# frozen_string_literal: true

# == Schema Information
#
# Table name: configuration.banned_words
#
#  id   :integer          not null, primary key
#  word :text             not null
#
class BannedWord < ApplicationRecord
  self.table_name = 'configuration.banned_words'
  self.record_timestamps = false
end
