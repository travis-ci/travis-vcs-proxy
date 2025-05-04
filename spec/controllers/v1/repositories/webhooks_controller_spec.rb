# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::Repositories::WebhooksController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:repository) { FactoryBot.create(:repository, created_by: user.id, owner_id: organization.id, owner_type: 'Organization', server_type: 'perforce') }
  let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: user) }
  let!(:webhook) { FactoryBot.create(:webhook, repository: repository) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    it 'returns webhooks for specified repository' do
      get :index, params: { repository_id: repository.id }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(
                                    [
                                      {
                                        id: webhook.id,
                                        name: webhook.name,
                                        url: webhook.url,
                                        active: webhook.active,
                                        insecure_ssl: webhook.insecure_ssl,
                                        created_at: webhook.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
                                      },
                                    ]
                                  ))
    end
  end

  describe 'GET show' do
    it 'returns webhook for specified repository and id' do
      get :show, params: { id: webhook.id, repository_id: repository.id }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(
                                    id: webhook.id,
                                    name: webhook.name,
                                    url: webhook.url,
                                    active: webhook.active,
                                    insecure_ssl: webhook.insecure_ssl,
                                    created_at: webhook.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
                                  ))
    end
  end

  describe 'POST create' do
    let(:webhook_params) do
      {
        name: 'TestHook',
        url: 'https://test.url/hook',
        active: true,
        insecure_ssl: false,
      }
    end

    it 'creates the webhook and returns its representation' do
      post :create, params: { repository_id: repository.id, webhook: webhook_params }

      expect(response).to be_successful
      data = JSON.parse(response.body)
      expect(data['name']).to eq(webhook_params[:name])
      expect(data['url']).to eq(webhook_params[:url])
      expect(data['active']).to eq(webhook_params[:active])
      expect(data['insecure_ssl']).to eq(webhook_params[:insecure_ssl])
    end
  end

  describe 'PATCH update' do
    let(:webhook_params) do
      {
        name: 'TestHookUpdate',
      }
    end

    it 'updates the webhook and returns its representation' do
      patch :update, params: { id: webhook.id, repository_id: repository.id, webhook: webhook_params }

      expect(response).to be_successful
      data = JSON.parse(response.body)
      expect(data['name']).to eq(webhook_params[:name])
    end
  end
end
