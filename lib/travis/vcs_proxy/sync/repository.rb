# frozen_string_literal: true

module Travis
  module VcsProxy
    module Sync
      class Repository
        def initialize(repository, user)
          @host_type = repository.server_type
          @repository = repository
          @user = user
        end

        def sync # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
          permissions = @user.repository_permissions.find_by(repository_id: @repository.id)
          username = permissions&.setting&.username
          token = permissions&.setting&.token
          return if username.blank? || token.blank?

          repo = @repository.repo(username, token)

          return unless repo

          puts "type: #{@host_type.inspect}"

          repo.branches&.each do |branch|
            branch_name = branch[:name].sub(%r{\A//#{Regexp.escape(@repository.name)}/}, '')
            branch = @repository.branches.find_or_create_by!(name: branch_name)

            repo.commits(branch_name).each do |commit|
              next if branch.commits.where(sha: commit[:sha]).exists?

              branch.commits.create!(commit.merge(repository_id: @repository.id))
            end
          end

          perms = repo.permissions
          if perms.present?
            repo_emails = perms.keys
            users = ::User.where(email: repo_emails).group_by(&:email)
            db_emails = @repository.users.pluck(:email)

            # Remove users that don't have access anymore
            (db_emails - repo_emails).each do |email|
              u = users[email]&.first
              u&.repository_permission(@repository.id)&.delete
            end

            perms.each do |email, permission|
              next unless users.key?(email)

              user = users[email].first
              perm = user.repository_permission(@repository.id)
              if permission == 'none'
                perm&.delete
                break
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
