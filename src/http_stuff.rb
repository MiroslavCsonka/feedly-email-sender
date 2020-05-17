# frozen_string_literal: true

require 'net/http'

# TODO: Replace with some nicer library (what does AWS Lambda support / how to get custom gems?)

class HttpStuff
  class << self
    def get(url, headers = {})
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Get.new(uri.request_uri)
      headers.each do |(key, value)|
        request[key] = value
      end

      http.request(request)
    end

    def delete(url, headers = {})
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Delete.new(uri.request_uri)
      headers.each do |(key, value)|
        request[key] = value
      end

      http.request(request)
    end
  end
end
