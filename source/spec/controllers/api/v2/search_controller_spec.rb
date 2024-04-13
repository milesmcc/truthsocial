# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::SearchController, type: :controller do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:search') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, params: { q: 'test' }

      expect(response).to have_http_status(200)
    end

    it 'returns tags by name' do
      tag_name = 'trump2020'
      Tag.create!(name: tag_name)
      get :index, params: { q: 'trump', type: 'hashtags' }

      expect(response).to have_http_status(200)
      expect(body_as_json[:hashtags].size).to eq(1)
      hashtag = body_as_json[:hashtags].first.with_indifferent_access
      expect_to_be_a_tag(hashtag)
      expect(hashtag[:name]).to eq(tag_name)
      expect(hashtag[:recent_statuses_count]).to eq(0)
    end

    it 'returns both tags and accounts by name' do
      query = 'trump'
      Fabricate(:account, username: query)
      tag_name = 'trump2020'
      Tag.create!(name: tag_name)
      get :index, params: { q: query }

      expect(response).to have_http_status(200)
      expect(body_as_json[:accounts].size).to eq(1)
      expect(body_as_json[:accounts].first[:username]).to eq query
      expect(body_as_json[:hashtags].size).to eq(1)
      hashtag = body_as_json[:hashtags].first.with_indifferent_access
      expect_to_be_a_tag(hashtag)
      expect(hashtag[:name]).to eq(tag_name)
    end

    it 'returns tags by limit and offset' do
      query = 'trump'
      Fabricate(:account, username: query)
      tag_name1 = 'trump2020'
      tag_name2 = 'trump2028'
      Tag.create!([{ name: tag_name1 }, { name: tag_name2 }])
      get :index, params: { q: query, type: 'hashtags', limit: 1, offset: 1 }

      expect(response).to have_http_status(200)
      expect(body_as_json[:hashtags].size).to eq(1)
      hashtag = body_as_json[:hashtags].first.with_indifferent_access
      expect_to_be_a_tag(hashtag)
      expect(hashtag[:name]).to eq(tag_name2)
    end
  end
end
