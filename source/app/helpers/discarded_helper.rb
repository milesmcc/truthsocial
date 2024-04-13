# frozen_string_literal: true

module DiscardedHelper
  def attribute_or_discarded_value(attribute, alternative)
    object.discarded? ? alternative : attribute
  end
end
