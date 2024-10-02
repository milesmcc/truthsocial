# frozen_string_literal: true

class REST::V2::Account::FieldSerializer < Panko::Serializer
  attributes :name, :value, :verified_at

  def value
    Formatter.instance.format_field(object.account, object.value)
  end
end
