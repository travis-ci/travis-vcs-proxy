# frozen_string_literal: true

module V1
  class UsersController < ApplicationController
    include PaginatedCollection

    before_action :require_authentication, except: %i[request_password_reset reset_password]
    skip_before_action :require_2fa, only: %i[show request_password_reset reset_password]

    def show
      head(:forbidden) && return unless current_user

      render json: presented_entity(:user, current_user)
    end

    def update_email
      head(:bad_request) && return if params[:email].blank?

      current_user.email = params[:email]
      if current_user.save
        head :ok
        return
      end

      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end

    def update_password # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      if params[:current_password].blank? || params[:password].blank? || params[:password_confirmation].blank?
        head(:bad_request) && return
      end

      unless current_user.valid_password?(params[:current_password])
        render json: { errors: ['Invalid current password'] }, status: :unprocessable_entity
        return
      end

      unless params[:password] == params[:password_confirmation]
        render json: { errors: ['Password does not match confirmation'] }, status: :unprocessable_entity
        return
      end

      current_user.password = params[:password]
      current_user.password_confirmation = params[:password_confirmation]
      if current_user.save
        head :ok
        return
      end

      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end

    def request_password_reset
      head(:ok) && return if params[:email].blank?
      head(:ok) && return unless user = User.find_by(email: params[:email])

      user.send_reset_password_instructions

      head :ok
    end

    def reset_password
      if params[:reset_password_token].blank? || params[:password].blank? || params[:password_confirmation].blank?
        head(:bad_request) && return
      end

      user = User.reset_password_by_token(params.slice(:reset_password_token, :password, :password_confirmation))
      if user.errors.empty?
        head :ok
        return
      end

      render json: { errors: user.errors }, status: :unprocessable_entity
    end

    def emails
      render json: { emails: [current_user&.email] }
    end

    def organizations
      organizations = current_user.organizations
                                  .includes(:organization_permissions)
                                  .order(:name)
                                  .page(params[:page])
                                  .per(params[:limit])
      puts "orgs: #{organizations.inspect}"
      render json: paginated_collection(:organizations, :organization, organizations)
    end

    def repositories
      order = params[:sort_by] == 'last_synced_at' ? 'DESC' : 'ASC'
      repositories = current_user.repositories.page(params[:page]).per(params[:limit])
      repositories = repositories.order(params[:sort_by] => order) if params[:sort_by].present?
      repositories = repositories.where('name LIKE ?', "%#{params[:filter]}%") if params[:filter].present?

      puts " repos: #{repositories.inspect}"
      render json: paginated_collection(:repositories, :repository, repositories)
    end

    def organizations_for_choice
      organizations = current_user.organizations
                                  .includes(:organization_permissions)
                                  .order(:name)

      render json: organizations.map { |org| { id: org.id, name: org.name } }
    end

    def sync
      SyncJob.perform_later(SyncJob::SyncType::USER, current_user.id)

      head :ok
    end
  end
end
