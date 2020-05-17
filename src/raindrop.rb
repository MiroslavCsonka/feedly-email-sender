# frozen_string_literal: true

require_relative './http_stuff'

class Raindrop
  attr_reader :token

  def initialize(token)
    @token = token
  end

  def items
    HttpStuff.get('https://api.raindrop.io/rest/v1/raindrops/-1', auth_headers)
  end

  def delete(item)
    HttpStuff.delete("https://api.raindrop.io/rest/v1/raindrop/#{item.fetch('_id')}", auth_headers)
  end

  private

  def auth_headers
    { 'Authorization' => "Bearer #{token}" }
  end
end
