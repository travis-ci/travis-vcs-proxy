# frozen_string_literal: true

class ServerType

  def bare_repo(*args)
    raise NotImplementedError
  end

  def commit_info_from_webhook(payload)
    raise NotImplementedError
  end

  def provider_type
    raise NotImplementedError
  end

  def host_type
    raise NotImplementedError
  end

  def default_branch
    raise NotImplementedError
  end

  private

end
