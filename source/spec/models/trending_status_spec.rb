require 'rails_helper'

describe TrendingStatus do
  describe '.refresh_trending_statuses' do
    let(:trending_account1) { Fabricate(:account, username: 'alice') }
    let(:trending_account2) { Fabricate(:account, username: 'bob') }
    let(:john) { Fabricate(:account, username: 'john') }
    let(:harry) { Fabricate(:account, username: 'harry') }
    let(:robert) { Fabricate(:account, username: 'robert') }
    let(:trending_status1) { Fabricate(:status, account: trending_account1) }
    let(:trending_status2) { Fabricate(:status, account: trending_account2) }
    let(:not_trending_status1) { Fabricate(:status) }
    let(:not_trending_status2) { Fabricate(:status) }

    before do
      TrendingStatusSetting.find_by!(name: 'maximum_statuses_per_account').update!(value: '1')
      TrendingStatusSetting.find_by!(name: 'popular_minimum_followers').update!(value: '1')
      TrendingStatusSetting.find_by!(name: 'status_reblog_weight').update!(value: '1')
      TrendingStatusSetting.find_by!(name: 'viral_maximum_followers').update!(value: '2')
      TrendingStatusSetting.find_by!(name: 'viral_minimum_followers').update!(value: '1')

      4.times do |i|
        user = Fabricate.create(:user, email: "test_a#{i}@example.com", password: "password") do
          account { Fabricate(:account, username: "test#{i}") }
        end

        user_account = user.account
        user_account.follow!(trending_account2)
        FavouriteService.new.call(user_account, trending_status1)
        trending_status1.reload

        ReblogService.new.call(user_account, trending_status1, visibility: "public")
        PostStatusService.new.call(user_account, text: "REPLYING", thread: trending_status1)
      end

      4.times do |i|
        user = Fabricate.create(:user, email: "test_b_#{i}@example.com", password: "password") do
          account { Fabricate(:account, username: "test_b_#{i}") }
        end

        user_account = user.account
        FavouriteService.new.call(user_account, trending_status2)
        trending_status2.reload

        ReblogService.new.call(user_account, trending_status2, visibility: "public")
        PostStatusService.new.call(user_account, text: "REPLYING", thread: trending_status2)
      end

      Follow.create!(account: john, target_account: trending_account1)
      Follow.create!(account: harry, target_account: trending_account1)
      Procedure.process_all_statistics_queues
      Procedure.refresh_trending_statuses
    end

    context "statuses within last 36 hours" do
      it "should retrieve a new list of interwoven 'viral' and 'popular' trending statuses" do
        trending_statuses = TrendingStatus.all
        expect(trending_statuses.count).to eq(2)
        expect(trending_statuses.pluck(:status_id).uniq.sort).to eq([trending_status1.id, trending_status2.id])
        expect(trending_statuses.pluck(:status_id)).not_to include(not_trending_status1.id, not_trending_status2.id)
      end
    end

    context "statuses within and without the 36 hour time frame" do
      let(:trending_status2) { Fabricate(:status, account: trending_account2, created_at: 2.days.ago ) }

      it "should only retrieve trending statuses that are within the last 36 hours" do
        Procedure.process_all_statistics_queues
        Procedure.refresh_trending_statuses

        trending_statuses = TrendingStatus.all
        expect(trending_statuses.count).to eq(1)
        expect(trending_statuses.pluck(:status_id).uniq.sort).to eq([trending_status1.id])
        expect(trending_statuses.pluck(:status_id)).not_to include(trending_status2.id)
      end
    end

    context "excluding a status" do
      let(:trending_status3) { Fabricate(:status, account: harry, text: 'She was a lady') }

      before do
        2.times do |i|
          user = Fabricate.create(:user, email: "test_d_#{i}@example.com", password: "password") do
            account { Fabricate(:account, username: "test_d_#{i}") }
          end

          user_account = user.account
          FavouriteService.new.call(user_account, trending_status3)
          trending_status3.reload
          ReblogService.new.call(user_account, trending_status3, visibility: "public")
          PostStatusService.new.call(user_account, text: "REPLYING", thread: trending_status3)
        end

        Follow.create!(account: john, target_account: harry)
        Follow.create!(account: robert, target_account: harry)
        TrendingStatusExcludedExpression.create!(expression: 'lady')
        Procedure.process_all_statistics_queues
        Procedure.refresh_trending_statuses
      end

      it "should exclude statuses from trending list that match an expression" do
        trending_statuses = TrendingStatus.all

        expect(trending_statuses.count).to eq(2)
        expect(trending_statuses.pluck(:status_id).uniq.sort).to eq([trending_status1.id, trending_status2.id])
        expect(trending_statuses.pluck(:status_id)).not_to include(trending_status3.id)
      end
    end
  end
end
