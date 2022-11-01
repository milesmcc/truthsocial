class AccountSuspensionPolicy
  attr_reader :account

  MAXIMUM_SUSPENSIONS = 5
  private_constant :MAXIMUM_SUSPENSIONS

  def initialize(account)
    @account = account
  end

  def current_suspension_period
    case suspension_count
    when 1
      48.hours
    when 2
      96.hours
    when 3
      192.hours
    when 4
      384.hours
    when 5
      768.hours
    end
  end

  def next_unsuspension_date
    case suspension_count
    when 0
      48.hours.from_now
    when 1
      96.hours.from_now
    when 2
      192.hours.from_now
    when 3
      384.hours.from_now
    when 4
      768.hours.from_now
    end
  end

  def strikes_expended?
    suspension_count >= MAXIMUM_SUSPENSIONS
  end

  private

  def suspension_count
    @suspension_count ||= account.targeted_account_warnings.where(action: :suspend).count
  end
end
