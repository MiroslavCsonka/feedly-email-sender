## Problem introduction

Feedly is great for collecting a lot of articles through RSS. My workflow is to go through the list, save the ones I like and read those later. The problem is that I forget to read them I'm actually pretty good at cleaning my email to get to inbox zero. So this serverless utility does following:

1. Gets the oldest saved articles from Feedly
2. Removes it from "Saved for later"
3. Emails a link to that article 

Set up:
- verify you can send emails with AWS SES
- Configure `TF_VAR_saved_later_stream_id`, `TF_VAR_feedly_auth_token`, and [`TF_VAR_raindrop_auth_token`](https://app.raindrop.io/#/settings/apps/dev) in your local env
- Change emails in `main.tf`
- run `terraform init`
- run `terraform apply` to provision the AWS Lambda, AWS Cloudwatch scheduled event, roles, and policies