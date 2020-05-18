variable "name" {
  description = "Name for the service"
}

variable "env" {
  description = "Define environment variables for this service"
  type = map(string)
  default = {}
}