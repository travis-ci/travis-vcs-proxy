# frozen_string_literal: true

class P4ServerType < ServerType
  include EncryptedToken

  def self.bare_repo(repository = nil, username = nil, password = nil)
    Travis::VcsProxy::Repositories::P4.new(repository, username, password)
  end

  def commit_info_from_webhook(payload)
    return unless payload.key?(:change_root) && payload.key?(:username)

    bare_repo.commit_info(payload[:change_root], payload[:username])
  end

  def permissions(url, username, password, is_new_repository, repository)
    p4 = P4.new
    p4.charset = 'utf8'
    p4.port = url
    p4.user = username
    p4.password = password
    p4.ticket_file = '/dev/null'
    p4.connect
    p4.run_trust('-y')
    p = p4.run_protects

    repository_name = url.include?('assembla') ? 'depot' : repository.name
    if p
      values = p.detect { |repo| repo['depotFile'] == "//#{repository_name}/..." }
      values ||= p.detect { |repo| repo['depotFile'] == '//...' }
    end
    puts "PERM VALUES: #{values.inspect}"
    values['perm'] || nil
  rescue P4Exception => e
    puts "PERM ERROR: #{e.inspect}"
    nil
  end

  def provider_type
    'perforce'
  end

  def host_type
    :p4_host
  end

  def default_branch
    'master'
  end

end
