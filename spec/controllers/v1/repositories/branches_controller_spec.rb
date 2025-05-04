# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::Repositories::BranchesController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:repository) { FactoryBot.create(:repository, created_by: user.id, owner_id: organization.id, owner_type: 'Organization', server_type: 'perforce') }
  let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: user) }
  let!(:branch_ref) { FactoryBot.create(:ref, name: 'BranchRef', repository: repository, type: :branch) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    it 'returns branches for specified repository' do
      get :index, params: { repository_id: repository.id }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump([{ id: branch_ref.id, name: branch_ref.name, commit: nil }]))
    end
  end

  describe 'GET show' do
    it 'returns specified branch from specified repository' do
      get :show, params: { repository_id: repository.id, id: branch_ref.id }

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(id: branch_ref.id, name: branch_ref.name, commit: nil))
    end
  end
end
