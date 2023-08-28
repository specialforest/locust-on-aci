resource "azurerm_storage_account" "storage" {
  name                     = random_pet.deployment.id
  location                 = azurerm_resource_group.deployment.location
  resource_group_name      = azurerm_resource_group.deployment.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.default_tags
}

resource "azurerm_storage_share" "locust" {
  name                 = "locust"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 50
}

resource "azurerm_storage_share_file" "locustfile" {
  name             = "locustfile.py"
  storage_share_id = azurerm_storage_share.locust.id
  source           = "../locustfile.py"
  content_type     = "text/plain"
}

resource "azurerm_storage_share_file" "init" {
  name             = "init.sh"
  storage_share_id = azurerm_storage_share.locust.id
  source           = "./init.sh"
  content_type     = "text/plain"
}

resource "azurerm_storage_container" "docker" {
  name                  = "docker"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "dockerfile" {
  name                   = "Dockerfile"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.docker.name
  type                   = "Block"
  content_type           = "text/plain"
  source                 = "./Dockerfile"
}
