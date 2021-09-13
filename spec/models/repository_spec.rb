# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Repository, type: :model do
  subject { FactoryBot.create(:repository, server_provider: server_provider) }

  let(:server_provider) { FactoryBot.create(:server_provider) }
  let!(:branch_ref) { FactoryBot.create(:ref, name: 'BranchRef', repository: subject, type: :branch) }
  let!(:tag_ref) { FactoryBot.create(:ref, name: 'TagRef', repository: subject, type: :tag) }

  describe '#branches' do
    it 'returns branch refs' do
      expect(subject.branches).to include(branch_ref)
    end
  end

  describe '#tags' do
    it 'returns tag refs' do
      expect(subject.tags).to include(tag_ref)
    end
  end

  describe '#repo' do
    it 'returns bare repo' do
      expect(server_provider).to receive(:bare_repo).with(subject, nil, nil)

      subject.repo
    end

    it 'authorizes and returns bare repo' do
      expect(server_provider).to receive(:bare_repo).with(subject, 'test', 'token')

      subject.repo('test', 'token')
    end
  end

  describe '#file_contents' do
    let(:bare_repo) { double }
    let(:ref) { 'ref' }
    let(:path) { 'path' }

    it 'returns file contents' do
      expect(server_provider).to receive(:bare_repo).with(subject, nil, nil).and_return(bare_repo)
      expect(bare_repo).to receive(:file_contents).with(ref, path)

      subject.file_contents(ref, path)
    end
  end
end
