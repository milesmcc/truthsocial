# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def reset_password?
    staff? && !record.staff?
  end

  def change_email?
    staff? && !record.staff?
  end

  def disable_2fa?
    admin? && !record.staff?
  end

  def confirm?
    staff? && !record.confirmed?
  end

  def enable?
    staff?
  end

  def update?
    admin?
  end

  def approve?
    staff? && !record.approved?
  end

  def reject?
    staff? && !record.approved?
  end

  def disable?
    staff? && !record.admin?
  end

  def ban?
    admin? && !record.admin?
  end

  def promote?
    admin? && promoteable?
  end

  def demote?
    admin? && !record.admin? && demoteable?
  end

  def enable_sms_reverification?
    admin?
  end

  def disable_sms_reverification?
    admin?
  end


  def enable_feature?
    admin?
  end


  private

  def promoteable?
    record.approved? && (!record.staff? || !record.admin?)
  end

  def demoteable?
    record.staff?
  end
end
