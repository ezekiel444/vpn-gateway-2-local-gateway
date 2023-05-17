resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "postgresql-db"
  server_id = azurerm_postgresql_flexible_server.server.id
  collation = "en_US.UTF8"
  charset   = "UTF8"
}