provider "azurerm" {
  features {}
  subscription_id = "5a488830-0c10-4e28-a870-cbc88de5c3ab"
}

resource "azurerm_resource_group" "rg" {
  name     = "PetClinic-RG-v2"
  location = "East US 2"
}

# 1. Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "petclinicacr${random_id.random.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# 2. Kubernetes Cluster (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "PetClinic-Cluster-v2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "petclinicaksv2"

  default_node_pool {
    name       = "default"
    node_count = 2  
    vm_size    = "Standard_B2ms"
  }

  identity {
    type = "SystemAssigned"
  }
}

# 3. Allow AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# 4. SQL Server & Database 
resource "azurerm_mssql_server" "sql" {
  name                         = "petclinicsql${random_id.random.hex}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Password1234!" 
}

resource "azurerm_mssql_database" "db" {
  name      = "petclinicdb"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"
}

# Utility for unique names
resource "random_id" "random" {
  byte_length = 4
}
