# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::Users::SessionsController, type: :controller do
  let(:user) { FactoryBot.create(:user, otp_secret: User.generate_otp_secret) }
  let(:jwt_token) { 'SecretToken' }

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    allow(controller).to receive(:current_user_jwt_token).and_return(jwt_token)
  end

  describe 'POST create' do
    context 'when email and password are missing' do
      let(:params) do
        {
          user: {
            email: '',
            password: '',
          },
        }
      end

      it 'returns bad request' do
        post :create, params: params, format: :json

        expect(response).to be_bad_request
      end
    end

    context 'when user does not exist' do
      let(:params) do
        {
          user: {
            email: 'noemail@e.corp',
            password: 'e',
          },
        }
      end

      it 'returns unauthorized' do
        post :create, params: params, format: :json

        expect(response).to be_unauthorized
      end
    end

    context 'when password is incorrect' do
      let(:params) do
        {
          user: {
            email: user.email,
            password: 'e',
          },
        }
      end

      it 'returns an error' do
        post :create, params: params, format: :json

        expect(response).to be_unauthorized
        expect(response.body).to eq(JSON.dump(error: 'Invalid Email or password.'))
      end
    end

    context 'when email and password are correct' do
      let(:params) do
        {
          user: {
            email: user.email,
            password: user.password,
          },
        }
      end

      it 'returns token and otp enabled' do
        post :create, params: params, format: :json

        expect(response).to be_successful
        expect(response.body).to eq(JSON.dump(token: jwt_token, otp_enabled: false))
      end
    end

    context 'when otp is enabled and otp attempt is blank' do
      let(:params) do
        {
          user: {
            email: user.email,
            password: user.password,
          },
        }
      end

      before do
        user.otp_required_for_login = true
        user.save
      end

      it 'returns empty token and otp enabled' do
        post :create, params: params, format: :json

        expect(response).to be_successful
        expect(response.body).to eq(JSON.dump(token: '', otp_enabled: true))
      end
    end

    context 'when otp is enabled and otp attempt is present and correct' do
      let(:params) do
        {
          user: {
            email: user.email,
            password: user.password,
            otp_attempt: user.current_otp,
          },
        }
      end

      before do
        user.otp_required_for_login = true
        user.save
      end

      it 'returns token and otp enabled' do
        post :create, params: params, format: :json

        expect(response).to be_successful
        expect(response.body).to eq(JSON.dump(token: jwt_token, otp_enabled: true))
      end
    end

    context 'when otp is enabled and otp attempt is present and incorrect' do
      let(:params) do
        {
          user: {
            email: user.email,
            password: user.password,
            otp_attempt: 'random',
          },
        }
      end

      before do
        user.otp_required_for_login = true
        user.save
      end

      it 'returns unauthorized' do
        post :create, params: params, format: :json

        expect(response).to be_unauthorized
      end
    end
  end
end
