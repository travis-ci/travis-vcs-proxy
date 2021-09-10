# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::WebhooksController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }
  let(:token) { 'token' }
  let(:server_provider) { FactoryBot.create(:p4_server_provider, listener_token: 'token') }
  let!(:server_provider_permission) { FactoryBot.create(:server_provider_permission, server_provider: server_provider, user: user) }
  let(:repository) { FactoryBot.create(:repository, server_provider: server_provider) }
  let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: user) }

  before do
    sign_in(user)
    allow_any_instance_of(P4ServerProvider).to receive(:commit_info_from_webhook).and_return(commit_info)
  end

  describe 'POST receive' do
    let(:params) do
      {
        token: token,
        change_root: 'root',
        username: user.email,
      }
    end
    let(:commit_info) do
      {
        email: user.email,
        repository_name: repository.name,
        sha: 'sha',
        ref: 'ref',
      }
    end

    context 'when all parameters are provided and correct' do
      let(:trigger_webhooks) { double }

      it 'triggers webhooks' do
        expect(TriggerWebhooks).to receive(:new).and_return(trigger_webhooks)
        expect(trigger_webhooks).to receive(:call)

        post :receive, params: params

        expect(response).to be_successful
      end
    end

    context 'when server is not found' do
      let(:token) { 'notoken' }

      it 'returns an error' do
        expect(TriggerWebhooks).not_to receive(:new)

        post :receive, params: params

        expect(response).to be_unauthorized
      end
    end

    context 'when there is no commit info' do
      before do
        allow_any_instance_of(P4ServerProvider).to receive(:commit_info_from_webhook).and_return(nil)
      end

      it 'returns an error' do
        expect(TriggerWebhooks).not_to receive(:new)

        post :receive, params: params

        expect(response.status).to eq(500)
      end
    end

    context 'when there is no user' do
      before do
        commit_info[:email] = 'no@email.com'
      end

      it 'does not trigger webhooks' do
        expect(TriggerWebhooks).not_to receive(:new)

        post :receive, params: params

        expect(response).to be_successful
      end
    end

    context 'when there is no repository' do
      before do
        commit_info[:repository_name] = 'NoREPO'
      end

      it 'does not trigger webhooks' do
        expect(TriggerWebhooks).not_to receive(:new)

        post :receive, params: params

        expect(response).to be_successful
      end
    end
  end
end
