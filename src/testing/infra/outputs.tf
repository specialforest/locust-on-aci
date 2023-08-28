output "locust_webui_fqdn" {
  value = azurerm_container_group.controller.*.fqdn
}