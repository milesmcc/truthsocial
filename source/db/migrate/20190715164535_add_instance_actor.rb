class AddInstanceActor < ActiveRecord::Migration[5.2]
  def up
    account = Account.new(id: -99, actor_type: 'Application', locked: true, username: Rails.configuration.x.local_domain)
    account.save!(validate: false)
  end

  def down
    Account.find_by(id: -99, actor_type: 'Application').destroy!
  end
end
