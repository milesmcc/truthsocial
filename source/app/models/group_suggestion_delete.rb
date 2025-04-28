# frozen_string_literal: true
# == Schema Information
#
# Table name: group_suggestion_deletes
#
#  account_id :bigint(8)        not null, primary key
#  group_id   :bigint(8)        not null, primary key
#
class GroupSuggestionDelete < ApplicationRecord
  self.primary_keys = :account_id, :group_id
  belongs_to :account
  belongs_to :group
end
