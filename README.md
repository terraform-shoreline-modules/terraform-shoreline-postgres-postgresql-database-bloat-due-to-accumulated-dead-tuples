
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# PostgreSQL database bloat due to accumulated dead tuples

---

This incident type involves the accumulation of dead tuples in a database due to `UPDATE` and `DELETE` activity, which can lead to bloat in both tables and indexes. Bloat is characterized by the accumulation of dead tuples that cause gaps in the physical layout, leading to excessive disk space usage and performance degradation. While `VACUUM FULL` is a standard command that can be used to get rid of bloat, it uses a long-lasting exclusive lock on the table, which can impact performance by blocking all queries to the table. [Pg_repack](https://github.com/reorg/pg_repack) uses a more graceful approach that requires short-lived locks, making it suitable for databases with high and concurrent activity.

### Parameters

```shell
export DATABASE_NAME="PLACEHOLDER"
export DATABASE_INDEX="PLACEHOLDER"
export DATABASE_PASSWORD="PLACEHOLDER"
export DATABASE_PORT="PLACEHOLDER"
export DATABASE_TABLE="PLACEHOLDER"
export DATABASE_USER="PLACEHOLDER"
export LOG_FILE_PATH="PLACEHOLDER"
export PG_REPACK_THRESHOLD="PLACEHOLDER"
export SCHEMA_NAME="PLACEHOLDER"
export VACUUM_FULL_THRESHOLD="PLACEHOLDER"
```

## Debug

### Check if the database is running

```shell
sudo systemctl status postgresql | grep "Active: active (running)" > /dev/null

if [ $? -ne 0 ]; then
  echo "PostgreSQL is not running"
  exit 1
fi
```

### Check the size of the database

```shell
sudo -u postgres psql -c "SELECT pg_size_pretty(pg_database_size('${DATABASE_NAME}'));" ${DATABASE_NAME}
```

### Check the amount of dead tuples

```shell
sudo -u postgres psql -c "SELECT schemaname, relname, n_dead_tup FROM pg_stat_user_tables ORDER BY n_dead_tup DESC LIMIT 10;"
```

### Check for index bloat

```shell
sudo -u postgres psql -c "SELECT t.tablename,  indexname,  c.reltuples, i.relpages, i.relpages * 8 / 1024 AS mb FROM pg_tables t INNER JOIN pg_indexes i ON t.tablename = i.tablename INNER JOIN pg_class c ON i.indexname = c.relname WHERE t.schemaname = '${SCHEMA_NAME}' ORDER BY mb DESC;" ${DATABASE_NAME}
```

### Check if autovacuum is enabled

```shell
sudo -u postgres psql -c "SHOW autovacuum_enabled;"
```

### Check if VACUUM FULL was run previously

```shell
sudo -u postgres psql -c "SELECT relname, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze FROM pg_stat_all_tables WHERE schemaname = '${SCHEMA_NAME}' ORDER BY relname;"
```

### Check for table and index bloat using pg_repack

```shell
pg_repack -d ${DATABASE_NAME} -t ${DATABASE_TABLE} -U ${DATABASE_USER} -p ${DATABASE_PORT} --dry-run
```

### Check for pg_repack errors

```shell
pg_repack -d ${DATABASE_NAME} -t ${DATABASE_TABLE} -U ${DATABASE_USER} -p ${DATABASE_PORT} --check-only
```

## Repair

### Regularly monitor database tables and indexes for bloat using tools like pgstattuple and pg_repack.

```shell
#!/bin/bash

# Set the necessary variables
DATABASE_NAME=${DATABASE_NAME}
DATABASE_TABLE=${DATABASE_TABLE}
DATABASE_INDEX=${DATABASE_INDEX}

# Monitor the database for bloat using pgstattuple
pgstattuple -d $DATABASE_NAME -t $DATABASE_TABLE -i $DATABASE_INDEX

# Use pg_repack to get rid of bloat
pg_repack -d $DATABASE_NAME -t $DATABASE_TABLE -i $DATABASE_INDEX
```

### Use VACUUM FULL or pg_repack to reclaim disk space and improve performance, but schedule these operations during low traffic periods to minimize impact on queries.
```shell
#!/bin/bash

# Define variables

DATABASE_NAME=${DATABASE_NAME}
DATABASE_TABLE=${DATABASE_TABLE}
VACUUM_FULL_THRESHOLD=${VACUUM_FULL_THRESHOLD}
PG_REPACK_THRESHOLD=${PG_REPACK_THRESHOLD}
CURRENT_TIME=$(date +%s)
LOG_FILE=${LOG_FILE_PATH}

# Determine if VACUUM FULL or pg_repack is necessary

if [ $(psql -U postgres -d $DATABASE_NAME -c "SELECT pg_database_size('$DATABASE_NAME')" | sed -n 3p | awk '{print $1}') -gt $VACUUM_FULL_THRESHOLD ]; then
  echo "$(date) - VACUUM FULL initiated" >> $LOG_FILE
  psql -U postgres -d $DATABASE_NAME -c "VACUUM FULL VERBOSE ANALYZE"
elif [ $(psql -U postgres -d $DATABASE_NAME -c "SELECT pg_database_size('$DATABASE_NAME')" | sed -n 3p | awk '{print $1}') -gt $PG_REPACK_THRESHOLD ]; then
  echo "$(date) - pg_repack initiated" >> $LOG_FILE
  pg_repack -U postgres -d $DATABASE_NAME -t ${DATABASE_TABLE} -j 4 --no-superuser-check --no-tablespaces
else
  echo "$(date) - No action taken" >> $LOG_FILE
fi
```

### Optimize SQL queries to reduce the number of UPDATE and DELETE operations and minimize the accumulation of dead tuples.

```shell
#!/bin/bash

# Define variables
DATABASE_NAME=${DATABASE_NAME}
DATABASE_USER=${DATABASE_USER}
PASSWORD=${DATABASE_PASSWORD}

# Optimize SQL queries to reduce the number of UPDATE and DELETE operations
# and minimize the accumulation of dead tuples
psql -d $DATABASE_NAME -U $DATABASE_USER -c "ANALYZE;" > /dev/null
psql -d $DATABASE_NAME -U $DATABASE_USER -c "VACUUM ANALYZE;" > /dev/null
echo "SQL queries optimized and dead tuples minimized."
```