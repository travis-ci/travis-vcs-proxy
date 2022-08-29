# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::UsersController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    it 'returns the user representation' do
      get :show

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(
                                    id: user.id,
                                    otp_required_for_login: user.otp_required_for_login,
                                    name: user.name,
                                    login: user.email,
                                    emails: [user.email],
                                    organizations: [],
                                    uuid: user.id,
                                    permission: '',
                                    org_permissions: []
                                  ))
    end
  end

  describe 'PATCH update_email' do
    let(:params) do
      {
        email: 'email@ecorp.com',
      }
    end

    context 'when email is provided' do
      it 'updates the email' do
        patch :update_email, params: params

        expect(response).to be_successful
        expect(user.reload.unconfirmed_email).to eq(params[:email])
      end
    end

    context 'when email is not provided' do
      before { params[:email] = '' }

      it 'does not update the email' do
        patch :update_email, params: params

        expect(response).to be_bad_request
        expect(user.reload.unconfirmed_email).to eq(nil)
      end
    end
  end

  describe 'PATCH update_password' do
    let(:new_password) { 'Stronk$Pass123' }
    let(:params) do
      {
        current_password: user.password,
        password: new_password,
        password_confirmation: new_password,
      }
    end

    context 'when valid password is provided' do
      it 'changes the password' do
        patch :update_password, params: params

        expect(response).to be_successful
      end
    end

    context 'when one of the parameters is not provided' do
      before { params[:password] = '' }

      it 'returns an error' do
        patch :update_password, params: params

        expect(response).to be_bad_request
      end
    end

    context 'when new password does not match confirmation' do
      before { params[:password] = 'e' }

      it 'returns an error' do
        patch :update_password, params: params

        expect(response.status).to eq(422)
        expect(response.body).to eq(JSON.dump(errors: ['Password does not match confirmation']))
      end
    end

    context 'when new password does not meet requirements' do
      before do
        params[:password] = 'e'
        params[:password_confirmation] = 'e'
      end

      it 'returns an error' do
        patch :update_password, params: params

        expect(response.status).to eq(422)
        expect(response.body).to eq(JSON.dump(errors: { password: ['is too short (minimum is 6 characters)', 'should contain a non-alphabet character (number or special character)'] }))
      end
    end

    context 'when current password does not match' do
      before { params[:current_password] = 'e' }

      it 'returns an error' do
        patch :update_password, params: params

        expect(response.status).to eq(422)
        expect(response.body).to eq(JSON.dump(errors: ['Invalid current password']))
      end
    end
  end

  describe 'POST request_password_reset' do
    let(:params) do
      {
        email: user.email,
      }
    end

    context 'when email is blank' do
      before { params[:email] = '' }

      it 'returns no error' do
        post :request_password_reset, params: params

        expect(response).to be_successful
      end
    end

    context 'when email does not belong to any user' do
      before { params[:email] = 'no@email.exists' }

      it 'returns no error' do
        post :request_password_reset, params: params

        expect(response).to be_successful
      end
    end

    context 'when email belongs to the user' do
      it 'returns no error and requests password reset' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions)

        post :request_password_reset, params: params

        expect(response).to be_successful
      end
    end
  end

  describe 'POST reset_password' do
    let(:new_password) { 'Stronk$Pass123' }
    let(:params) do
      {
        reset_password_token: 'token',
        password: new_password,
        password_confirmation: new_password,
      }
    end

    context 'when all parameters are present and correct' do
      before do
        allow(User).to receive(:reset_password_by_token).and_return(user)
      end

      it 'resets the password' do
        post :reset_password, params: params

        expect(response).to be_successful
      end
    end

    context 'when reset token is not correct' do
      before do
        allow(User).to receive(:reset_password_by_token).and_return(user)
        user.errors.add(:password, 'Failed')
      end

      it 'resets the password' do
        post :reset_password, params: params

        expect(response.status).to eq(422)
        expect(response.body).to eq(JSON.dump(errors: { password: ['Failed'] }))
      end
    end
  end

  describe 'GET emails' do
    it 'returns users emails' do
      get :emails

      expect(response).to be_successful
      expect(response.body).to eq(JSON.dump(emails: [user.email]))
    end
  end

  describe 'GET repositories' do
    let(:organization) { FactoryBot.create(:organization) }
    let(:repository) { FactoryBot.create(:repository, created_by: user.id, owner_id: organization.id, owner_type: 'Organization', server_type: 'perforce') }
    let!(:repository_permission) { FactoryBot.create(:repository_permission, repository: repository, user: user) }

    it 'returns users repositories' do
      get :repositories

      expect(response).to be_successful
    end
  end

  describe 'POST sync' do
    it 'schedules sync for server provider' do
      expect(SyncJob).to receive(:perform_later).with(SyncJob::SyncType::USER, user.id)

      post :sync

      expect(response).to be_successful
    end
  end
end
