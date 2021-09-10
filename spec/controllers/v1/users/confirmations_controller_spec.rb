# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::Users::ConfirmationsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  before { @request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET show' do
    let(:confirmation_token) { 'TOKTOKTOKTOKTOK' }

    before do
      allow(User).to receive(:confirm_by_token).with(confirmation_token).and_return(user)
    end

    context 'when confirmation token is valid' do
      it 'confirms the user and redirects to confirmed url' do
        get :show, params: { confirmation_token: confirmation_token }

        expect(response).to redirect_to(URI.join(Settings.web_url, 'confirmed').to_s)
      end
    end

    context 'when confirmation token is invalid' do
      before do
        user.errors.add('token invalid')
      end

      it 'redirects to unconfirmed page' do
        get :show, params: { confirmation_token: confirmation_token }

        redirect_uri = URI.join(Settings.web_url, 'unconfirmed')
        redirect_uri.query = 'error=expired'
        expect(response).to redirect_to(redirect_uri.to_s)
      end
    end
  end

  describe 'POST resend' do
    context 'when email is present and user is not confirmed' do
      before do
        allow_any_instance_of(User).to receive(:confirmed?).and_return(false)
      end

      it 'resends the confirmation email' do
        expect_any_instance_of(User).to receive(:resend_confirmation_instructions)

        post :resend, params: { email: user.email }

        expect(response).to be_successful
      end
    end

    context 'when email is present and user is confirmed' do
      before do
        allow_any_instance_of(User).to receive(:confirmed?).and_return(true)
      end

      it 'does not resend the confirmation email' do
        expect_any_instance_of(User).not_to receive(:resend_confirmation_instructions)

        post :resend, params: { email: user.email }

        expect(response).to be_successful
      end
    end

    context 'when email is not present' do
      it 'responds with bad request' do
        post :resend

        expect(response).to be_bad_request
      end
    end
  end
end
