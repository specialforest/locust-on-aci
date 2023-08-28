variable "location" {
  description = "The Azure Region in which the controller and the shared storage account will be provisioned."
  type        = string
  default     = "northeurope"
}

variable "resource_group" {
  description = "Resource group name. Must not contain any special characters."
  type        = string
  default     = "locust-on-aci"
}

variable "environment" {
  description = "Environment Resource Tag"
  type        = string
  default     = "dev"
}

variable "use_acr" {
  description = "Provision and use Azure Container Registry"
  type        = bool
  default     = true
}

variable "locust_container_image" {
  description = "Locust Container Image"
  type        = string
  default     = "locustio/locust:latest"
}

variable "targeturl" {
  description = "Target URL"
  type        = string
  default     = "https://my-sample-app.net"
}

variable "locustWorkerNodes" {
  description = "Number of Locust worker instances (zero will stop controller)"
  type        = string
  default     = "0"
}

variable "locustWorkerLocations" {
  description = "List of regions to deploy workers to in round robin fashion"
  type        = list(any)
  default = [
    "northeurope",
    "eastus2",
    "southeastasia",
    "westeurope",
    "westus",
    "australiaeast",
    "francecentral",
    "southcentralus",
    "japaneast",
    "southindia",
    "brazilsouth",
    "germanywestcentral",
    "uksouth",
    "canadacentral",
    "eastus",
    "uaenorth",
    "koreacentral",
    "eastasia",
    "australiasoutheast",
    "canadaeast",
    "centralindia",
    "japanwest",
    "norwayeast",
    "switzerlandnorth",
    "ukwest",
    "centralus",
    "northcentralus",
    "westcentralus",
    "westus2"
  ]
}
