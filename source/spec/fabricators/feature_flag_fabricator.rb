Fabricator(:feature_flag, from: 'Configuration::FeatureFlag') do
  name Faker::Lorem.word
  status %w(enabled disabled account_based).sample
end
