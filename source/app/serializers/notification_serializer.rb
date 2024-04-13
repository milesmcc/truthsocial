# frozen_string_literal: true

class NotificationSerializer < ActiveModel::Serializer
  include RoutingHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper

  def mailer_params
    name = "@#{object.from_account.username}"
    params = { name: name }
    if object.count.to_i > 1
      params[:count_others] = object.count - 1
      params[:actor] = 'other'
      params[:actor] += 's' if object.count.to_i > 2
    end

    group_types = [:group_delete, :group_approval, :group_promoted, :group_demoted]

    if group_types.include? object.type
      params[:group] = Group.find_by(id: object.activity_id)&.display_name
    end

    if object.type == :group_request
      params[:group] = GroupMembershipRequest.find_by(id: object.activity_id)&.group&.display_name
    end

    if object.type == :group_favourite
      params[:group] = Favourite.find_by(id: object.activity_id)&.status&.group&.display_name
    end

    if object.type == :group_reblog
      params[:group] = Status.find_by(id: object.activity_id)&.group&.display_name
    end

    if object.type == :group_mention
      params[:group] = Mention.find_by(id: object.activity_id)&.status&.group&.display_name
    end

    params
  end

  def template
    if object.count.to_i > 1
      "#{object_type}_group"
    else
      object_type
    end
  end

  def object_type
    object.type.to_s.gsub '_group', ''
  end
end
