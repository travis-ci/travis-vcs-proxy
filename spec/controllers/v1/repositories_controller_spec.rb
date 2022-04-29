# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::RepositoriesController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }
  let(:server_provider) { FactoryBot.create(:p4_server_provider) }
  let(:repository) { FactoryBot.create(:repository, server_provider: server_provider) }
  let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: user) }
  let!(:branch_ref) { FactoryBot.create(:ref, name: 'BranchRef', repository: repository, type: :branch) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    it 'returns specified repository' do
      get :show, params: { id: repository.id }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(
                                    id: repository.id,
                                    name: repository.name,
                                    url: URI.join(Settings.web_url, "servers/#{repository.server_provider_id}"),
                                    token: repository.token,
                                    last_synced_at: repository.last_synced_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
                                    server_provider_id: repository.server_provider_id,
                                    permission: repository_permission.permission,
                                    default_branch: server_provider.default_branch,
                                    owner: {
                                      id: server_provider.id,
                                    },
                                    slug: "#{server_provider.name}/#{repository.name}",
                                    server_type: server_provider.provider_type
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
