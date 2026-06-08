terraform {
  backend "azurerm" {
    use_azuread_auth = true # This is required to access state files with only "Storage blob data contributor" role assined to the service principal in state storage account
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.75.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=3.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.9.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
