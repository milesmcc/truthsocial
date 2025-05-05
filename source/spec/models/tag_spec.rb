require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'validations' do
    it 'invalid with #' do
      expect(Tag.new(name: '#hello_world')).to_not be_valid
    end

    it 'invalid with .' do
      expect(Tag.new(name: '.abcdef123')).to_not be_valid
    end

    it 'invalid with spaces' do
      expect(Tag.new(name: 'hello world')).to_not be_valid
    end

    it 'valid with ａｅｓｔｈｅｔｉｃ' do
      expect(Tag.new(name: 'ａｅｓｔｈｅｔｉｃ')).to be_valid
    end
  end

  describe '#unlist_bannable_tags' do
    it 'should set listable and trendable to false' do
      word =  BannedWord.pluck(:word).sample
      tag = Tag.create!(name: word)
      expect(tag.listable).to eq false
      expect(tag.trendable).to eq false
    end

    it 'should set listable and trendable to false if banned word is included in tag name' do
      word =  BannedWord.pluck(:word).sample
      tag = Tag.create!(name: "Test#{word}Test")
      expect(tag.listable).to eq false
      expect(tag.trendable).to eq false
    end

    it 'should not set listable and trendable to false if banned word is not included in tag name' do
      word = 'Nothing_bad'
      tag = Tag.create!(name: "Test#{word}Test")
      expect(tag.listable).to be true
      expect(tag.trendable).to eq true
    end
  end

  describe 'HASHTAG_RE' do
    subject { Tag::HASHTAG_RE }

    it 'does not match URLs with anchors with non-hashtag characters' do
      expect(subject.match('Check this out https://medium.com/@alice/some-article#.abcdef123')).to be_nil
    end

    it 'does not match URLs with hashtag-like anchors' do
      expect(subject.match('https://en.wikipedia.org/wiki/Ghostbusters_(song)#Lawsuit')).to be_nil
    end

    it 'matches ﻿#ａｅｓｔｈｅｔｉｃ' do
      expect(subject.match('﻿this is #ａｅｓｔｈｅｔｉｃ').to_s).to eq ' #ａｅｓｔｈｅｔｉｃ'
    end

    it 'matches digits at the start' do
      expect(subject.match('hello #3d').to_s).to eq ' #3d'
    end

    it 'matches digits in the middle' do
      expect(subject.match('hello #l33ts35k').to_s).to eq ' #l33ts35k'
    end

    it 'matches digits at the end' do
      expect(subject.match('hello #world2016').to_s).to eq ' #world2016'
    end

    it 'matches underscores at the beginning' do
      expect(subject.match('hello #_test').to_s).to eq ' #_test'
    end

    it 'matches underscores at the end' do
      expect(subject.match('hello #test_').to_s).to eq ' #test_'
    end

    it 'matches underscores in the middle' do
      expect(subject.match('hello #one_two_three').to_s).to eq ' #one_two_three'
    end

    it 'matches middle dots' do
      expect(subject.match('hello #one·two·three').to_s).to eq ' #one·two·three'
    end

    it 'matches ZWNJ' do
      expect(subject.match('just add #نرم‌افزار and').to_s).to eq ' #نرم‌افزار'
    end

    it 'does not match middle dots at the start' do
      expect(subject.match('hello #·one·two·three')).to be_nil
    end

    it 'does not match middle dots at the end' do
      expect(subject.match('hello #one·two·three·').to_s).to eq ' #one·two·three'
    end

    it 'does not match purely-numeric hashtags' do
      expect(subject.match('hello #0123456')).to be_nil
    end
  end

  describe '#to_param' do
    it 'returns name' do
      tag = Fabricate(:tag, name: 'foo')
      expect(tag.to_param).to eq 'foo'
    end
  end

  describe '.find_normalized' do
    it 'returns tag for a multibyte case-insensitive name' do
      upcase_string   = 'abcABCａｂｃＡＢＣ'
      downcase_string = 'abcabcａｂｃａｂｃ';

      tag = Fabricate(:tag, name: downcase_string)
      expect(Tag.find_normalized(upcase_string)).to eq tag
    end
  end

  describe '.matches_name' do
    it 'returns tags for multibyte case-insensitive names' do
      upcase_string   = 'abcABCａｂｃＡＢＣ'
      downcase_string = 'abcabcａｂｃａｂｃ';

      tag = Fabricate(:tag, name: downcase_string)
      expect(Tag.matches_name(upcase_string)).to eq [tag]
    end

    it 'uses the LIKE operator' do
      expect(Tag.matches_name('100%abc').to_sql).to eq %q[SELECT "tags".* FROM "tags" WHERE LOWER("tags"."name") LIKE '100\\%abc%']
    end
  end

  describe '.matching_name' do
    it 'returns tags for multibyte case-insensitive names' do
      upcase_string   = 'abcABCａｂｃＡＢＣ'
      downcase_string = 'abcabcａｂｃａｂｃ';

      tag = Fabricate(:tag, name: downcase_string)
      expect(Tag.matching_name(upcase_string)).to eq [tag]
    end
  end

  describe '.find_or_create_by_names' do
    it 'runs a passed block once per tag regardless of duplicates' do
      upcase_string   = 'abcABCａｂｃＡＢＣやゆよ'
      downcase_string = 'abcabcａｂｃａｂｃやゆよ';
      count           = 0

      Tag.find_or_create_by_names([upcase_string, downcase_string]) do |tag|
        count += 1
      end

      expect(count).to eq 1
    end
  end

  describe '.search_for' do
    it 'finds tag records with matching names' do
      tag_name = "match"
      Fabricate(:tag, name: tag_name)
      Fabricate(:tag, name: "miss")

      serialized_result = Tag.search_for("match", 10, 0)

      result = JSON.parse(serialized_result).first
      expect_to_be_a_tag result
      expect(result['name']).to eq tag_name
    end

    it 'finds tag records in case insensitive' do
      tag_name = "MATCH"
      Fabricate(:tag, name: tag_name)
      Fabricate(:tag, name: "miss")

      serialized_result = Tag.search_for("match", 10, 0)

      result = JSON.parse(serialized_result).first
      expect_to_be_a_tag result
      expect(result['name']).to eq tag_name
    end

    it 'finds the exact matching tag as the first item' do
      similar_tag = Fabricate(:tag, name: "matchlater", reviewed_at: Time.now.utc)
      tag = Fabricate(:tag, name: "match", reviewed_at: Time.now.utc)

      serialized_result = Tag.search_for("match", 10, 0)

      result1, result2 = JSON.parse(serialized_result)
      expect_to_be_a_tag result1
      expect_to_be_a_tag result2
      expect(result1['name']).to eq tag.name
      expect(result2['name']).to eq similar_tag.name
    end
  end

  describe '.history' do
    it 'should return the tag history from 1 to 6 days ago' do
      tag = Fabricate(:tag, name: 'Tag')
      account = Fabricate(:account)
      key = "activity:tags:#{tag.id}:#{1.day.ago.beginning_of_day.to_i}"
      accounts_key = "activity:tags:#{tag.id}:#{1.day.ago.beginning_of_day.to_i}:accounts"
      Redis.current.incrby(key, 1)
      Redis.current.pfadd(accounts_key, account.id)

      response = tag.history
      first_response = response.first
      last_response = response.last

      expect(response.length).to eq(6)
      expect(first_response[:day].to_i).to eq(1.day.ago.beginning_of_day.to_i)
      expect(first_response[:uses].to_i).to eq(1)
      expect(first_response[:accounts].to_i).to eq(1)
      expect(last_response[:day].to_i).to eq(6.days.ago.beginning_of_day.to_i)
      expect(last_response[:uses].to_i).to eq(0)
      expect(last_response[:accounts].to_i).to eq(0)
    end
  end
end
