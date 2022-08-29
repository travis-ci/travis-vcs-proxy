# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject { FactoryBot.create(:user) }

  let(:organization) { FactoryBot.create(:organization) }

  context 'with organizations' do
    let!(:organization_permission) { FactoryBot.create(:organization_permission, organization: organization, user: subject) }

    describe '#organization_permission' do
      it 'returns permissions for specified organization' do
        result = subject.organization_permission(organization.id)

        expect(result).to eq(organization_permission)
      end
    end

    describe '#set_organization_permission' do
      it 'sets permissions for specified organization' do
        subject.set_organization_permission(organization.id, :member)

        expect(organization_permission.reload.permission).to eq('member')
      end
    end
  end

  context 'with repositories' do
    let(:repository) { FactoryBot.create(:repository, created_by: subject.id, owner_id: organization.id, owner_type: 'Organization', server_type: 'perforce', listener_token: 'token') }
    let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: subject) }

    describe '#repository_permission' do
      it 'returns permissions for specified repository' do
        result = subject.repository_permission(repository.id)

        expect(result).to eq(repository_permission)
      end
    end
  end

  describe '#mark_as_deleted' do
    it 'obfuscates user email, name and marks inactive' do
      subject.mark_as_deleted

      expect(subject.reload.email).to include('deleted_email_')
      expect(subject.name).to eq(nil)
      expect(subject.active).to be_falsey
    end
  end
end
