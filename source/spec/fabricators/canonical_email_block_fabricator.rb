Fabricator(:canonical_email_block) do
  email "test@example.com"
  reference_account { Fabricate(:account) }
end
