# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::WebhooksController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }
  let(:token) { 'token' }
  let(:organization) { FactoryBot.create(:organization) }
  let(:repository) { FactoryBot.create(:repository, created_by: user.id, owner_id: organization.id, owner_type: 'Organization', server_type: 'svn', listener_token: 'token') }
  let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: user) }
  let!(:repository_user_setting) { FactoryBot.create(:repository_user_setting, username: user.email, value: 'token', permission: repository_permission) }

  let(:commit_info) do
    {
      email: user.email,
      repository_name: repository.name,
      sha: 'sha',
      ref: 'ref',
    }
  end

  before do
    sign_in(user)
    allow_any_instance_of(EncryptedToken).to receive(:decrypted_token).and_return('token')

    allow_any_instance_of(Repository).to receive(:commit_info_from_webhook).and_return(commit_info)
  end

  describe 'POST receive' do
    let(:params) do
      {
        token: token,
        change_root: 'trunk',
        username: user.email,
        message: 'xxxx',
        sha: '3',
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

    context 'when repository is not found' do
      let(:token) { 'notoken' }

      it 'returns an error' do
        expect(TriggerWebhooks).not_to receive(:new)

        post :receive, params: params

        expect(response.status).to eq(401)
      end
    end

    context 'when there is no commit info' do
      let(:commit_info) {}

      it 'returns an error' do
        expect(TriggerWebhooks).not_to receive(:new)

        post :receive, params: params

        expect(response.status).to eq(500)
      end
    end

    context 'when there is no repository' do
      before do
        params[:token] = 'NONE'
      end

      it 'does not trigger webhooks' do
        expect(TriggerWebhooks).not_to receive(:new)

        post :receive, params: params

        expect(response.status).to eq(401)
      end
    end
  end
end
