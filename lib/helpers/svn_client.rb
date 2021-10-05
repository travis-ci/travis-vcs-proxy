# frozen_string_literal: true

module Travis
  module VcsProxy
    class SvnClient
      attr_accessor :username, :ssh_key, :password

      def exec(cmd)
        return `svn --username #{@username} --password #{@password} #{cmd}` if @password

        ssh_file = Tempfile.new('sshkey')
        ssh_file.write(@ssh_key)
        ENV['SVN_SSH'] = sshfile.path
        ssh_file.close
        `svn #{cmd}`
      ensure
        ssh_file&.unlink
      end

      def ls(repo, branch = nil)
        res = exec("ls #{url}/#{repo}/#{get_branch(branch)}")
        return [] unless res

        res.split("\n")
      end

      def branches(repo)
        res = exec("ls #{url}/#{repo}/branches")
        return [] unless res

        res.split("\n")
      end

      def content(repo, file, branch: nil, revision: nil)
        params = "-r #{revision}" if revision
        exec("cat #{url}/#{repo}/#{get_branch(branch)}/#{file} #{params}")
      end

      def log(repo, file, branch: nil, revision: nil, format: nil)
        params = ''
        params += '--xml' if format
        params += "-r #{revision}" if revision
        exec("log #{url}/#{repo}/#{get_branch(branch)}/#{file} #{params}")
      end

      private

      def url
        return "svn://#{@url}" if @password

        "svn+ssh://#{@username}@#{@url}"
      end

      def get_branch(branch)
        branch ? '/branches/' + branch : 'trunk'
      end
    end
  end
end
