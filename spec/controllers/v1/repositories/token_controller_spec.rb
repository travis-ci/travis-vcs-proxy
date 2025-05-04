# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::Repositories::TokenController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:repository) { FactoryBot.create(:repository, created_by: user.id, owner_id: organization.id, owner_type: 'Organization', server_type: 'perforce') }
  let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: user) }
  let(:branch_ref) { FactoryBot.create(:ref, name: 'BranchRef', repository: repository, type: :branch) }
  let!(:commit) { FactoryBot.create(:commit, ref: branch_ref, repository: repository, user: user) }

  before do
    sign_in(user)
  end

  describe 'PATCH update' do
    let(:token) { 'token' }
    let(:username) { 'username' }

    context 'when username and token are present and user has permission' do
      it 'updates the token' do
        expect(UpdateRepositoryCredentials).to receive(:new).with(repository, ActionController::Parameters.new(username: username, token: token).permit!).and_call_original
        expect_any_instance_of(UpdateRepositoryCredentials).to receive(:call).and_return(true)

        patch :update, params: { repository_id: repository.id, username: username, token: token }

        expect(response).to be_successful
      end

      it 'returns error on unsuccessful update' do
        expect(UpdateRepositoryCredentials).to receive(:new).with(repository, ActionController::Parameters.new(username: username, token: token).permit!).and_call_original
        expect_any_instance_of(UpdateRepositoryCredentials).to receive(:call).and_return(false)

        patch :update, params: { repository_id: repository.id, username: username, token: token }

        expect(response.status).to eq(422)
      end
    end

    context 'when username or token are blank' do
      let(:token) { '' }
      let(:username) { '' }

      it 'returns bad_request' do
        patch :update, params: { repository_id: repository.id, username: username, token: token }

        expect(response).to be_bad_request
      end
    end
  end

  describe 'DELETE destroy' do
    context 'when username and token are present and user has permission' do
      it 'destroys the token' do
        expect(UpdateRepositoryCredentials).to receive(:new).with(repository, {}).and_call_original
        expect_any_instance_of(UpdateRepositoryCredentials).to receive(:call).and_return(true)

        delete :destroy, params: { repository_id: repository.id }

        expect(response).to be_successful
      end

      it 'returns error on unsuccessful update' do
        expect(UpdateRepositoryCredentials).to receive(:new).with(repository, {}).and_call_original
        expect_any_instance_of(UpdateRepositoryCredentials).to receive(:call).and_return(false)

        delete :destroy, params: { repository_id: repository.id }

        expect(response.status).to eq(422)
      end
    end
  end
end
