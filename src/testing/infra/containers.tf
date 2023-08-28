resource "azurerm_container_registry" "registry" {
  count = var.use_acr ? 1 : 0
  name = random_pet.deployment.id
  resource_group_name = azurerm_resource_group.deployment.name
  location = azurerm_resource_group.deployment.location
  sku = "Standard"
  admin_enabled = true
}

resource "azurerm_container_group" "controller" {
  count               = var.locustWorkerNodes >= 1 ? 1 : 0
  name                = "${random_pet.deployment.id}-locust-controller"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name
  ip_address_type     = "Public"
  dns_name_label      = "${random_pet.deployment.id}-locust-controller"
  os_type             = "Linux"

  dynamic "image_registry_credential" {
    for_each = var.use_acr ? [1] : []
    content {
      server = azurerm_container_registry.registry[0].login_server
      username = azurerm_container_registry.registry[0].admin_username
      password = azurerm_container_registry.registry[0].admin_password
    }
  }

  init_container {
    name   = "${random_pet.deployment.id}-locust-controller-init"
    image  = "%{if var.use_acr}${azurerm_container_registry.registry[0].login_server}/%{endif}${var.locust_container_image}"

    commands = [
      "/home/locust/init/init.sh"
    ]

    volume {
      name       = "init"
      mount_path = "/home/locust/init"
      read_only = true
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
      storage_account_name = azurerm_storage_account.storage.name
      share_name           = azurerm_storage_share.locust.name
    }

    volume {
      name       = "secrets"
      mount_path = "/home/locust/secrets"
      read_only = true
      secret = {
        crt = base64encode(azurerm_key_vault_certificate.locustcert.certificate_data_base64)
        crt_secret = data.azurerm_key_vault_secret.locustcert.value
      }
    }

    volume {
      name       = "cert"
      mount_path = "/home/locust/cert"
      empty_dir = true
    }
  }

  container {
    name   = "${random_pet.deployment.id}-locust-controller"
    image  = "%{if var.use_acr}${azurerm_container_registry.registry[0].login_server}/%{endif}${var.locust_container_image}"
    cpu    = "2"
    memory = "2"

    commands = [
      "locust"
    ]

    environment_variables = {
      "LOCUST_LOCUSTFILE"              = "/home/locust/locust/${azurerm_storage_share_file.locustfile.name}"
      "LOCUST_HOST"                    = var.targeturl
      "LOCUST_MODE_MASTER"             = "true"
      "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.deployment.connection_string
      "LOCUST_TLS_CERT" = "/home/locust/cert/locust.crt"
      "LOCUST_TLS_KEY" = "/home/locust/cert/locust.pem"
    }

    secure_environment_variables = {
      "LOCUST_WEB_AUTH" = "locust:${azurerm_key_vault_secret.locustsecret.value}"
    }

    volume {
      name       = "cert"
      mount_path = "/home/locust/cert"
      empty_dir = true
    }

    volume {
      name       = "locust"
      mount_path = "/home/locust/locust"
      read_only = true
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
      storage_account_name = azurerm_storage_account.storage.name
      share_name           = azurerm_storage_share.locust.name
    }

    ports {
      port     = "8089"
      protocol = "TCP"
    }

    ports {
      port     = "5557"
      protocol = "TCP"
    }

  }

  tags = local.default_tags
}

resource "azurerm_container_group" "worker" {
  count               = var.locustWorkerNodes
  name                = "${random_pet.deployment.id}-locust-worker-${count.index}"
  location            = var.locustWorkerLocations[count.index % length(var.locustWorkerLocations)]
  resource_group_name = azurerm_resource_group.deployment.name
  ip_address_type     = "Public"
  os_type             = "Linux"

  dynamic "image_registry_credential" {
    for_each = var.use_acr ? [1] : []
    content {
      server = azurerm_container_registry.registry[0].login_server
      username = azurerm_container_registry.registry[0].admin_username
      password = azurerm_container_registry.registry[0].admin_password
    }
  }

  container {
    name   = "${random_pet.deployment.id}-worker-${count.index}"
    image  = "%{if var.use_acr}${azurerm_container_registry.registry[0].login_server}/%{endif}${var.locust_container_image}"
    cpu    = "2"
    memory = "2"

    commands = [
      "locust"
    ]

    environment_variables = {
      "LOCUST_LOCUSTFILE"              = "/home/locust/locust/${azurerm_storage_share_file.locustfile.name}",
      "LOCUST_MASTER_NODE_HOST"        = azurerm_container_group.controller[0].fqdn,
      "LOCUST_MODE_WORKER"             = "true"
      "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.deployment.connection_string
    }

    volume {
      name       = "locust"
      mount_path = "/home/locust/locust"

      storage_account_key  = azurerm_storage_account.storage.primary_access_key
      storage_account_name = azurerm_storage_account.storage.name
      share_name           = azurerm_storage_share.locust.name
    }

    ports {
      port     = 8089
      protocol = "TCP"
    }

  }

  tags = local.default_tags
}
