# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::Users::TwoFactorAuthController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in(user) }

  describe 'GET url' do
    let(:otp_secret) { 'secret' }

    it 'generates otp secret and returns the url' do
      allow(User).to receive(:generate_otp_secret).and_return(otp_secret)

      get :url

      expect(JSON.parse(response.body)).to eq('url' => "otpauth://totp/Travis%20CI%20VCS%20Proxy:bob%40uncle.com?secret=#{otp_secret}&issuer=Travis%20CI%20VCS%20Proxy")
      expect(user.reload.otp_secret).to eq(otp_secret)
    end
  end

  describe 'POST enable' do
    before do
      user.otp_secret = User.generate_otp_secret
      user.save
    end

    context 'when provided otp_attempt is incorrect' do
      let(:otp_attempt) { '21345' }

      it 'returns an error' do
        post :enable, params: { otp_attempt: otp_attempt }

        expect(response.status).to eq(422)
      end
    end

    context 'when provided otp_attempt is correct' do
      let(:otp_attempt) { user.current_otp }
      let(:jwt_token) { 'SecretToken' }

      before { allow(controller).to receive(:current_user_jwt_token).and_return(jwt_token) }

      it 'revokes old token and returns new token' do
        expect(User).to receive(:revoke_jwt)

        post :enable, params: { otp_attempt: otp_attempt }

        expect(response).to be_successful
        expect(response.body).to eq(JSON.dump(token: jwt_token, otp_enabled: true))
      end
    end
  end

  describe 'GET codes' do
    let(:codes) { 'codes' }

    context 'when generation is successful' do
      before do
        allow_any_instance_of(User).to receive(:generate_otp_backup_codes!).and_return(codes)
      end

      it 'returns the recoery codes' do
        get :codes

        expect(response).to be_successful
        expect(response.body).to eq(JSON.dump(codes: codes))
      end
    end

    context 'when generation is not successful' do
      before do
        allow_any_instance_of(User).to receive(:save).and_return(false)
      end

      it 'returns unprocessible entity' do
        get :codes

        expect(response.status).to eq(422)
      end
    end
  end
end
