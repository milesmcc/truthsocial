def expect_to_be_a_group(payload)
  expect_to_be_a_basic_group(payload)
end

def expect_to_be_an_admin_group(payload)
  expect_to_be_a_basic_group(payload)
  expect(payload[:owner][:username]).to be_an_instance_of String
  expect(payload[:owner][:avatar]).to be_an_instance_of String
end

def expect_to_be_a_trending_group(payload)
  expect_to_be_a_basic_group(payload)
end

def expect_to_be_a_basic_group(payload)
  expect(payload[:id]).to be_an_instance_of String
  expect(payload[:discoverable]).to be_boolean
  expect(payload[:locked]).to be_boolean
  expect(payload[:avatar]).to be_an_instance_of String
  expect(payload[:avatar_static]).to be_an_instance_of String
  expect(payload[:header]).to be_an_instance_of String
  expect(payload[:header_static]).to be_an_instance_of String
  expect(payload[:group_visibility]).to be_an_instance_of String
  expect(payload[:created_at]).to be_an_instance_of String
  expect(payload[:display_name]).to be_an_instance_of String
  expect(payload[:note]).to be_an_instance_of String
  expect(payload[:membership_required]).to be_boolean
  expect(payload[:members_count]).to be_an_instance_of Integer
  expect(payload[:tags]).to be_an_instance_of Array
  expect(payload[:source]).to be_an_instance_of Hash
  expect(payload[:url]).to be_an_instance_of String
  expect(payload[:owner][:id]).to be_an_instance_of String
end
