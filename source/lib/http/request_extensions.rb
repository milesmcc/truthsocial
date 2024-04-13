# frozen_string_literal: true

module HTTP
  module RequestExtensions
    def proxy_connect_headers
      headers = super
      headers[Headers::HOST] = "#{headers[Headers::HOST]}:#{port}"
      headers
    end
  end
end

HTTP::Request.prepend(HTTP::RequestExtensions)