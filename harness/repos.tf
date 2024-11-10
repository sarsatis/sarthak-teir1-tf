# Create repositories based on the list of repositories
resource "github_repository" "new_repo" {
  for_each = { for repo in var.repositories : repo.repo_name => repo }

  name        = each.value.repo_name
  description = var.repo_description

  template {
    owner      = var.github_owner
    repository = var.template_repo_name
  }
}

# Local variable to handle repo types and files
locals {
  repo_files = flatten([
    for repo in var.repositories : [
      for file in (
        repo.repo_type == "microservice" ? [
          {
            file     = ".harness/pipeline.yaml"
            template = "${path.module}/microservices/pipeline.yaml"
            filename = "pipeline.yaml"
          },
          {
            file     = ".harness/service-dev"
            template = "${path.module}/microservices/service-dev.yaml"
            filename = "service-dev.yaml"
          },
          {
            file     = ".harness/service-int"
            template = "${path.module}/microservices/service-int.yaml"
            filename = "service-int.yaml"
          }
        ] : [
          {
            file     = ".harness/pipeline.yaml"
            template = "${path.module}/library/pipeline.yaml"
            filename = "pipeline.yaml"
          }
        ]
      ) : {
        repo_name = repo.repo_name
        file      = file.file
        template  = file.template
        filename  = file.filename
      }
    ]
  ])
}

# Create and commit each file to the new repository inside the .harness folder
resource "github_repository_file" "repo_files" {
  for_each = { for file in local.repo_files : "${file.repo_name}-${file.filename}" => file }

  repository    = github_repository.new_repo[each.value.repo_name].name
  branch        = "master"  # Assuming "main" is the default branch
  file          = each.value.file
  content       = templatefile(each.value.template, { repo_name = each.value.repo_name })
  commit_message = "Add ${each.value.filename} related files to the .harness folder"

  depends_on = [github_repository.new_repo]
}

output "repository_urls" {
  value = [for repo in var.repositories : "https://github.com/${var.github_owner}/${repo.repo_name}"]
}
