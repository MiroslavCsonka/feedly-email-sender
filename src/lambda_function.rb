# frozen_string_literal: true

require 'json'
require 'net/http'
require 'cgi'
require_relative './send-email'

FEEDLY_AUTH_TOKEN = ENV.fetch('FEEDLY_AUTH_TOKEN')
SAVED_LATER_STREAM_ID = ENV.fetch('SAVED_LATER_STREAM_ID')
FROM_EMAIL = 'miroslavcsonka@miroslavcsonka.com'
TO_EMAIl = 'miroslavcsonka@miroslavcsonka.com'

# TODO: Replace with some nicer library (what does AWS Lambda support / how to get custom gems?)
def get_request(url)
  uri = URI.parse(url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  request = Net::HTTP::Get.new(uri.request_uri)
  request['Authorization'] = "OAuth #{FEEDLY_AUTH_TOKEN}"

  http.request(request)
end

def delete_request(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  delete_request = Net::HTTP::Delete.new(uri.request_uri)
  delete_request['Authorization'] = "OAuth #{FEEDLY_AUTH_TOKEN}"

  http.request(delete_request)
end

def lambda_handler(event:, context:)
  response = get_request(
    "https://feedly.com/v3/streams/contents?streamId=#{CGI.escape(SAVED_LATER_STREAM_ID)}&count=2&unreadOnly=true&ranked=oldest&similar=true&findUrlDuplicates=true&ck=1589021002505&ct=feedly.desktop&cv=31.0.705"
  )

  output = {
    get_stream: { code: response.code, body: JSON.parse(response.body) }
  }

  unless response.code == '200'
    return format_response(response.code.to_i, "Getting items failed with #{response.code} and body #{response.body}")
  end

  item = JSON.parse(response.body).fetch('items')[0]

  return format_response(400, 'No more items to serve') unless item

  output[:item] = item
  id, title, url = item.values_at('id', 'title', 'canonicalUrl')

  email_sent = send_email(
    from: FROM_EMAIL,
    to: TO_EMAIl,
    subject: "Read: #{title}",
    body: url
  )
  output[:email_sending] = email_sent

  return format_response(400, output) unless email_sent

  if email_sent
    tagid = item.fetch('tags').find { |tag| tag.fetch('label') == 'Saved For Later' }.fetch('id')
    delete_tag_response = delete_request(
      "https://feedly.com/v3/tags/#{CGI.escape(tagid)}/#{CGI.escape(id)}"
    )
    output[:delete_tag_response] = { code: delete_tag_response.code, body: delete_tag_response.body }
  end

  format_response(200, { event: event, context: context, response: output })
end

def format_response(code, body)
  { statusCode: code, body: JSON.generate(body) }
end
