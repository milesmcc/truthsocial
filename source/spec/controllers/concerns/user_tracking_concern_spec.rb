# frozen_string_literal: true

require 'rails_helper'

describe ApplicationController, type: :controller do
  controller do
    include UserTrackingConcern

    def show
      render plain: 'show'
    end
  end

  before do
    routes.draw { get 'show' => 'anonymous#show' }
    stub_const('UserTrackingConcern::TRACKED_CONTROLLERS', ['anonymous'])
  end

  describe 'when signed in' do
    let(:user) { Fabricate(:user) }

    it 'does not track when the user has signed in today' do
      user.update(current_sign_in_at: Date.today + 2.hours )
      prior = user.current_sign_in_at

      travel_to(Date.today + 3.hours) do
        sign_in user, scope: :user
        get :show
        expect(user.reload.current_sign_in_at).to eq(Date.today + 2.hours)
      end
    end

    it 'tracks when sign in is nil' do
      user.update(current_sign_in_at: nil)
      sign_in user, scope: :user
      get :show

      expect_updated_sign_in_at(user)
    end

    it 'tracks when the last sign in is yesterday' do
      user.update(current_sign_in_at: Date.yesterday + 5.hours)

      travel_to(Date.today + 3.hours) do
        sign_in user, scope: :user
        get :show

        expect(user.reload.current_sign_in_at).to eq(Date.today + 3.hours)
        expect(user.reload.current_sign_in_ip).to eq(request.remote_ip)
        expect(user.user_current_information.current_sign_in_at).to eq(Date.today + 3.hours)
        expect(user.user_current_information.current_sign_in_ip).to eq(request.remote_ip)
        expect(user.user_current_information.current_city_id).to eq(1)
      end

    end

    it 'updates current city' do
      travel_to(Date.today + 3.hours) do
        sign_in user, scope: :user

        request.headers['Geoip-City-Name'] = 'Timbuktu'
        request.headers['Geoip-Country-Code'] = 'US'
        request.headers['Geoip-Country-Name'] = 'United States'
        request.headers['Geoip-Region-Name'] = 'Washington'
        request.headers['Geoip-Region-Code'] = 'WA'

        get :show

        city = City.find_by(name: 'Timbuktu')
        region = Region.find_by(name: 'Washington', code: 'WA')

        expect(user.user_current_information.current_city_id).to eq(city.id)
        expect(city.region).to eq(region)
        expect(region.country).to eq(Country.find_by(name: 'United States', code: 'US'))
      end
    end

    describe 'interactions score' do
      before do
        stub_const('UserTrackingConcern::INTERACTIONS_SCORE_TRACKED_CONTROLLER', 'anonymous')

        user.account.update(interactions_score: 5)

        current_week = Time.now.strftime('%U').to_i
        last_week = Time.now.strftime('%U').to_i - 1

        Redis.current.set("interactions_score:#{user.account.id}:#{current_week}", 20)
        Redis.current.set("interactions_score:#{user.account.id}:#{last_week}", 10)
      end
      it 'does not update interactions when there is a recent sign in' do
        user.update(current_sign_in_at: 60.minutes.ago)

        sign_in user, scope: :user
        get :show

        expect(user.account.reload.interactions_score).to eq(5)
      end

      it 'updates interactions when sign in is nil' do
        user.update(current_sign_in_at: nil)

        sign_in user, scope: :user
        get :show

        expect(user.account.reload.interactions_score).to eq(30)
      end

      it 'updates interactions when sign in is older than one day' do
        user.update(current_sign_in_at: 2.days.ago)
        sign_in user, scope: :user
        get :show

        expect(user.account.reload.interactions_score).to eq(30)
      end

    end

    describe 'feed regeneration' do
      before do
        allow_any_instance_of(Redisable).to receive(:redis_timelines).and_return(Redis.current)
        alice = Fabricate(:account)
        bob   = Fabricate(:account)

        user.account.follow!(alice)
        user.account.follow!(bob)

        Fabricate(:status, account: alice, text: 'hello world')
        Fabricate(:status, account: bob, text: 'yes hello')
        Fabricate(:status, account: user.account, text: 'test')

        user.update(last_sign_in_at: 'Tue, 04 Jul 2017 14:45:56 UTC +00:00', current_sign_in_at: 'Wed, 05 Jul 2017 22:10:52 UTC +00:00')

        sign_in user, scope: :user
      end

      it 'does not set a regeneration marker because regeneration is being performed upon request, not upon login' do
        allow(RegenerationWorker).to receive(:perform_async)
        get :show

        expect_updated_sign_in_at(user)
        expect(Redis.current.exists?("account:#{user.account_id}:regeneration")).to eq false
        expect(RegenerationWorker).to_not have_received(:perform_async)
      end

      it 'sets the regeneration marker to expire' do
        allow(RegenerationWorker).to receive(:perform_async)
        get :show
        expect(Redis.current.ttl("account:#{user.account_id}:regeneration")).to be < 0 # negative because key doesn't exist
      end

      it 'regenerates feed when sign in is older than two weeks' do
        get :show
        expect_updated_sign_in_at(user)
        expect(Redis.current.zcard(FeedManager.instance.key(:home, user.account_id))).to eq 0
        expect(Redis.current.get("account:#{user.account_id}:regeneration")).to be_nil
      end
    end

    def expect_updated_sign_in_at(user)
      expect(user.reload.current_sign_in_at).to be_within(1.0).of(Time.now.utc)
    end
  end
end
