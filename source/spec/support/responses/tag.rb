def expect_to_be_a_tag(result)
  expect(result['url']).to be_an_instance_of String
  expect(result['name']).to be_an_instance_of String
  history = result['history'].first
  expect(history['day']).to be_an_instance_of String
  expect(history['uses']).to be_an_instance_of String
  expect(history['accounts']).to be_an_instance_of String
  expect(history['days_ago']).to be_an_instance_of Integer
end

def expect_to_be_a_group_tag(result)
  expect(result[:id]).to be_an_instance_of String
  expect(result[:name]).to be_an_instance_of String
end
