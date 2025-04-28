# frozen_string_literal: true

class REST::V2::TvChannelGuideSerializer < Panko::Serializer
  attributes :tv, :status_id, :reminder_set

  def tv
    REST::V2::TvProgramSerializer.new.serialize(object)
  end

  def status_id
    object&.tv_program_status&.status_id&.to_s
  end

  def reminder_set
    return false unless context && context[:reminders]
    context[:reminders].any? { |r| r[:channel_id] == object.channel_id && (r[:start_time]) == object.start_time.to_i * 1000 }
  end
end
