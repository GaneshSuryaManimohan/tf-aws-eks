variable "project_name" {
  default = "expense"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "common_tags" {
  type = map(any)
  default = {
    Environment = "dev"
    Project     = "expense"
    CreatedBy   = "terraform"
  }
}

variable "sg_id" {
  type        = string
  description = "Security group ID for workstation"
  default     = "sg-0bbdd2b154434fbfd"
}

variable "public_subnet_ids" {
  type    = string
  default = "subnet-00d8b90d93d5ad88f"
}