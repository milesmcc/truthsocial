Fabricator(:user) do
  account
  email        { sequence(:email) { |i| "#{i}#{Faker::Internet.email}" } }
  password     "123456789"
  confirmed_at { Time.zone.now }
  agreement    true
  invite_id    { nil }
end
