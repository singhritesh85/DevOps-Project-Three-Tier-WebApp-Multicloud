############################################### Azure Key Vault for MySQL Flexible Servers #######################################

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault_mysql" {
  name                        = "${var.prefix}2"
  location                    = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name         = azurerm_resource_group.vnetconnection_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7

  access_policy {
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = data.azurerm_client_config.current.object_id
    key_permissions         = ["Get", "List", "Delete", "Purge"]
    secret_permissions      = ["Get", "List", "Set", "Delete", "Purge"]
  }
}

resource "azurerm_key_vault_secret" "mysql_username" {
  name         = "${var.prefix}-mysql-server-username"
  value        = var.mysql_server_admin_username
  key_vault_id = azurerm_key_vault.key_vault_mysql.id
}

resource "random_password" "mysql_password" {
  length           = 16
  special          = true
  override_special = "_!%^@"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
}

resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-server-password"
  value        = random_password.mysql_password.result
  key_vault_id = azurerm_key_vault.key_vault_mysql.id
}

resource "azurerm_role_assignment" "key_vault_role_assignment" {
  scope                = azurerm_key_vault.key_vault_mysql.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

################################################ Azure MySQL Database For Flexible Servers ###################################################

resource "azurerm_private_dns_zone" "dexter_private_mysql" {
  name                = "dexter-mysql3.private.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dexter_mysql_vnet_link" {
  name                  = "multicloudprivate.com"
  private_dns_zone_name = azurerm_private_dns_zone.dexter_private_mysql.name
  virtual_network_id    = azurerm_virtual_network.vnet-1.id
  resource_group_name   = azurerm_resource_group.vnetconnection_rg.name
  depends_on            = [azurerm_subnet.mysql_flexible_server_subnet]
}

resource "azurerm_private_dns_a_record" "mysql_atype_recordset" {
  name                = "mysql-server"
  zone_name           = azurerm_private_dns_zone.dexter_private_mysql.name
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  ttl                 = 300
  records             = ["172.25.3.4"] # First IP Assigned to MySQL Flexible Server
}

resource "azurerm_network_security_group" "ec2_to_mysql_access" {
  name                = "AWS-EC2-to-Access-Azure-Database-for-MySQL-Flexible-Servers"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

# For MySQL Traffic
  security_rule {
    name                       = "Allow-MySQL-Connection"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefixes    = ["${var.vpc_cidr}", "${var.ip_range_subnet}", "${var.pods_ip_range}", "${var.services_ip_range}", "${var.ip_public_range_subnet}"]  
    destination_address_prefix = "*"
  }
  
  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

resource "azurerm_subnet_network_security_group_association" "ec2_to_mysql_access_association" {
  subnet_id = azurerm_subnet.mysql_flexible_server_subnet.id
  network_security_group_id = azurerm_network_security_group.ec2_to_mysql_access.id

  depends_on = [azurerm_mysql_flexible_server.azure_mysql]
}

resource "azurerm_mysql_flexible_server" "azure_mysql" {
  name                   = "dexter-mysql3"
  resource_group_name    = azurerm_resource_group.vnetconnection_rg.name
  location               = azurerm_resource_group.vnetconnection_rg.location
  version                = "8.4"
  administrator_login    = azurerm_key_vault_secret.mysql_username.value
  administrator_password = azurerm_key_vault_secret.mysql_password.value
  backup_retention_days  = 1
  delegated_subnet_id    = azurerm_subnet.mysql_flexible_server_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.dexter_private_mysql.id
  sku_name               = "GP_Standard_D2ads_v5"    ###"B_Standard_B2ms"
  zone                   = "2"

  storage {
    auto_grow_enabled = false
    io_scaling_enabled = false
    iops = 360
    size_gb = 20
  }
  
#  high_availability {
#    mode = "ZoneRedundant"
#    standby_availability_zone = 3
#  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dexter_mysql_vnet_link]
}

resource "azurerm_mysql_flexible_database" "mysql_database" {
  name                = "dexter"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  server_name         = azurerm_mysql_flexible_server.azure_mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"

  lifecycle {
    ignore_changes = [charset, collation]
  }
}

resource "azurerm_mysql_flexible_server_configuration" "disable_ssl" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  server_name         = azurerm_mysql_flexible_server.azure_mysql.name
  value               = "OFF" # This disables SSL enforcement
}
