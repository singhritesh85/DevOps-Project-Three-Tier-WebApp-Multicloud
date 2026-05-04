provider "aws" {
  region = var.region
}

provider "google" {
  project = var.project_name ### Provide Project ID for your GCP Account
  billing_project = var.project_name ### Provide Project ID for your GCP Account
  user_project_override = true
  region  = "us-central1"    ###var.gcp_region[1]
}

provider "azurerm" {
  subscription_id = "5XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  tenant_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = true    ### All the Resources within the Resource Group must be deleted before deleting the Resource Group.
    }

    virtual_machine {
      delete_os_disk_on_deletion = true
    }

    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = false
    }
  }
}
