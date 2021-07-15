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
    "#{resource_name.to_s.classify}Serializer".constantize.new(resource).to_h
  end
end
