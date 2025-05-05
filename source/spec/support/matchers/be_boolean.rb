RSpec::Matchers.define :be_boolean do
  match do |actual|
    expect(actual).to be_in([true, false])
  end
end
