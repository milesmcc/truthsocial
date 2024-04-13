Fabricator(:one_time_challenge) do
  challenge           "MyString"
  user                nil
  webauthn_credential nil
  object_type 'attestation'
end
