def expect_to_be_a_feed(payload)
  expect(payload[:id]).to be_an_instance_of String
  expect(payload[:name]).to be_an_instance_of String
  expect(payload[:description]).to be_an_instance_of(String).or eq nil
  expect(payload[:visibility]).to be_an_instance_of String
  expect(payload[:feed_type]).to be_an_instance_of String
  expect(payload[:created_by_account_id]).to be_an_instance_of String
  expect(payload[:pinned]).to be_boolean.or eq nil
  expect(payload[:can_unpin]).to be_boolean
  expect(payload[:can_delete]).to be_boolean
  expect(payload[:can_sort]).to be_boolean
  expect(payload[:seen]).to be_boolean.or eq nil # Change once logic is implemented
  expect(payload[:created_at]).to be_an_instance_of String
end
