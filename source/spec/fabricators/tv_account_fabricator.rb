Fabricator(:tv_account) do
  account
  account_uuid { Faker::Internet.uuid }
  p_profile_id { Faker::Number.number(digits: 10) }
end
