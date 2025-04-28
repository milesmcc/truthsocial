Fabricator(:tag) do
  name { sequence(:hashtag) { |i| "#{Faker::Lorem.word}#{i}" } }
  trendable true
  listable true
end
