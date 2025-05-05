# == Schema Information
#
# Table name: group_tags
#
#  group_id       :bigint(8)        not null, primary key
#  tag_id         :bigint(8)        not null, primary key
#  group_tag_type :enum             default("pinned"), not null
#
class GroupTag < ApplicationRecord
  enum group_tag_type: { pinned: 'pinned', hidden: 'hidden' }
  validates :group_tag_type, inclusion: { in: group_tag_types.keys }

  belongs_to :tag
  belongs_to :group

  def group_tag_type=(value)
    super
  rescue ArgumentError
    @attributes.write_cast_value('group_tag_type', value)
  end
end
