# frozen_string_literal: true

class V1::Repositories::WebhooksController < ApplicationController
  before_action :require_authentication
  before_action :set_repository
  before_action :set_webhook, only: [:show, :update]

  def index
    render json: @repository.webhooks.map { |webhook| presented_entity(:webhook, webhook) }
  end

  def show
    render json: presented_entity(:webhook, @webhook)
  end

  def create
    webhook = @repository.webhooks.build(webhook_params)
    if webhook.save
      render json: presented_entity(:webhook, webhook)
      return
    end

    render json: { errors: webhook.errors.full_messages }, status: :unprocessable_entity
  end

  def update
    if @webhook.update(webhook_params)
      render json: presented_entity(:webhook, @webhook)
      return
    end

    render json: { errors: webhook.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_repository
    @repository = current_user.repositories.find(params[:repository_id])
  end

  def set_webhook
    @webhook = @repository.webhooks.find(params[:id])
  end

  def webhook_params
    params.require(:webhook).permit(:name, :url, :active, :insecure_ssl)
  end
end