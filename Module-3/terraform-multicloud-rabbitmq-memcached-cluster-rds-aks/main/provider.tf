provider "aws" {
  region = var.region
}

provider "google" {
  project = var.project_name ### Provide Project ID for your GCP Account
  region  = "us-central1"    ###var.gcp_region[1]
}

provider "azurerm" {
  subscription_id = "51283936-af44-49c6-9a24-f1cbdc17915d"
  tenant_id = "8a0fce19-3824-4678-8769-b6c8e37a33ff"
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
