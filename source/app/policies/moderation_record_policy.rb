# frozen_string_literal: true
class ModerationRecordPolicy < ApplicationPolicy
  def index?
    staff?
  end
end
