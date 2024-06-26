variable "env" {
  default     = "name"                  ### Should be changed, bucket name will be made using this variabele
  description = "Name of the environment"
}

variable "app_name" {
  default = "mlflow-terraform"          ### Should be changed to fit your needs, bucket name will be made using this variabele
}

variable "cidr" {
  default     = "10.0.0.0/25"
  description = "Cidr block of vpc"
}

variable "private_cidr_a" {
  default = "10.0.0.0/28"
}

variable "private_cidr_b" {
  default = "10.0.0.16/28"
}

variable "db_cidr_a" {
  default = "10.0.0.32/28"
}

variable "db_cidr_b" {
  default = "10.0.0.48/28"
}

variable "public_cidr_a" {
  default = "10.0.0.96/28"
}

variable "public_cidr_b" {
  default = "10.0.0.112/28"
}

variable "your_vpn" {
  default = "0.0.0.0/0"
  description = "Change this variable to your VPN. If you leave 0.0.0.0/0 your application will be accessible from any IP."
}


variable "region" {
  default = "eu-west-1"
}

variable "zone_a" {
  default = "eu-west-1a"
}

variable "zone_b" {
  default = "eu-west-1b"
}

variable "internet_cidr" {
  default     = "0.0.0.0/0"
  description = "Cidr block for the internet"
}

variable "ecs_service_name" {
  default = "mlflow-test"       ### Change this if you want.
}

variable "ecs_task_name" {
  default = "mlflow-test"       ### Change this if you want.
}
