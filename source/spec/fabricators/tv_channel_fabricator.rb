Fabricator(:tv_channel) do
  channel_id { Faker::Number.number(digits: 3) }
  name { Faker::Name.name }
  image_url '/test.jpg'
  pltv_timespan 0
  enabled false
end
