class ApplicationController < ActionController::API
  private

  def require_authentication
    head :unauthorized and return unless user_signed_in?
  end

  def presented_entity(resource_name, resource)
    "#{resource_name.to_s.classify}Serializer".constantize.new(resource).to_h
  end
end
