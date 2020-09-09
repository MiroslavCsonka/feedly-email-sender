# frozen_string_literal: true

require 'json'
require_relative './feedly'
require_relative './raindrop'
require_relative './send-email'

FROM_EMAIL = ENV.fetch('FROM_EMAIL')
TO_EMAIl = ENV.fetch('TO_EMAIL')
SERVICE_TO_RUN = ENV.fetch('SERVICE')

def run(client, link_field_name)
  items_response = client.items

  output = {
    get_stream: { code: items_response.code, body: JSON.parse(items_response.body) }
  }

  unless items_response.code == '200'
    return format_response(items_response.code.to_i, "Getting items failed with #{items_response.code} and body #{items_response.body}")
  end

  item = JSON.parse(items_response.body).fetch('items')[0]

  return format_response(400, 'No more items to serve') unless item

  output[:item] = item
  title, url = item.values_at('title', link_field_name)

  email_sent = send_email(
    from: FROM_EMAIL,
    to: TO_EMAIl,
    subject: "Read: #{title} (from #{client.class})",
    body: url
  )
  output[:email_sending] = email_sent

  return format_response(400, output) unless email_sent

  if email_sent
    delete_item_response = client.delete(item)
    output[:delete_tag_response] = { code: delete_item_response.code, body: delete_item_response.body }
  end

  format_response(200, { response: output })
end

def lambda_handler(event:, context:)
  if SERVICE_TO_RUN == 'feedly'
    feedly_client = Feedly.new(
      ENV.fetch('FEEDLY_AUTH_TOKEN'),
      ENV.fetch('SAVED_LATER_STREAM_ID')
    )
    run(feedly_client, 'canonicalUrl')
  elsif SERVICE_TO_RUN == 'raindrop'
    run(Raindrop.new(ENV.fetch('RAINDROP_AUTH_TOKEN')), 'link')
  else
    format_response(400, { error: "Unknown service #{SERVICE_TO_RUN}" })
  end
end

def format_response(code, body)
  { statusCode: code, body: JSON.generate(body) }
end
