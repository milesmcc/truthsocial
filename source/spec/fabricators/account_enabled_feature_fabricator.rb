Fabricator(:account_feature, from: 'Configuration::AccountEnabledFeature') do
  account
  feature_flag
end
