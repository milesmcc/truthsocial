# frozen_string_literal: true

class REST::RuleSerializer < ActiveModel::Serializer
  attributes :id, :text, :subtext, :rule_type

  def id
    object.id.to_s
  end

  def rule_type
    object.rule_type == "rule_type_group" ? :group : object.rule_type
  end

  def text
    I18n.t("admin.instances.rules.#{object.name}.text")
  end

  def subtext
    I18n.t("admin.instances.rules.#{object.name}.subtext")
  end
end
