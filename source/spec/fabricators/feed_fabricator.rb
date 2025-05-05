Fabricator(:feed, from: 'Feeds::Feed') do
  name
  description nil
  visibility 'private'
  account
  created_at nil
end
