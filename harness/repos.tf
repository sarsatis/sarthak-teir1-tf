locals {
  repo_files = flatten([
    for repo in var.repositories : [
      for file in(
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
        org_identifier     = repo.orgIdentifier
        project_identifier = repo.projectIdentifier
        repo_name          = repo.repo_name
        file               = file.file
        template           = file.template
        filename           = file.filename
      }
    ]
  ])
}

resource "time_sleep" "wait_for_repo_creation" {
  depends_on = [
    github_repository_file.repo_files
  ]
  create_duration = "15s"
}

resource "github_repository" "new_repo" {
  for_each = { for repo in var.repositories : "${repo.orgIdentifier}-${repo.projectIdentifier}-${repo.repo_name}" => repo }

  name        = each.value.repo_name
  description = var.repo_description

  template {
    owner      = var.github_owner
    repository = var.template_repo_name
  }

}


resource "github_repository_file" "repo_files" {
  for_each = {
    for file in local.repo_files :
    "${file.org_identifier}-${file.project_identifier}-${file.repo_name}-${file.filename}" => file
  }

  repository     = github_repository.new_repo["${each.value.org_identifier}-${each.value.project_identifier}-${each.value.repo_name}"].name
  branch         = "master"
  file           = each.value.file
  content        = templatefile(each.value.template, { repo_name = each.value.repo_name, project_identifier = each.value.project_identifier, org_identifier = each.value.org_identifier })
  commit_message = "Add ${each.value.filename} related files to the .harness folder for ${each.value.repo_name}"

  depends_on = [github_repository.new_repo]
}

resource "harness_platform_pipeline" "pipeline" {
  for_each = {
    for repo in var.repositories :
    "${repo.orgIdentifier}-${repo.projectIdentifier}-${repo.repo_name}" => repo
  }
  depends_on = [github_repository_file.repo_files, time_sleep.wait_for_repo_creation]

  identifier      = each.value.repo_name
  org_id          = each.value.orgIdentifier
  project_id      = each.value.projectIdentifier
  name            = each.value.repo_name
  import_from_git = true

  git_import_info {
    branch_name   = "master"
    file_path     = ".harness/pipeline.yaml"
    connector_ref = "account.Github_OAuth_1719255138258"
    repo_name     = "${var.github_owner}/${each.value.repo_name}"
  }

  pipeline_import_request {
    pipeline_name        = each.value.repo_name
    pipeline_description = "This pipeline is auto-created for ${each.value.repo_name}."
  }
}

# resource "harness_platform_service" "service" {
#   for_each = {
#     for repo in var.repositories :
#     "${repo.orgIdentifier}-${repo.projectIdentifier}-${repo.repo_name}" => repo
#   }

#   depends_on = [github_repository_file.repo_files]

#   name        = each.value.repo_name
#   identifier  = each.value.repo_name
#   org_id      = each.value.orgIdentifier
#   project_id  = each.value.projectIdentifier

#   # Dynamically import YAML for each environment
#   yaml = templatefile("https://raw.githubusercontent.com/${var.github_owner}/${each.value.repo_name}/master/.harness/service-${each.value.repo_name}-${each.value.environment}.yaml", {
#     repo_name     = each.value.repo_name
#     org_identifier = each.value.orgIdentifier
#     project_identifier = each.value.projectIdentifier
#     environment   = each.value.environment
#   })
# }



output "repository_urls" {
  value = [
    for repo in var.repositories :
    "https://github.com/${var.github_owner}/${repo.repo_name}"
  ]
}
