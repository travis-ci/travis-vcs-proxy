# frozen_string_literal: true

module V1
  class OrganizationsController < ApplicationController
    include PaginatedCollection

    before_action :require_authentication, except: %i[confirm_invitation]
    before_action :set_organization, only: %i[show update authenticate forget repositories sync users destroy]

    def create # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      if params[:organization].blank?
        head(:bad_request) && return
      end

      if Organization.find_by(name: params[:organization][:name]).present?
        render(json: { errors: ['An organization with this name already exists.'] }, status: :unprocessable_entity) && return
      end

      errors = []
      org = nil
      ActiveRecord::Base.transaction do
        org = Organization.new(organization_params)
        unless org.save
          errors = org.errors
          raise ActiveRecord::Rollback
        end
        puts "perm: #{OrganizationPermission.permissions[:owner].inspect}"
        unless current_user.set_organization_permission(org.id, :owner)
          errors << 'Cannot set permission for user'
          raise ActiveRecord::Rollback
        end
      end

      render(json: presented_entity(:organization, org)) && return if errors.blank?

      render json: { errors: errors }, status: :unprocessable_entity
    end

    def destroy
      head(:forbidden) && return unless current_user.organization_permission(params[:id])&.permission == 'owner'

      Repository.where(owner_id: @organization.id).each do |repo|
        Audit.create(current_user,"repository deleted: #{repo.id}")
        repo.destroy
      end

      @organization.destroy
      Audit.create(current_user,"organization deleted: #{params[:id]}")

      head(:ok) && return
    end

    def confirm_invitation
      perm = OrganizationInvitation.find_by(token: params['token'])
      head(:not_found) && return unless perm

      head(:unprocessable_entity) && return unless Time.now - perm.created_at < 1.day

      User.find(perm.user_id)&.set_organization_permission(perm.organization_id, OrganizationPermission.permissions[perm.permission])
      @organization = Organization.includes(:organization_permissions).find(perm.organization_id)
      perm.delete

      render(json: presented_entity(:organization, @organization))
    end

    def invite
      token = nil
      user_id = params['user_id']
      user_id ||= User.find_by(email: params['user_email'])&.id;
      head(:not_found) && return unless user_id

      @organization = Organization.find(params['organization_id'])

      ActiveRecord::Base.transaction do
        inv = OrganizationInvitation.new(
          organization_id: params['organization_id'],
          user_id: user_id,
          permission: params['permission'],
        )
        unless inv.save
          errors = inv.errors
          raise ActiveRecord::Rollback
        end
        token = inv.token
      end
      head(:unprocessable_entity) && return unless token

      Audit.create(current_user,"invited #{user_id} to organization #{params['organization_id']}")

      invitation_link = Settings.web_url + '/accept_invite?token=' + token

      InvitationMailer.with(email: params['user_email'], organization: @organization.name, invitation_link: invitation_link, invited_by: current_user.email).send_invitation.deliver_now

      render(json: {"token": token})
    end

    def show
      permission = current_user.organization_permission(@organization.id)
      head(:forbidden) && return if permission.blank?

      render json: presented_entity(:organization, @organization)
    end

    def users
      users = User.select('users.*, organization_permissions.permission').joins(:organization_permissions).where("organization_permissions.organization_id = ?", @organization.id)
      users = users.order(params[:sort_by] => 'ASC') if params[:sort_by].present?
      users = users.where('name LIKE ?', "%#{params[:filter]}%") if params[:filter].present?

      render json: paginated_collection(:users, :user, users.page(params[:page])&.per(params[:limit]))
    end

    def update # rubocop:disable Metrics/CyclomaticComplexity
      permission = current_user.organization_permission(@organization.id)
      head(:forbidden) && return if permission.blank? || !permission.owner?

      errors = []
      ActiveRecord::Base.transaction do
        unless @organization.update(organization_update_params)
          errors = @organization.errors
          raise ActiveRecord::Rollback
        end
      end

      head(:ok) && return if errors.blank?

      render json: { errors: errors }, status: :unprocessable_entity
    end

    def forget
      current_user.organization_permission(@organization.id)&.destroy

      head :ok
    end

    def sync
      permission = current_user.organization_permission(@organization.id)
      head(:forbidden) && return if permission.blank?

      SyncJob.perform_later(SyncJob::SyncType::ORGANIZATION, @organization.id, current_user.id)

      head :ok
    end

    def by_name
      head(:bad_request) && return if params[:name].blank?

      permission = current_user.organization_permission(@organization.id)
      head(:forbidden) && return if permission.blank?

      render json: presented_entity(:organization, Organization.find_by!(name: params[:name]))
    end

    def repositories
      permission = current_user.organization_permission(@organization.id)
      head(:forbidden) && return if permission.blank?

      order = params[:sort_by] == 'last_synced_at' ? 'DESC' : 'ASC'
      puts "org: #{@organization.repositories.inspect}"
      repositories = @organization.repositories
                                    .includes(:permissions)
      repositories = repositories.order(params[:sort_by] => order) if params[:sort_by].present?
      repositories = repositories.where('name LIKE ?', "%#{params[:filter]}%") if params[:filter].present?

      render json: paginated_collection(:repositories, :repository, repositories.page(params[:page])&.per(params[:limit]))
    end

    private

    def organization_params
      params.require(:organization).permit(:name, :description, :listener_token)
    end

    def organization_update_params
      params.require(:organization).permit(:description, :listener_token)
    end

    def set_organization
      puts "params: #{params.inspect}"
      @organization = Organization.includes(:organization_permissions).find(params[:id])
    end

  end
end
