#added a comment
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.37.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "66bc95b7-5c49-4ea6-abcc-38ae21688cf2"
   features {
    # Example: Customizing Key Vault behavior
    key_vault {
      purge_soft_delete_on_destroy = true
    }

    # Example: Customizing Virtual Machine behavior
    virtual_machine_scale_set {
      force_delete = true
    }
  }
}
resource "azurerm_resource_group" "RG-Terraform" {
  name     = "terraform-resource-group"
  location = "West Europe"
}

resource "azurerm_app_service_plan" "ASP-TerraForm" {
  name                = "nagclk-terraform-appserviceplan"
  location            = azurerm_resource_group.RG-Terraform.location
  resource_group_name = azurerm_resource_group.RG-Terraform.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "AS-Terraform" {
  name                = "nagclk-app-service-terraform"
  location            = azurerm_resource_group.RG-Terraform.location
  resource_group_name = azurerm_resource_group.RG-Terraform.name
  app_service_plan_id = azurerm_app_service_plan.ASP-TerraForm.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=tcp:${azurerm_mssql_server.terraform-sqlserver.fully_qualified_domain_name} Database=${azurerm_mssql_database.terraform-sqldatabase.name};User ID=${azurerm_mssql_server.terraform-sqlserver.administrator_login};Password=${azurerm_mssql_server.terraform-sqlserver.administrator_login_password};Trusted_Connection=False;Encrypt=True;"
  }
}

resource "azurerm_mssql_server" "terraform-sqlserver" {
  name                         = "terraform-sqlserver"
  resource_group_name          = azurerm_resource_group.RG-Terraform.name
  location                     = azurerm_resource_group.RG-Terraform.location
  version                      = "12.0"
  administrator_login          = "nagAdmin"
  administrator_login_password = "Admin@123456#"
}

resource "azurerm_mssql_database" "terraform-sqldatabase" {
  name         = "terraform-sqldatabase"
  server_id    = azurerm_mssql_server.terraform-sqlserver.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "S0"
  enclave_type = "VBS"

  tags = {
    environment = "production"
  }
}