# frozen_string_literal: true

require 'aws-sdk-s3'

module Seahorse
  module SeahorseExtensions
    def http_proxy_parts
      proxy_parts = super
      proxy_parts[0] = false if proxy_parts[0].nil?
      proxy_parts
    end
  end
end

Seahorse::Client::NetHttp::ConnectionPool.prepend(Seahorse::SeahorseExtensions)
