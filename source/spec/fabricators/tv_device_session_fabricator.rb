Fabricator(:tv_device_session) do
  doorkeeper_access_token
  tv_session_id { Faker::Number.number(digits: 10) }
end
