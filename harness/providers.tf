terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "6.3.1"
    }
  }
}


provider "github" {
  token = var.github_token
  owner = var.github_owner
}