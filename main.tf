variable "feedly_auth_token" {}
variable "saved_later_stream_id" {}
variable "raindrop_auth_token" {}

locals {
  from_email = "miroslavcsonka@miroslavcsonka.com"
  to_email = "miroslavcsonka@miroslavcsonka.com"
}

provider "aws" {
  region = "eu-west-2"
}

module "feedly-service" {
  source = "./modules/service"

  name = "feedly-sender"

  env = {
    FROM_EMAIL = local.from_email
    TO_EMAIL = local.to_email
    FEEDLY_AUTH_TOKEN = var.feedly_auth_token
    SAVED_LATER_STREAM_ID = var.saved_later_stream_id
    SERVICE = "feedly"
  }
}

module "raindrop-service" {
  source = "./modules/service"

  name = "raindrop-sender"

  env = {
    FROM_EMAIL = local.from_email
    TO_EMAIL = local.to_email
    RAINDROP_AUTH_TOKEN = var.raindrop_auth_token
    SERVICE = "raindrop"
  }

}

output "feedly-arn" {
  value = module.feedly-service.arn
}

output "raindrop-arn" {
  value = module.raindrop-service.arn
}