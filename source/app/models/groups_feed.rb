class GroupsFeed < Feed
  def initialize(account)
    @account = account
    super(:group, account)
  end

end
