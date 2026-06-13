terraform {
  required_providers {
    snowflake = {
      source  = "SnowflakeLabs/snowflake"
      version = "~> x.x"
    }
  }
}

# Variables — avoids hardcoding values throughout

variable "database_name" {
  default = "ANALYTICS"
}

variable "schema_name" {
  default = "REPORTING"
}

variable "warehouse_name" {
  default = "REPORTING_WH"
}

variable "role_name" {
  default = "REPORTING_ROLE"
}

variable "service_user_name" {
  default = "REPORTING_SVC_USER"
}

# Database

resource "snowflake_database" "analytics" {
  name    = var.database_name
  comment = "Analytics database for reporting workloads"
}

# Schema

resource "snowflake_schema" "reporting" {
  database = snowflake_database.analytics.name
  name     = var.schema_name
  comment  = "Reporting schema inside the Analytics database"
}


# Warehouse
# auto_suspend = 60s, auto_resume = true, size = SMALL


resource "snowflake_warehouse" "reporting_wh" {
  name           = var.warehouse_name
  warehouse_size = "SMALL"
  auto_suspend   = 60
  auto_resume    = true
  comment        = "Warehouse for reporting queries — small size, aggressive auto-suspend to control costs"
}

# Role

resource "snowflake_role" "reporting_role" {
  name    = var.role_name
  comment = "Role for reporting service user and analysts"
}

# Grants — full privileges on database and schema


resource "snowflake_database_grant" "reporting_db_grant" {
  database_name = snowflake_database.analytics.name
  privilege     = "ALL PRIVILEGES"
  roles         = [snowflake_role.reporting_role.name]

  depends_on = [snowflake_database.analytics, snowflake_role.reporting_role]
}

resource "snowflake_schema_grant" "reporting_schema_grant" {
  database_name = snowflake_database.analytics.name
  schema_name   = snowflake_schema.reporting.name
  privilege     = "ALL PRIVILEGES"
  roles         = [snowflake_role.reporting_role.name]

  depends_on = [snowflake_schema.reporting, snowflake_role.reporting_role]
}

# Service User

resource "snowflake_user" "reporting_svc_user" {
  name         = var.service_user_name
  login_name   = var.service_user_name
  display_name = "Reporting Service User"
  comment      = "Service account for automated reporting pipelines"

  default_role      = snowflake_role.reporting_role.name
  default_warehouse = snowflake_warehouse.reporting_wh.name

  depends_on = [snowflake_role.reporting_role, snowflake_warehouse.reporting_wh]
}

# Assign role to service user

resource "snowflake_role_grants" "reporting_role_grant" {
  role_name = snowflake_role.reporting_role.name
  users     = [snowflake_user.reporting_svc_user.name]

  depends_on = [snowflake_role.reporting_role, snowflake_user.reporting_svc_user]
}
