terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.70" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
    tls    = { source = "hashicorp/tls", version = "~> 4.0" }
  }

  backend "s3" {
    bucket       = "sf-tfstate-staging"
    key          = "eks-infra/staging/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "staging"
      ManagedBy   = "terraform"
      Repository  = "eks-infra"
    }
  }
}
