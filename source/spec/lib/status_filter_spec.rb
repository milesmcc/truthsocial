# frozen_string_literal: true

require 'rails_helper'

describe StatusFilter do
  describe '#filtered?' do
    let(:status) { Fabricate(:status) }

    context 'without an account' do
      subject { described_class.new(status, nil) }

      context 'when there are no connections' do
        it { is_expected.not_to be_filtered }
      end

      context 'when status account is silenced' do
        before do
          status.account.silence!
        end

        it { is_expected.to be_filtered }
      end

      context 'when status policy does not allow show' do
        before do
          expect_any_instance_of(StatusPolicy).to receive(:show?).and_return(false)
        end

        it { is_expected.to be_filtered }
      end
    end

    context 'with real account' do
      let(:account) { Fabricate(:account) }
      subject { described_class.new(status, account) }

      context 'when there are no connections' do
        it { is_expected.not_to be_filtered }
      end

      context 'when status account is blocked' do
        before do
          Fabricate(:block, account: account, target_account: status.account)
        end

        it { is_expected.to be_filtered }
      end

      context 'when status account domain is blocked' do
        before do
          status.account.update(domain: 'example.com')
          Fabricate(:account_domain_block, account: account, domain: status.account_domain)
        end

        it { is_expected.to be_filtered }
      end

      context 'when status account is muted' do
        before do
          Fabricate(:mute, account: account, target_account: status.account)
        end

        it { is_expected.to be_filtered }
      end

      context 'when status account is silenced' do
        before do
          status.account.silence!
        end

        it { is_expected.to be_filtered }
      end

      context 'when status policy does not allow show' do
        before do
          expect_any_instance_of(StatusPolicy).to receive(:show?).and_return(false)
        end

        it { is_expected.to be_filtered }
      end
    end
  end
end
