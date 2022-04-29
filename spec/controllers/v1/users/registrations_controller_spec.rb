# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::Users::RegistrationsController, type: :controller do
  before { @request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'POST create' do
    let(:sign_up_params) do
      {
        email: 'new@user.com',
        password: 'Stronk$PASS123',
        password_confirmation: 'Stronk$PASS123',
      }
    end

    context 'when user creation is successful' do
      it 'creates user' do
        expect do
          post :create, params: { user: sign_up_params }
        end.to change(User, :count).by(1)

        expect(response).to be_successful
      end
    end

    context 'when user creation is unsuccessful' do
      before do
        sign_up_params[:password_confirmation] = 'e'
      end

      it 'does not create user and returns unprocessible entity' do
        expect do
          post :create, params: { user: sign_up_params }
        end.not_to change(User, :count)

        expect(response.status).to eq(422)
      end
    end
  end

  describe 'DELETE destroy' do
    let(:user) { FactoryBot.create(:user, otp_required_for_login: true) }

    before do
      sign_in(user)
    end

    context 'when request has feedback' do
      let(:params) do
        {
          password: 'TestPass#123',
          feedback: {
            reason: 'Reason',
            text: 'Text',
          },
        }
      end
      let(:feedback_mailer) { double }
      let(:mail_promise) { double }

      it 'removes user, sends feedback' do
        expect(FeedbackMailer).to receive(:with).and_return(feedback_mailer)
        expect(feedback_mailer).to receive(:send_feedback).and_return(mail_promise)
        expect(mail_promise).to receive(:deliver_now)

        delete :destroy, params: params

        expect(response).to be_successful
        expect(user.reload.active).to be_falsey
      end
    end

    context 'when request does not have feedback' do
      let(:params) do
        {
          password: 'TestPass#123',
        }
      end

      it 'removes user, sends feedback' do
        expect(FeedbackMailer).not_to receive(:with)

        delete :destroy, params: params

        expect(response).to be_successful
        expect(user.reload.active).to be_falsey
      end
    end

    context 'when password is incorrect' do
      let(:params) do
        {
          password: 'Test123',
        }
      end

      it 'removes user, sends feedback' do
        expect(FeedbackMailer).not_to receive(:with)

        delete :destroy, params: params

        expect(response.status).to eq(422)
        expect(user.reload.active).to be_truthy
      end
    end
  end
end
