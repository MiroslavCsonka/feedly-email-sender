# frozen_string_literal: true

require 'aws-sdk'

def send_email(from:, to:, subject:, body:)
  ses = Aws::SES::Client.new(region: 'eu-west-2')

  begin
    ses.send_email({
                     destination: {
                       to_addresses: [
                         to
                       ]
                     },
                     message: {
                       body: {
                         html: {
                           charset: 'UTF-8',
                           data: body
                         },
                         text: {
                           charset: 'UTF-8',
                           data: body
                         }
                       },
                       subject: {
                         charset: 'UTF-8',
                         data: subject
                       }
                     },
                     source: from
                   })
  rescue Aws::SES::Errors::ServiceError => e
    puts "Email not sent. Error message: #{e}"
    nil
  end
end
