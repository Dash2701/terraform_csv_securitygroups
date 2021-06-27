# provider.tf

# Specify the provider and access details
provider "aws" {
  profile  = "default"
  region  = "ap-south-1"
}



terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.39.0"
    }
  }

  required_version = ">= 0.13"
}
