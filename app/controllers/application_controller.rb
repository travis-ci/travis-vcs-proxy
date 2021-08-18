class ApplicationController < ActionController::API
  before_action :require_2fa

  private

  def require_authentication
    head :unauthorized and return unless user_signed_in?
  end

  def require_2fa
    head :unauthorized and return unless two_factor_auth_enabled?
  end

  def two_factor_auth_enabled?
    !user_signed_in? || current_user.otp_required_for_login?
  end

  def presented_entity(resource_name, resource)
    "#{resource_name.to_s.classify}Serializer".constantize.new(resource, { params: { current_user: current_user } }).to_h
  end

  def current_user_jwt_token
    request.env[Warden::JWTAuth::Hooks::PREPARED_TOKEN_ENV_KEY]
  end

  def user_signed_in?
    super || current_resource_owner.present?
  end

  def current_user
    super || current_resource_owner
  end

  def current_resource_owner
    return @current_resource_owner if defined?(@current_resource_owner)

    unless valid_doorkeeper_token?
      @current_resource_owner = nil
      return
    end

    @current_resource_owner = User.find(doorkeeper_token.resource_owner_id)
  end
end
