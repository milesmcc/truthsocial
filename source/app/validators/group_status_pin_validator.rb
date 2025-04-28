# frozen_string_literal: true

class GroupStatusPinValidator < ActiveModel::Validator
  def validate(pin)
    pin.errors.add(:base, I18n.t('statuses.pin_errors.reblog')) if pin.status.reblog?
    pin.errors.add(:base, I18n.t('statuses.pin_errors.group_ownership')) unless pin.status.group.owner_account == Current.account
    pin.errors.add(:base, I18n.t('statuses.pin_errors.limit')) if group_pins(pin).count > 1
  end

  def group_pins(pin)
    StatusPin
      .joins(:status)
      .joins('join groups on statuses.group_id = groups.id')
      .where(groups: { id: pin.status.group_id })
  end
end
