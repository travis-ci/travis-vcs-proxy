# frozen_string_literal: true

require 'rails_helper'

RSpec.describe P4ServerProvider, type: :model do
  subject { FactoryBot.create(:p4_server_provider) }

  describe '#bare_repo' do
    context 'when username and password passed' do
      let(:username) { 'username' }
      let(:password) { '1337PASSWORD' }

      it 'uses provided user and password to return bare repo' do
        expect(Travis::VcsProxy::Repositories::P4).to receive(:new).with(nil, subject.url, username, password).and_call_original

        expect(subject.bare_repo(nil, username, password)).to be_instance_of(Travis::VcsProxy::Repositories::P4)
      end
    end

    context 'when repository passed' do
      let(:username) { 'username' }
      let(:token) { 'testtoken' }
      let(:repo) { FactoryBot.create(:repository, server_provider: subject, token: token) }

      before do
        repo.settings(:p4_host).username = username
      end

      it 'uses repo user and token to return bare repo' do
        expect(Travis::VcsProxy::Repositories::P4).to receive(:new).with(repo, subject.url, username, token).and_call_original

        expect(subject.bare_repo(repo)).to be_instance_of(Travis::VcsProxy::Repositories::P4)
      end
    end

    context 'when nothing is passed' do
      let(:username) { 'username' }
      let(:token) { 'testtoken' }

      before do
        subject.settings(:p4_host).username = username
        subject.token = token
      end

      it 'uses server user and token' do
        expect(Travis::VcsProxy::Repositories::P4).to receive(:new).with(nil, subject.url, username, token).and_call_original

        expect(subject.bare_repo).to be_instance_of(Travis::VcsProxy::Repositories::P4)
      end
    end
  end

  describe '#remote_repositories' do
    it 'returns remote repositories' do
      expect(subject).to receive(:bare_repo).and_call_original
      expect_any_instance_of(Travis::VcsProxy::Repositories::P4).to receive(:repositories)

      subject.remote_repositories
    end
  end

  describe '#commit_info_from_webhook' do
    context 'when payload does not contain change_root and username' do
      it 'return nil' do
        expect(subject.commit_info_from_webhook({})).to eq(nil)
      end
    end

    context 'when payload contains change_root and username' do
      let(:payload) { { change_root: 'test', username: 'user' } }

      it 'returns commit info from webhook' do
        expect(subject).to receive(:bare_repo).and_call_original
        expect_any_instance_of(Travis::VcsProxy::Repositories::P4).to receive(:commit_info).with(payload[:change_root], payload[:username]).and_return('test')

        expect(subject.commit_info_from_webhook(payload)).to eq('test')
      end
    end
  end

  describe '#provider_type' do
    it 'returns provider_type' do
      expect(subject.provider_type).to eq('perforce')
    end
  end

  describe '#default_branch' do
    it 'returns default_branch' do
      expect(subject.default_branch).to eq('master')
    end
  end
end
