# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::ServerProvidersController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }

  before do
    sign_in(user)
  end

  describe 'POST create' do
    let(:params) do
      {
        server_provider: {
          type: 'perforce',
          url: 'test.e.corp',
          name: 'EcorpServer',
          username: 'user',
          token: 'token',
        },
      }
    end

    context 'when no type provided' do
      before { params[:server_provider][:type] = '' }

      it 'returns an error' do
        post :create, params: params

        expect(response).to be_bad_request
      end
    end

    context 'when server with provided URL already exists' do
      let!(:server_provider) { FactoryBot.create(:server_provider, url: params[:server_provider][:url]) }

      it 'returns an error' do
        post :create, params: params

        expect(response.status).to eq(422)
        expect(response.body).to eq(JSON.dump(errors: ['A server with this URL already exists.']))
      end
    end

    context 'when all parameters present but validation fails' do
      before do
        allow_any_instance_of(UpdateRepositoryCredentials).to receive(:call).and_return(false)
      end

      it 'returns an error' do
        post :create, params: params

        expect(response.status).to eq(422)
        expect(response.body).to eq(JSON.dump(errors: ['Cannot save credentials']))
      end
    end

    context 'when all parameters present but setting the permission fails' do
      before do
        allow_any_instance_of(User).to receive(:set_server_provider_permission).and_return(false)
        allow_any_instance_of(UpdateRepositoryCredentials).to receive(:call).and_return(true)
      end

      it 'returns an error' do
        post :create, params: params

        expect(response.status).to eq(422)
        expect(response.body).to eq(JSON.dump(errors: ['Cannot set permission for user']))
      end
    end

    context 'when all parameters present' do
      before do
        allow_any_instance_of(UpdateRepositoryCredentials).to receive(:call).and_return(true)
      end

      it 'creates the server provider' do
        expect { post :create, params: params }.to change(ServerProvider, :count).by(1)

        expect(response).to be_successful
        expect(response.body).to eq(JSON.dump(
                                      id: ServerProvider.last.id,
                                      name: params[:server_provider][:name],
                                      url: params[:server_provider][:url],
                                      type: params[:server_provider][:type],
                                      username: '',
                                      permission: 'Owner'
                                    ))
        expect(ServerProvider.last.name).to eq(params[:server_provider][:name])
      end
    end
  end

  describe 'GET show' do
    let(:server_provider) { FactoryBot.create(:server_provider) }
    let!(:server_provider_permission) { FactoryBot.create(:server_provider_permission, server_provider: server_provider, user: user) }

    it 'returns the server provider representation' do
      get :show, params: { id: server_provider.id }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(
                                    id: server_provider.id,
                                    name: server_provider.name,
                                    url: server_provider.url,
                                    type: 'perforce',
                                    username: '',
                                    permission: 'Owner'
                                  ))
    end
  end

  describe 'PATCH update' do
    let(:server_provider) { FactoryBot.create(:server_provider) }
    let(:params) do
      {
        id: server_provider.id,
        server_provider: {
          name: 'TestNameUpdate',
          username: 'user',
          token: 'token',
        },
      }
    end

    before do
      allow_any_instance_of(UpdateRepositoryCredentials).to receive(:call).and_return(true)
    end

    context 'when user has permission' do
      let!(:server_provider_permission) { FactoryBot.create(:server_provider_permission, server_provider: server_provider, user: user) }

      it 'updates the server provider' do
        patch :update, params: params

        expect(response).to be_successful
        expect(ServerProvider.last.name).to eq(params[:server_provider][:name])
      end
    end

    context 'when user has no permission' do
      it 'returns forbidden' do
        patch :update, params: params

        expect(response).to be_forbidden
      end
    end

    context 'when credentials are not validated' do
      let!(:server_provider_permission) { FactoryBot.create(:server_provider_permission, server_provider: server_provider, user: user) }

      before do
        allow_any_instance_of(UpdateRepositoryCredentials).to receive(:call).and_return(false)
      end

      it 'returns an error' do
        patch :update, params: params

        expect(response.status).to eq(422)
        expect(response.body).to eq(JSON.dump(errors: ['Cannot save credentials']))
      end
    end
  end

  describe 'POST authenticate' do
    let(:server_provider) { FactoryBot.create(:server_provider) }
    let(:params) do
      {
        id: server_provider.id,
        username: 'user',
        token: 'token',
      }
    end

    context 'when no username or token are provided' do
      before { params[:username] = '' }

      it 'returns an error' do
        post :authenticate, params: params

        expect(response).to be_bad_request
      end
    end

    context 'when permission exists' do
      let!(:server_provider_permission) { FactoryBot.create(:server_provider_permission, server_provider: server_provider, user: user) }

      before do
        allow_any_instance_of(ValidateP4Credentials).to receive(:call).and_return(true)
      end

      it 'updates credentials' do
        post :authenticate, params: params

        expect(response).to be_successful
        expect(server_provider_permission.setting.username).to eq(params[:username])
        expect(server_provider_permission.setting.token).to eq(params[:token])
      end
    end

    context 'when permission does not exist' do
      before do
        allow_any_instance_of(ValidateP4Credentials).to receive(:call).and_return(true)
      end

      it 'creates member permission and updates credentials' do
        post :authenticate, params: params

        expect(response).to be_successful
        server_provider_permission = ServerProviderPermission.last
        expect(server_provider_permission.permission).to eq('member')
        expect(server_provider_permission.setting.username).to eq(params[:username])
        expect(server_provider_permission.setting.token).to eq(params[:token])
      end
    end

    context 'when validation fails' do
      it 'creates member permission and updates credentials' do
        post :authenticate, params: params

        expect(response.status).to eq(422)
        expect(response.body).to eq(JSON.dump(errors: ['Cannot authenticate']))
      end
    end
  end

  describe 'POST forget' do
    let(:server_provider) { FactoryBot.create(:server_provider) }
    let!(:server_provider_permission) { FactoryBot.create(:server_provider_permission, server_provider: server_provider, user: user) }

    it 'removes server provider permission' do
      expect { post :forget, params: { id: server_provider.id } }.to change(ServerProviderPermission, :count).by(-1)
    end
  end

  describe 'POST sync' do
    let(:server_provider) { FactoryBot.create(:server_provider) }
    let!(:server_provider_permission) { FactoryBot.create(:server_provider_permission, server_provider: server_provider, user: user) }

    it 'schedules sync for server provider' do
      expect(SyncJob).to receive(:perform_later).with(SyncJob::SyncType::SERVER_PROVIDER, server_provider.id, user.id)

      post :sync, params: { id: server_provider.id }

      expect(response).to be_successful
    end
  end

  describe 'GET by_url' do
    let(:server_provider) { FactoryBot.create(:server_provider) }
    let!(:server_provider_permission) { FactoryBot.create(:server_provider_permission, server_provider: server_provider, user: user) }

    it 'returns server provider representation' do
      get :by_url, params: { url: server_provider.url }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(
                                    id: server_provider.id,
                                    name: server_provider.name,
                                    url: server_provider.url,
                                    type: 'perforce',
                                    username: '',
                                    permission: 'Owner'
                                  ))
    end
  end

  describe 'POST add_by_url' do
    let(:server_provider) { FactoryBot.create(:server_provider) }

    it 'adds member permission for user' do
      post :add_by_url, params: { url: server_provider.url }

      expect(response).to be_successful
      server_provider_permission = ServerProviderPermission.last
      expect(server_provider_permission.permission).to eq('member')
    end
  end
end
