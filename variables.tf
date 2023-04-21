variable "fqdn" {
  type        = string
  default     = ""
  description = "The fully qualified domain name to generate a certificate for"
}

variable "hosted_zone_id" {
  type        = string
  default     = ""
  description = "Route53 Hosted Zone ID"
}

variable "bucket_name" {
  type        = string
  default     = ""
  description = "Name for the S3 bucket containing the static site files, if unset, the bucket will use a UUID"
}

variable "force_destroy" {
  type = bool
  default = false
  description = "Used to empty and destroy the S3 bucket"
}
