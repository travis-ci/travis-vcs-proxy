# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject { FactoryBot.create(:user) }

  let(:server_provider) { FactoryBot.create(:server_provider) }

  context 'with server_providers' do
    let!(:server_provider_permission) { FactoryBot.create(:server_provider_permission, server_provider: server_provider, user: subject) }

    describe '#server_provider_permission' do
      it 'returns permissions for specified server provider' do
        result = subject.server_provider_permission(server_provider.id)

        expect(result).to eq(server_provider_permission)
      end
    end

    describe '#set_server_provider_permission' do
      it 'sets permissions for specified server provider' do
        subject.set_server_provider_permission(server_provider.id, :member)

        expect(server_provider_permission.reload.permission).to eq('member')
      end
    end
  end

  context 'with repositories' do
    let(:repository) { FactoryBot.create(:repository, server_provider: server_provider) }
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
