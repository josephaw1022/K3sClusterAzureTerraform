# Include all necessary files
terraform {
  required_version = ">= 0.12"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}
