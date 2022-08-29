# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::Repositories::CommitsController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:repository) { FactoryBot.create(:repository, created_by: user.id, owner_id: organization.id, owner_type: 'Organization', server_type: 'perforce') }
  let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: user) }
  let(:branch_ref) { FactoryBot.create(:ref, name: 'BranchRef', repository: repository, type: :branch) }
  let!(:commit) { FactoryBot.create(:commit, ref: branch_ref, repository: repository, user: user) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    it 'returns commits for specified ref and repository' do
      get :index, params: { repository_id: repository.id, branch: branch_ref.name }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(
                                    [
                                      {
                                        id: commit.id,
                                        message: commit.message,
                                        committed_at: commit.committed_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
                                        sha: "#{branch_ref.name}@#{commit.sha}",
                                        author: {
                                          name: user.name,
                                          email: user.email,
                                        },
                                      },
                                    ]
                                  ))
    end
  end

  describe 'GET show' do
    it 'returns specified branch from specified repository' do
      get :show, params: { repository_id: repository.id, branch: branch_ref.name, id: commit.sha }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(
                                    id: commit.id,
                                    message: commit.message,
                                    committed_at: commit.committed_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
                                    sha: "#{branch_ref.name}@#{commit.sha}",
                                    author: {
                                      name: user.name,
                                      email: user.email,
                                    }
                                  ))
    end
  end
end
