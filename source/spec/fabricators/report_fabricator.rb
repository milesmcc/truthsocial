Fabricator(:report) do
  account
  target_account { Fabricate(:account) }
  comment        "You nasty"
  action_taken   false
  rule_ids       []
end
