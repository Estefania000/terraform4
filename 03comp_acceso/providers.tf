terraform {
  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 5.0"
    }
  }
}

provider "azurerm" {
    features {}
    subscription_id = "925c40b9-52f2-45d4-8294-d0f9407bc767"
}