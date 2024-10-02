class REST::Admin::TagSearchSerializer < Panko::Serializer
  attributes :id, :name, :trendable, :listable
end
