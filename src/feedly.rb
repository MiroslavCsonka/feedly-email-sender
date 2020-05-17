# frozen_string_literal: true

require_relative './http_stuff'
require 'cgi'

class Feedly
  attr_reader :token, :saved_later_stream_id

  def initialize(token, saved_later_stream_id)
    @token = token
    @saved_later_stream_id = saved_later_stream_id
  end

  def items
    HttpStuff.get(
      "https://feedly.com/v3/streams/contents?streamId=#{CGI.escape(saved_later_stream_id)}&count=2&unreadOnly=true&ranked=oldest&similar=true&findUrlDuplicates=true&ck=1589021002505&ct=feedly.desktop&cv=31.0.705",
      { 'Authorization' => "OAuth #{token}" }
    )
  end

  def delete(item)
    tagid = item.fetch('tags').find { |tag| tag.fetch('label') == 'Saved For Later' }.fetch('id')
    HttpStuff.delete(
      "https://feedly.com/v3/tags/#{CGI.escape(tagid)}/#{CGI.escape(item.fetch('id'))}",
      { 'Authorization' => "OAuth #{token}" }
    )
  end
end
