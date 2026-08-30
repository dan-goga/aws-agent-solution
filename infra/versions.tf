terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # Local state on purpose: this project runs against ephemeral Pluralsight
  # cloud sandboxes (~4h sessions) where nothing persists between sessions,
  # so a remote backend would just be state pointing at infrastructure that
  # no longer exists.
}
