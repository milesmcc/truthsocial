# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseEmailValidator, type: :validator do
  describe '#validate' do
    let(:user)   { double(email: email, errors: errors) }
    let(:errors) { double(add: nil) }
    let(:email) { 'info@mail.com' }

    before do
      stub_const('BaseEmailValidator::BASE_EMAIL_DOMAINS_VALIDATION', 'gmail.com, outlook.com')
      stub_const('EmailHelper::BASE_EMAIL_DOMAINS_VALIDATION_STRIP_DOTS', 'gmail.com')

      allow(user).to receive(:valid_invitation?) { false }
    end

    subject { described_class.new.validate(user); errors }

    context 'when the e-mail domain is not added for base domain validation' do
      let(:first_user) { Fabricate(:user, email: 'alice@yahoo.com') }
      let(:email) { 'alice+1@yahoo.com' }

      before do
        UserBaseEmail.create(user_id: first_user.id, email: first_user.email)
      end

      it 'does not add errors' do
        expect(subject).not_to have_received(:add).with(:email, :taken)
      end
    end

    context 'when the e-mail domain is added for base domain validation' do
      context 'when the e-mail contains "+"' do
        let(:second_user) { Fabricate(:user, email: 'alice@gmail.com') }
        let(:email) { 'alice+1@gmail.com' }

        before do
          UserBaseEmail.create(user_id: second_user.id, email: second_user.email)
        end

        it 'adds error' do
          expect(subject).to have_received(:add).with(:email, :taken)
        end
      end

      context 'when the e-mail contains "."' do
        context 'when the e-mail domain is added to trim "."' do
          let(:third_user) { Fabricate(:user, email: 'alice@gmail.com') }
          let(:email) { 'al.ice@gmail.com' }

          before do
            UserBaseEmail.create(user_id: third_user.id, email: third_user.email)
          end

          it 'adds error' do
            expect(subject).to have_received(:add).with(:email, :taken)
          end
        end

        context 'when the e-mail domain is not added to trim "."' do
          let(:fourth_user) { Fabricate(:user, email: 'alice@outlook.com') }
          let(:email) { 'al.ice@outlook.com' }

          before do
            UserBaseEmail.create(user_id: fourth_user.id, email: fourth_user.email)
          end

          it 'adds error' do
            expect(subject).not_to have_received(:add).with(:email, :taken)
          end
        end
      end
    end
  end
end
