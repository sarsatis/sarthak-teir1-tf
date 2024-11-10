# modules/github-repository-template/variables.tf

variable "github_token" {
  description = "Name of the new repository"
  type        = string
  default     = ""
}

variable "github_owner" {
  description = "Name of the new repository"
  type        = string
  default     = "sarsatis"
}

variable "repo_description" {
  description = "Description of the new repository"
  type        = string
  default     = "Created from a template repository"
}

variable "repo_private" {
  description = "Whether the repository is private or public"
  type        = bool
  default     = false
}

variable "template_repo_name" {
  description = "The name of the template repository"
  type        = string
  default     = "generic-repo-template"
}

variable "repositories" {
  description = "List of repositories to create, including name and type"
  type = list(object({
    repo_name = string
    repo_type = string  # e.g., "microservice" or "library"
  }))
  
  # Default value for the repositories variable
  default = [
    {
      repo_name = "sarthak-microservice"
      repo_type = "microservice"
    },
    {
      repo_name = "sarthak-library"
      repo_type = "library"
    }
  ]
}
