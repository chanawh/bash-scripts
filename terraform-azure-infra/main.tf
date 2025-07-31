module "network" {
  source              = "./modules/network"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = "vnet-prod"
  vnet_address_space  = ["10.0.0.0/16"]
  subnet_name         = "subnet1"
  subnet_prefix       = "10.0.1.0/24"
  nsg_name            = "nsg-prod"
}
