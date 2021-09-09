# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { 'Bob Uncle' }
    email { 'bob@uncle.com' }
    password { 'TestPass#123' }
  end

  factory :server_provider do
    name { 'TestServer' }
    url { 'http://test.com/server' }
    type { 'P4ServerProvider' }
  end

  factory :server_provider_permission do
    association :user
    association :server_provider
    permission { :owner }
  end

  factory :p4_server_provider, class: 'P4ServerProvider' do
    name { 'TestP4Server' }
    url { 'http://test.com/server' }
    type { 'P4ServerProvider' }
  end

  factory :repository do
    name { 'TestRepo' }
    url { 'http://test.com/repo' }
    association :server_provider
    last_synced_at { Time.now }
  end

  factory :repository_permission do
    association :user
    association :repository
    permission { :super }
  end

  factory :ref do
    association :repository
    name { 'TestRef' }
    type { :branch }
  end
end
