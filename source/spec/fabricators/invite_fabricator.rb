Fabricator(:invite) do
  user
  expires_at nil
  max_uses   nil
  uses       0
  email      "test@testmail.com"
  users      count: 1
end
