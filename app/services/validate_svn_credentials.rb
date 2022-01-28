# frozen_string_literal: true

class ValidateSvnCredentials
  class ValidationFailed < StandardError
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end

  def initialize(username, password, url, name, svn_realm = '')
    @username = username
    @password = password
    @url = url
    @name = name
    @svn_realm = svn_realm
  end

  def call
    raise ValidationFailed unless @username && @password

    svn = Travis::VcsProxy::SvnClient.new
    svn.username = @username
    svn.ssh_key = @password
    svn.url = @url
    res = svn.ls(@name);
    puts "SVN VALIDATION : #{res}"
    !res.empty?
  end
end
