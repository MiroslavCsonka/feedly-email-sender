# frozen_string_literal: true

require 'json'
require_relative './feedly'
require_relative './raindrop'
require_relative './send-email'

FROM_EMAIL = 'miroslavcsonka@miroslavcsonka.com'
TO_EMAIl = 'miroslavcsonka@miroslavcsonka.com'
SERVICE_TO_RUN = ENV.fetch('SERVICE')

def run_feedly
  feedly_client = Feedly.new(
    ENV.fetch('FEEDLY_AUTH_TOKEN'),
    ENV.fetch('SAVED_LATER_STREAM_ID')
  )
  response = feedly_client.items

  output = {
    get_stream: { code: response.code, body: JSON.parse(response.body) }
  }

  unless response.code == '200'
    return format_response(response.code.to_i, "Getting items failed with #{response.code} and body #{response.body}")
  end

  item = JSON.parse(response.body).fetch('items')[0]

  return format_response(400, 'No more items to serve') unless item

  output[:item] = item
  title, url = item.values_at('title', 'canonicalUrl')

  email_sent = send_email(
    from: FROM_EMAIL,
    to: TO_EMAIl,
    subject: "Read: #{title}",
    body: url
  )
  output[:email_sending] = email_sent

  return format_response(400, output) unless email_sent

  if email_sent
    delete_tag_response = feedly_client.delete(item)
    output[:delete_tag_response] = { code: delete_tag_response.code, body: delete_tag_response.body }
  end

  format_response(200, { response: output })
end

def run_raindrop
  raindrop_client = Raindrop.new(ENV.fetch('RAINDROP_AUTH_TOKEN'))
  response = raindrop_client.items

  output = {
    get_stream: { code: response.code, body: JSON.parse(response.body) }
  }

  unless response.code == '200'
    return format_response(response.code.to_i, "Getting items failed with #{response.code} and body #{response.body}")
  end

  item = JSON.parse(response.body).fetch('items')[0]

  return format_response(400, 'No more items to serve') unless item

  output[:item] = item
  title, url = item.values_at('title', 'link')

  email_sent = send_email(
    from: FROM_EMAIL,
    to: TO_EMAIl,
    subject: "Read: #{title}",
    body: url
  )
  output[:email_sending] = email_sent

  return format_response(400, output) unless email_sent

  if email_sent
    delete_tag_response = raindrop_client.delete(item)
    output[:delete_tag_response] = { code: delete_tag_response.code, body: delete_tag_response.body }
  end

  format_response(200, { response: output })
end

def lambda_handler(event:, context:)
  if SERVICE_TO_RUN == 'feedly'
    run_feedly
  elsif SERVICE_TO_RUN == 'raindrop'
    run_raindrop
  else
    format_response(400, { error: "Unknown service #{SERVICE_TO_RUN}" })
  end
end

def format_response(code, body)
  { statusCode: code, body: JSON.generate(body) }
end
