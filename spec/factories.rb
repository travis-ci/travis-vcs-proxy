# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { 'Bob Uncle' }
    email { 'bob@uncle.com' }
    password { 'TestPass#123' }
    confirmed_at { Date.today }
  end

  factory :organization do
    name { 'TestOrg' }
    description { 'test' }
  end

  factory :organization_permission do
    association :user
    association :organization
    permission { :owner }
  end

  factory :repository do
    name { 'TestRepo' }
    display_name { 'TestRepo' }
    url { 'http://test.com/repo' }
    last_synced_at { Time.now }
  end

  factory :repository_permission do
    association :user
    association :repository
    permission { :super }
  end

  factory :repository_user_setting do
    username { :super }
    value { :super }
  end

  factory :ref do
    association :repository
    name { 'TestRef' }
    type { :branch }
  end

  factory :commit do
    association :ref
    association :repository
    association :user
    sha { 'COMMIT_SHA' }
    message { 'Commit Message' }
    committed_at { '2021-09-01 00:00:00' }
  end

  factory :webhook do
    association :repository
    name { 'RepoWebHook' }
    url { 'https://webhook.repo/' }
    active { true }
    insecure_ssl { false }
    created_at { '2021-09-01 00:00:00' }
  end
end
