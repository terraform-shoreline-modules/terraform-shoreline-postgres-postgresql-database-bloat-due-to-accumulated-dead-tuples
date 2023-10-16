resource "shoreline_notebook" "postgresql_database_bloat_due_to_accumulated_dead_tuples" {
  name       = "postgresql_database_bloat_due_to_accumulated_dead_tuples"
  data       = file("${path.module}/data/postgresql_database_bloat_due_to_accumulated_dead_tuples.json")
  depends_on = [shoreline_action.invoke_pg_status,shoreline_action.invoke_monitor_bloat_and_repack,shoreline_action.invoke_vacuum_pg_repack,shoreline_action.invoke_optimize_sql_queries]
}

resource "shoreline_file" "pg_status" {
  name             = "pg_status"
  input_file       = "${path.module}/data/pg_status.sh"
  md5              = filemd5("${path.module}/data/pg_status.sh")
  description      = "Check if the database is running"
  destination_path = "/tmp/pg_status.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "monitor_bloat_and_repack" {
  name             = "monitor_bloat_and_repack"
  input_file       = "${path.module}/data/monitor_bloat_and_repack.sh"
  md5              = filemd5("${path.module}/data/monitor_bloat_and_repack.sh")
  description      = "Regularly monitor database tables and indexes for bloat using tools like pgstattuple and pg_repack."
  destination_path = "/tmp/monitor_bloat_and_repack.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "vacuum_pg_repack" {
  name             = "vacuum_pg_repack"
  input_file       = "${path.module}/data/vacuum_pg_repack.sh"
  md5              = filemd5("${path.module}/data/vacuum_pg_repack.sh")
  description      = "Use VACUUM FULL or pg_repack to reclaim disk space and improve performance, but schedule these operations during low traffic periods to minimize impact on queries."
  destination_path = "/tmp/vacuum_pg_repack.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "optimize_sql_queries" {
  name             = "optimize_sql_queries"
  input_file       = "${path.module}/data/optimize_sql_queries.sh"
  md5              = filemd5("${path.module}/data/optimize_sql_queries.sh")
  description      = "Optimize SQL queries to reduce the number of UPDATE and DELETE operations and minimize the accumulation of dead tuples."
  destination_path = "/tmp/optimize_sql_queries.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_pg_status" {
  name        = "invoke_pg_status"
  description = "Check if the database is running"
  command     = "`chmod +x /tmp/pg_status.sh && /tmp/pg_status.sh`"
  params      = []
  file_deps   = ["pg_status"]
  enabled     = true
  depends_on  = [shoreline_file.pg_status]
}

resource "shoreline_action" "invoke_monitor_bloat_and_repack" {
  name        = "invoke_monitor_bloat_and_repack"
  description = "Regularly monitor database tables and indexes for bloat using tools like pgstattuple and pg_repack."
  command     = "`chmod +x /tmp/monitor_bloat_and_repack.sh && /tmp/monitor_bloat_and_repack.sh`"
  params      = ["DATABASE_INDEX","DATABASE_NAME","DATABASE_TABLE"]
  file_deps   = ["monitor_bloat_and_repack"]
  enabled     = true
  depends_on  = [shoreline_file.monitor_bloat_and_repack]
}

resource "shoreline_action" "invoke_vacuum_pg_repack" {
  name        = "invoke_vacuum_pg_repack"
  description = "Use VACUUM FULL or pg_repack to reclaim disk space and improve performance, but schedule these operations during low traffic periods to minimize impact on queries."
  command     = "`chmod +x /tmp/vacuum_pg_repack.sh && /tmp/vacuum_pg_repack.sh`"
  params      = ["LOG_FILE_PATH","PG_REPACK_THRESHOLD","DATABASE_NAME","VACUUM_FULL_THRESHOLD","DATABASE_TABLE"]
  file_deps   = ["vacuum_pg_repack"]
  enabled     = true
  depends_on  = [shoreline_file.vacuum_pg_repack]
}

resource "shoreline_action" "invoke_optimize_sql_queries" {
  name        = "invoke_optimize_sql_queries"
  description = "Optimize SQL queries to reduce the number of UPDATE and DELETE operations and minimize the accumulation of dead tuples."
  command     = "`chmod +x /tmp/optimize_sql_queries.sh && /tmp/optimize_sql_queries.sh`"
  params      = ["DATABASE_PASSWORD","DATABASE_NAME","DATABASE_USER"]
  file_deps   = ["optimize_sql_queries"]
  enabled     = true
  depends_on  = [shoreline_file.optimize_sql_queries]
}

