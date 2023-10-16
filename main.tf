terraform {
  required_version = ">= 0.13.1"

  required_providers {
    shoreline = {
      source  = "shorelinesoftware/shoreline"
      version = ">= 1.11.0"
    }
  }
}

provider "shoreline" {
  retries = 2
  debug = true
}

module "postgresql_database_bloat_due_to_accumulated_dead_tuples" {
  source    = "./modules/postgresql_database_bloat_due_to_accumulated_dead_tuples"

  providers = {
    shoreline = shoreline
  }
}