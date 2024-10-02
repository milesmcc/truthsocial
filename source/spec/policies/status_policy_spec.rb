# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

RSpec.describe StatusPolicy, type: :model do
  subject { described_class }

  let(:admin) { Fabricate(:user, admin: true) }
  let(:alice) { Fabricate(:account, username: 'alice') }
  let(:bob) { Fabricate(:account, username: 'bob') }
  let(:status) { Fabricate(:status, account: alice) }

  permissions :show?, :reblog? do
    it 'grants access when no viewer' do
      expect(subject).to permit(nil, status)
    end

    it 'denies access when viewer is blocked' do
      block = Fabricate(:block)
      status.visibility = :private
      status.account = block.target_account

      expect(subject).to_not permit(block.account, status)
    end
  end

  permissions :show? do
    it 'grants access when direct and account is viewer' do
      status.visibility = :direct

      expect(subject).to permit(status.account, status)
    end

    it 'grants access when direct and viewer is mentioned' do
      status.visibility = :direct
      status.mentions = [Fabricate(:mention, account: alice)]

      expect(subject).to permit(alice, status)
    end

    it 'denies access when direct and viewer is not mentioned' do
      viewer = Fabricate(:account)
      status.visibility = :direct

      expect(subject).to_not permit(viewer, status)
    end

    it 'grants access when private and account is viewer' do
      status.visibility = :private

      expect(subject).to permit(status.account, status)
    end

    it 'grants access when private and account is following viewer' do
      follow = Fabricate(:follow)
      status.visibility = :private
      status.account = follow.target_account

      expect(subject).to permit(follow.account, status)
    end

    it 'grants access when private and viewer is mentioned' do
      status.visibility = :private
      status.mentions = [Fabricate(:mention, account: alice)]

      expect(subject).to permit(alice, status)
    end

    context 'when tv status' do
      let(:start_time) { Time.now.to_i * 1000 }
      let(:end_time) { (Time.now.to_i + 3600) * 1000 }
      let(:program_name) { 'Test program' }
      let(:image_name) { 'test.jpg' }
      let(:tv_channel) { Fabricate(:tv_channel) }

      before do
        tv_channel.update(enabled: true)
        Fabricate(:tv_channel_account, account: alice, tv_channel: tv_channel)
        tv_program = TvProgram.create!(channel_id: tv_channel.id, name: program_name, image_url: image_name, start_time:  Time.zone.at(start_time.to_i / 1000).to_datetime, end_time:  Time.zone.at(end_time.to_i / 1000).to_datetime)
        @tv_status = Fabricate(:status, account: alice, tv_program_status?: true)
        TvProgramStatus.create!(tv_program: tv_program, tv_channel: tv_channel, status: @tv_status)
      end

      it 'grants access to tv status when feature flag is enabled for user' do
        alice.feature_flags.create!(name: 'tv', status: 'account_based')
        expect(subject).to permit(alice, @tv_status)
      end

      it 'denies access to tv status when feature flag is not enabled for user' do
        expect(subject).to_not permit(alice, @tv_status)
      end
    end

    it 'denies access when private and viewer is not mentioned or followed' do
      viewer = Fabricate(:account)
      status.visibility = :private

      expect(subject).to_not permit(viewer, status)
    end
  end

  permissions :reblog? do
    it 'denies access when private' do
      viewer = Fabricate(:account)
      status.visibility = :private

      expect(subject).to_not permit(viewer, status)
    end

    it 'denies access when direct' do
      viewer = Fabricate(:account)
      status.visibility = :direct

      expect(subject).to_not permit(viewer, status)
    end
  end

  permissions :destroy?, :unreblog? do
    it 'grants access when account is deleter' do
      expect(subject).to permit(status.account, status)
    end

    it 'grants access when account is admin' do
      expect(subject).to permit(admin.account, status)
    end

    it 'denies access when account is not deleter' do
      expect(subject).to_not permit(bob, status)
    end

    it 'denies access when no deleter' do
      expect(subject).to_not permit(nil, status)
    end
  end

  permissions :favourite? do
    it 'grants access when viewer is not blocked' do
      follow         = Fabricate(:follow)
      status.account = follow.target_account

      expect(subject).to permit(follow.account, status)
    end

    it 'denies when viewer is blocked' do
      block          = Fabricate(:block)
      status.account = block.target_account

      expect(subject).to_not permit(block.account, status)
    end
  end

  permissions :index?, :update? do
    it 'grants access if staff' do
      expect(subject).to permit(admin.account)
    end

    it 'denies access unless staff' do
      expect(subject).to_not permit(alice)
    end
  end
end
