# frozen_string_literal: true

module Travis
  module VcsProxy
    module Sync
      class Repository
        def initialize(repository, user)
          @repository = repository
          @user = user
        end

        def sync
          username = @repository.settings(:p4_host).username
          token = @repository.token
          if username.blank? || token.blank?
            return unless server_provider_permission = @user.server_provider_permission(@repository.server_provider_id)
            return unless server_provider_user_setting = server_provider_permission.setting

            username = server_provider_user_setting.username
            token = server_provider_user_setting.token
          end
          return if username.blank? || token.blank?

          @repository.repo.branches.each do |branch|
            branch_name = branch[:name].sub(/\A\/\/#{Regexp.escape(@repository.name)}\//, '')
            branch = @repository.branches.find_or_create_by!(name: branch_name)

            @repository.repo.commits(branch_name).each do |commit|
              next if branch.commits.where(sha: commit[:sha]).exists?

              branch.commits.create!(commit.merge(repository_id: @repository.id))
            end
          end

          perms = @repository.repo.permissions
          if perms.present?
            repo_emails = perms.keys
            users = ::User.where(email: repo_emails).group_by(&:email)
            db_emails = @repository.users.pluck(:email)

            # Remove users that don't have access anymore
            (db_emails - repo_emails).each do |email|
              users[email].first.repository_permission(@repository.id).delete
            end

            perms.each do |email, permission|
              next unless users.has_key?(email)
              user = users[email].first
              perm = user.repository_permission(@repository.id)
              if permission == 'none'
                perm&.delete
                return
              end

              perm ||= user.repository_permissions.build(repository_id: @repository.id)
              perm.permission = permission
              perm.save!
            end
          end

          @repository.last_synced_at = Time.now
          @repository.save!
        end
      end
    end
  end
end
