# frozen_string_literal: true

require 'json'
require 'net/http'
require 'cgi'
require_relative './send-email'

def lambda_handler(event:, context:)
  feedly_url = "https://feedly.com/v3/streams/contents?streamId=#{CGI.escape(ENV.fetch('SAVED_LATER_STREAM_ID'))}&count=2&unreadOnly=true&ranked=oldest&similar=true&findUrlDuplicates=true&ck=1589021002505&ct=feedly.desktop&cv=31.0.705"

  uri = URI.parse(feedly_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  request = Net::HTTP::Get.new(uri.request_uri)
  request['Authorization'] = "OAuth #{ENV.fetch('FEEDLY_AUTH_TOKEN')}"

  response = http.request(request)

  output = {
    get_stream: { code: response.code, body: JSON.parse(response.body) }
  }

  item = JSON.parse(response.body).fetch('items')[0]
  output[:item] = item
  id, title, url = item.values_at('id', 'title', 'canonicalUrl')

  tagid = item.fetch('tags').find { |tag| tag.fetch('label') == 'Saved For Later' }.fetch('id')
  uri = URI.parse("https://feedly.com/v3/tags/#{CGI.escape(tagid)}/#{CGI.escape(id)}")
  delete_request = Net::HTTP::Delete.new(uri.request_uri)
  delete_request['Authorization'] = "OAuth #{ENV.fetch('FEEDLY_AUTH_TOKEN')}"

  delete_tag_response = http.request(delete_request)
  output[:delete_tag_response] = { code: delete_tag_response.code, body: delete_tag_response.body }

  sender = 'miroslavcsonka@miroslavcsonka.com'
  recipient = 'miroslavcsonka@miroslavcsonka.com'
  subject = "Read: #{title}"

  puts output

  result = send_email(from: sender, to: recipient, subject: subject, body: url)
  output[:email_sending] = result

  { statusCode: 200, body: JSON.generate({ event: event, context: context, response: output }) }
end
