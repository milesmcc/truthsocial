Fabricator(:email_domain_block) do
  domain { sequence(:domain) { |i| "#{i}#{Faker::Internet.domain_name}" } }
  disposable false
end
