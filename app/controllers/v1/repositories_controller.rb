# frozen_string_literal: true

module V1
  class RepositoriesController < ApplicationController
    before_action :require_authentication
    before_action :set_repository, except: %i[create]

    def show
      render json: presented_entity(:repository, @repository)
    end

    def create
      errors = nil
      head(:bad_request) && return if params['repository'].blank?
      is_new_repository = false

      @repository = Repository.find_by(name: params['repository']['name'], url: params['repository']['url'])
      puts "param: #{params.inspect}"
      @organization = Organization.find(params['repository']['owner_id'].to_i);
      puts "org: #{@organization.inspect}"
      unless @repository then
        is_new_repository = true
        ActiveRecord::Base.transaction do
          @repository = Repository.new(
            name: params['repository']['name'],
            display_name: params['repository']['name'],
            url: params['repository']['url'],
            created_by: current_user.id,
            server_type: params['repository']['server_type'],
            owner_id: @organization.id,
            owner_type: 'Organization',
            last_synced_at: Time.now
          )
          render(json: { errors: ['Could not validate credentials'] }, status: :forbidden) && return unless @repository.validate(params['username'], params['token'])

          unless @repository.save
            errors = @repository.errors
            raise ActiveRecord::Rollback
          end
        end
      end

      unless is_new_repository
        render(json: { errors: ['Could not validate credentials.'] }, status: :forbidden) && return unless @repository.validate(params['username'], params['token'])

        render(json: { errors: ['Repository with this URL already exists.'] }, status: :forbidden) && return unless current_user.repository_permission(@repository.id).nil?
      end

      ActiveRecord::Base.transaction do
        perm = current_user.repository_permissions.build(repository_id: @repository.id)
        perm.permission = is_new_repository ? 'admin' : 'write'
        unless perm.save!
          puts "PERMS ERROR"
          errors = perm.errors
          raise ActiveRecord::Rollback
        end
        setting = perm.setting || perm.build_setting
        puts "params: #{params.inspect}"
        setting.username = params['username']
        setting.token = params['token']
        unless setting.save!
          puts "SETTINGS ERROR"
          errors = setting.errors
          raise ActiveRecord::Rollback
        end
        puts "perm.se: #{setting.inspect}"
        puts "perm: #{perm.inspect}"
        puts "perm.se: #{perm.setting.inspect}"
      end
      Audit.create(current_user,"repository created: #{@repository.id}") if errors.blank?

      puts "errors: #{errors.inspect}"
      puts "repo: #{@repository.inspect}"

      render json: presented_entity(:repository, @repository) && return if errors.blank?
      puts "!!!!!!!!!!!!!"

      render json: { errors: errors }, status: :unprocessable_entity
    end

    def update
      errors = nil
      head(:bad_request) && return if params['repository'].blank?

      @repository = Repository.find(params['id'])

      head(:not_found) && return unless @repository

      @organization = Organization.find(@repository.owner_id);

      head(:not_found) && return unless @organization
      auditlog = ""

      render(json: { errors: ['could not validate credentials'] }, status: :forbidden) && return unless @repository.validate(params['repository']['username'], params['repository']['token'])

      if params['repository']['owner_id'] && @organization.id != params['repository']['owner_id'].to_i
        old_organization = @organization
        @organization = Organization.find(params['repository']['owner_id'])

        head(:not_found) && return unless @organization

        new_users = @organization.users
        old_organization.users.each do |user|
         user.repository_permission(@repository.id)&.delete if new_users.where(id: user.id).empty?
        end
        auditlog += "organization changed from #{old_organization.id} to #{@organization.id}\n"
      end
      ActiveRecord::Base.transaction do
        @repository.display_name =  params['repository']['display_name'] if params['repository']['display_name']
        @repository.owner_id = @organization.id if @organization
        puts "repo: #{@repository.inspect}"
        unless @repository.save
          errors = @repository.errors
          raise ActiveRecord::Rollback
        end
      end

      Audit.create(current_user,"repository updated: #{@repository.id} - #{auditlog}") if errors.blank? && !auditlog.empty?

      ActiveRecord::Base.transaction do
        perm = current_user.repository_permission(params['id'])
        setting = perm.setting || perm.build_setting
        setting.username = params['repository']['username'] if params['repository']['username']
        setting.token = params['repository']['token'] if params['repository']['token']
        unless setting.save!
          puts "SETTINGS ERROR"
          errors = setting.errors
          raise ActiveRecord::Rollback
        end
      end

      puts "repo: #{@repository.inspect}"

      render json: presented_entity(:repository, @repository) && return if errors.blank?

      render json: { errors: errors }, status: :unprocessable_entity
    end

    def destroy
      permission = current_user.repository_permission(params[:id])

      head(:forbidden) && return unless permission&.owner?
      @repository.destroy

      Audit.create(current_user,"repository deleted: #{params[:id]}")

      head(:ok) && return
    end

    def refs
      render json: @repository.refs.map { |ref| presented_entity(:full_ref, ref) }
    end

    def by_name
      head(:bad_request) && return if params[:name].blank?

      render json: presented_entity(:organization, Repository.find_by!(name: params[:name]))
    end

    def content # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      head(:bad_request) && return if params[:ref].blank? || params[:path].blank?

      ref, commit = params[:ref].split('@')
      if commit
        ref = Ref.find_by(name: ref, repository: @repository)
        commit = Commit.find_by(sha: commit, ref: ref)
      else
        commit = Commit.find_by(sha: ref, repository: @repository)
      end


      permission = current_user.repository_permission(@repository.id)

      head(:forbidden) && return unless permission && permission&.setting

      result = @repository.file_contents(permission.setting.username, permission.setting.token, commit, params[:path])
      render(json: { errors: ['Cannot render file'] }, status: :unprocessable_entity) && return if result.blank?

      render plain: result
    end

    def sync
      SyncJob.perform_later(SyncJob::SyncType::REPOSITORY, @repository.id, current_user.id)

      head :ok
    end

    private

    def set_repository
      @repository = current_user.repositories.includes(:permissions).find(params[:id])
    end
  end
end
