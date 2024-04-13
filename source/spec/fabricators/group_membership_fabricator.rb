Fabricator(:group_membership) do
  group
  account
  role :user
end
