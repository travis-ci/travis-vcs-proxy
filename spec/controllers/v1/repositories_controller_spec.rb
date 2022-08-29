# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::RepositoriesController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:repository) { FactoryBot.create(:repository, created_by: user.id, owner_id: organization.id, owner_type: 'Organization', server_type: 'perforce', listener_token: 'token') }
  let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: user) }
  let!(:repository_user_setting) { FactoryBot.create(:repository_user_setting, username: user.email, value: 'token', permission: repository_permission) }
  let!(:branch_ref) { FactoryBot.create(:ref, name: 'BranchRef', repository: repository, type: :branch) }

  before do
    sign_in(user)
    allow_any_instance_of(EncryptedToken).to receive(:decrypted_token).and_return('token')
  end

  describe 'GET show' do
    it 'returns specified repository' do
      get :show, params: { id: repository.id }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(
                                    id: repository.id,
                                    name: repository.name,
                                    display_name: repository.name,
                                    url: repository.url,
                                    server_type: 'perforce',
                                    last_synced_at: repository.last_synced_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
                                    owner_id: organization.id,
                                    listener_token: 'token',
                                    permission: repository_permission.permission,
                                    token: 'token',
                                    username: user.email,
                                    default_branch: 'main',
                                    owner: {
                                      id: organization.id,
                                      type: 'Organization',
                                    },
                                    type: repository.server_type,
                                    slug: "#{organization.name}/#{repository.name}",
                                    source_url: repository.url
                                  ))
    end
  end

  describe 'GET refs' do
    it 'returns refs from specified repository' do
      get :refs, params: { id: repository.id }

      expect(response.body).to eq(JSON.dump([
                                              {
                                                id: branch_ref.id,
                                                name: branch_ref.name,
                                                type: branch_ref.type,
                                              },
                                            ]))
    end
  end

  describe 'GET content' do
    context 'when no path is specified' do
      it 'returns an error' do
        get :content, params: { id: repository.id, ref: branch_ref.id }

        expect(response).to be_bad_request
      end
    end

    context 'when path is specified' do
      let(:path) { 'path' }
      let(:contents) { ['', 'contents'] }

      it 'returns the contents' do
        expect_any_instance_of(Repository).to receive(:file_contents).and_return(contents)

        get :content, params: { id: repository.id, ref: branch_ref.id, path: path }

        expect(response).to be_successful
        expect(response.body).to eq(contents[1])
      end
    end

    context 'when path is specified but contents are blank' do
      let(:path) { 'path' }
      let(:contents) { '' }

      it 'returns the contents' do
        expect_any_instance_of(Repository).to receive(:file_contents).and_return(contents)

        get :content, params: { id: repository.id, ref: branch_ref.id, path: path }

        expect(response.status).to eq(422)
      end
    end
  end
end
