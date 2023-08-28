resource "azurerm_key_vault" "keyvault" {
  name                        = random_pet.deployment.id
  location                    = azurerm_resource_group.deployment.location
  resource_group_name         = azurerm_resource_group.deployment.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

# Give KV secret permissions to the service principal that runs the Terraform apply itself
resource "azurerm_key_vault_access_policy" "owner" {
  key_vault_id = azurerm_key_vault.keyvault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Delete", "Purge", "Set", "Backup", "Restore", "Recover"
  ]

 certificate_permissions = [
    "Get", "List", "Delete", "Create", "Update"
 ]
}

# Give KV secret permissions to the service principal that runs the Terraform apply itself
resource "azurerm_key_vault_access_policy" "cli" {
  key_vault_id = azurerm_key_vault.keyvault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id
  application_id = "04b07795-8ddb-461a-bbee-02f9e1bf7b46" # Microsoft Azure CLI

  secret_permissions = [
    "Get", "List", "Delete", "Purge", "Set", "Backup", "Restore", "Recover"
  ]

 certificate_permissions = [
    "Get", "List", "Delete", "Create", "Update"
 ]
}

resource "random_password" "locustsecret" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "locustsecret" {
  name         = "locust-webauth-secret"
  value        = random_password.locustsecret.result
  key_vault_id = azurerm_key_vault.keyvault.id

  depends_on = [ azurerm_key_vault_access_policy.cli ]
}

resource "azurerm_key_vault_certificate" "locustcert" {
  name         = "locust"
  key_vault_id = azurerm_key_vault.keyvault.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      # subject_alternative_names {
      #   dns_names = ["internal.contoso.com", "domain.hello.world"]
      # }

      subject = "CN=${random_pet.deployment.id}.${azurerm_resource_group.deployment.location}.azurecontainer.io"
      validity_in_months = 12
    }
  }

  depends_on = [ azurerm_key_vault_access_policy.cli ]
}

data "azurerm_key_vault_secret" "locustcert" {
  name      = "locust"
  key_vault_id = azurerm_key_vault.keyvault.id

  depends_on = [ azurerm_key_vault_certificate.locustcert ]
}
