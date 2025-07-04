variable "fqdn" {
  type        = string
  default     = ""
  description = "The subdomain to generate a certificate for and host"
}

variable "bucket_name" {
  type        = string
  default     = ""
  description = "Override for the name of the S3 bucket containing site assets"
}

variable "force_destroy" {
  type = bool
  default = false
  description = "Used to empty and destroy the S3 bucket"
}

variable "api_gateway_origin_domain" {
  type        = string
  default     = ""
  description = "API Gateway origin domain for /api/* routing"
}

variable "api_gateway_origin_path" {
  type        = string
  default     = ""
  description = "API Gateway origin path prefix (e.g., /dev for stage)"
}
