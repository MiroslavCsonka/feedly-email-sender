## Problem introduction

Feedly is great for collecting a lot of articles through RSS. My workflow is to go through the list, save the ones I like and read those later. The problem is that I forget to read them I'm actually pretty good at cleaning my email to get to inbox zero. So this serverless utility does following:

1. Gets the oldest saved articles from Feedly
2. Removes it from "Saved for later"
3. Emails a link to that article 



Set up:
- Create an AWS Lambda function with the code from this repo
- Verify you can send emails with AWS SES
- Allow the AWS Lambda to send email with AWS SES (by adding a new policy to the role)
- Configure `FEEDLY_AUTH_TOKEN` and `SAVED_LATER_STREAM_ID`
- Create an AWS Cloudwatch scheduled triggers to kick off the Lambda