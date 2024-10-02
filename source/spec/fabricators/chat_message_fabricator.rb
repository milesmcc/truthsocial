Fabricator(:chat_message) do
  content Faker::Lorem.characters(number: 15)
end
