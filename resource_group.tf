provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "MyResourceGroup"
  location = "East US"
}

