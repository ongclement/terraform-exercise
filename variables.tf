variable "PUBLIC_KEY_PATH" {
  default = "keys/ec2-key.pub"
}

variable "PRIVATE_KEY_PATH" {
  default = "keys/ec2-pvt-key.pem"
}

variable "USER" {
  default = "ec2-user"
}

variable "ACCESS_KEY" {
  description = "The username for the DB master user"
  type        = string
}
variable "SECRET_KEY" {
  description = "The password for the DB master user"
  type        = string
}

variable "private_subnet" {
  type    = list(string)
  default = ["10.9.1.0/24", "10.9.2.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-southeast-1a","ap-southeast-1b"]
}