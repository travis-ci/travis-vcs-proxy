# frozen_string_literal: true
require 'tempfile'

module Travis
  module VcsProxy
    class SvnClient
      attr_accessor :username, :ssh_key, :password, :url

      def exec(repo, cmd)
        return `svn --username #{@username} --password #{@password} #{cmd}` if @password

        ssh_file = ::Tempfile.new('sshkey')
        ssh_file.write(@ssh_key)
        ENV['SVN_SSH'] = "ssh -i #{ssh_file.path} -o StrictHostKeyChecking=no"
        if assembla?
          ENV['SVN_SSH'] = "ssh -i #{ssh_file.path} -o SendEnv=REPO_NAME -o StrictHostKeyChecking=no -l svn"
        end
        ssh_file.close
        ENV['REPO_NAME'] = repo
        `svn #{cmd}`
      rescue Exception => e
        puts "SVN exec error: #{e.message}"
      ensure
        ssh_file&.unlink
      end

      def ls(repo, branch = nil)
        res = exec(repo, "ls #{repository_path(repo)}/#{get_branch(branch)}")
        return [] unless res

        res.split("\n")
      end

      def branches(repo)
        res = exec(repo, "ls #{repository_path(repo)}/branches")
        return['trunk'] unless res

        res = res.split("\n").each { |r| r.delete_suffix!('/') }
        res << 'trunk'
      end

      def content(repo, file, branch: nil, revision: nil)
        params = "-r #{revision}" if revision
        exec(repo, "cat #{repository_path(repo)}/#{get_branch(branch)}/#{file} #{params}")
      end

      def log(repo, file, branch: nil, revision: nil, format: nil)
        params = ''
        params += '--xml' if format
        params += "-r #{revision}" if revision
        exec(repo, "log #{repository_path(repo)}/#{get_branch(branch)}/#{file} #{params}")
      end

      def users(repo)
        res = exec(repo, "log -q -r 1:HEAD #{repository_path(repo)} | grep '^r' | awk -F'|' '!x[$2]++{print$2}' | tr -d ' '")
        res.split("\n")
      end

      private

      def repository_path(repo)
        return "#{url}/#{repo}" unless assembla?

        url
      end

      def url
        return @url if @password

        u = uri(@url)
        return @url unless u

        if u.port
          "svn+ssh://#{@username}@#{u.host}:#{u.port}#{u.path}" unless assembla?
          "svn+ssh://#{u.host}:#{u.port}"
        else
          "svn+ssh://#{@username}@#{u.host}#{u.path}" unless assembla?
          "svn+ssh://#{u.host}"
        end
      end

      def assembla?
        @assembla ||= uri(@url)&.host.include? 'assembla'
      end

      def repository_name
        uri(@url)&.path.split('/').last
      end

      def get_branch(branch)
        branch && branch != 'trunk' ? '/branches/' + branch : 'trunk'
      end

      def uri(url)
        proto, url = url.split('://')
        return nil unless url

        host,path = url.split('/',2)
        path = '/' unless path&.length > 0
        host,user = host.split('@',2).reverse
        user,pass = user.split(':',2) if user
        {
          :proto => proto,
          :host => host,
          :path => path,
          :user => user,
          :pass => pass
        }
      end
    end
  end
end
