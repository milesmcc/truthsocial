# frozen_string_literal: true

module Queriable
  extend ActiveSupport::Concern

  def execute_query(query, options)
    execute(query, options)
  end

  def execute_query_on_master(query, options)
    if Rails.env.production?
      connection.stick_to_master!(false)
    end

    execute(query, options)
  end

  private

  def execute(query, options)
    connection.exec_query(
      query,
      'SQL',
      options.map { |option| [nil, option] },
      prepare: true
    )
  end
end
