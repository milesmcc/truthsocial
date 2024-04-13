Fabricator(:poll) do
  expires_at { 7.days.from_now }
  options(count: 2, fabricator: :poll_option)
  status
end

Fabricator(:poll_option) do
  option_number { Fabricate.sequence(:number, 0).odd? ? 1 : 0 }
  text { Faker::Alphanumeric.alphanumeric(number: 20) }
end
