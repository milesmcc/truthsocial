def expect_to_be_an_admin_account(payload)
  expect(payload[:id]).to be_an_instance_of String
  expect(payload[:username]).to be_an_instance_of String
  expect(payload[:domain]).to be_an_instance_of(String).or eq nil
  expect(payload[:created_at]).to be_an_instance_of String
  expect(payload[:deleted]).to be_boolean
  expect(payload[:email]).to be_an_instance_of String
  expect(payload[:ip]).to be_an_instance_of(String).or eq nil
  expect(payload[:role]).to be_an_instance_of String
  expect(payload[:confirmed]).to be_boolean
  expect(payload[:suspended]).to be_boolean
  expect(payload[:silenced]).to be_boolean
  expect(payload[:disabled]).to be_boolean
  expect(payload[:approved]).to be_boolean
  expect(payload[:locale]).to be_an_instance_of(String).or eq nil
  expect(payload[:invite_request]).to be_an_instance_of(String).or eq nil
  expect(payload[:verified]).to be_boolean
  expect(payload[:location]).to be_an_instance_of String
  expect(payload[:website]).to be_an_instance_of String
  expect(payload[:sms]).to be_an_instance_of(String).or eq nil
  expect(payload[:sms_reverification_required]).to be_boolean
  expect(payload[:updated_at]).to be_an_instance_of String
  expect(payload[:advertiser]).to be_boolean
  expect(payload[:created_by_application_id]).to be_an_instance_of(String).or eq nil
  expect(payload[:invited_by_account_id]).to be_an_instance_of(String).or eq nil
  expect(payload[:account]).to be_an_instance_of Hash
end
