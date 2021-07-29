# frozen_string_literal: true

class V1::WebhooksController < ApplicationController
  def receive
    head :unauthorized and return unless server_provider = ServerProvider.find_by(listener_token: params[:token])

    connection = Travis::VcsProxy::P4Connection.new(server_provider.url, server_provider.settings(:p4_host).username, server_provider.token)
    head :internal_server_error unless commit_info = connection.commit_info(params[:change_root], params[:username])

    # TODO: Figure out if we should really ignore the hook if there is no user with the given email
    head :ok and return unless user = server_provider.users.find_by(email: commit_info[:email])
    # TODO: Figure out if we should really ignore the hook if there is no repository with this name
    head :ok and return unless repository = server_provider.repositories.find_by(name: commit_info[:repository_name])

    ref = repository.refs.branch.find_by(name: commit_info[:ref]) || repository.refs.branch.create(name: commit_info[:ref])
    head :unprocessable_entity and return unless ref

    commit = ref.commits.find_by(sha: params[:sha]) || ref.commits.create(sha: params[:sha], repository: repository, user: user)
    head :unprocessable_entity and return unless commit

    head :ok
  end
end
