# frozen_string_literal: true

class CanonicalRequestService
  include AppAttestable

  attr_reader :request, :canonical_string

  def initialize(request)
    @request = request
  end

  def call
    verb = request.request_method
    path = request.path
    query = construct_canonical_query_string
    sorted_headers = canonical_headers.sort.to_h.compact
    header_keys = sorted_headers.keys.join(';')
    header_values = sorted_headers.map { |key, value| "#{key}:#{value}" }.join("\n")
    body = request.raw_post
    json_body = body.empty? ? '' : body
    hex_encoded_body = hexdigest(json_body.bytes.pack('c*'))
    hex_encoded_canonical_string = "#{verb}\n#{path}\n#{query}\n#{header_values}\n\n#{header_keys}\n#{hex_encoded_body}"
    @canonical_string = "#{verb}\n#{path}\n#{query}\n#{header_values}\n\n#{header_keys}\n#{json_body}"

    digest hex_encoded_canonical_string
  end

  def canonical_headers
    headers = {}
    headers['content-type'] = request.headers['Content-Type'] if request.headers['Content-Type']
    headers['host'] = Rails.configuration.x.web_domain
    headers['idempotency-key'] = request.headers['idempotency-key'] if request.headers['idempotency-key']
    request.headers.select { |header| header.to_s.include?('HTTP_X_TRU_') }.each do |key, value|
      next if key == 'HTTP_X_TRU_ASSERTION'

      formatted_key = key.split('HTTP_').last.downcase.gsub('_', '-')
      headers[formatted_key] = value
    end

    headers
  end

  private

  def construct_canonical_query_string
    original_url = request.original_url
    query_params = original_url.include?('?') ? original_url.split('?').last : nil
    return '' unless query_params

    sorted_params = query_params.split('&').sort
    params_hash = sorted_params.each_with_object({}.compare_by_identity) do |value, memo|
      key, value = value.split('=')
      memo[key] = CGI.unescape(value || '')
    end

    uri = Addressable::URI.parse(original_url)
    uri.query_values = params_hash
    uri.normalize.to_s.split('?').pop
  end
end
