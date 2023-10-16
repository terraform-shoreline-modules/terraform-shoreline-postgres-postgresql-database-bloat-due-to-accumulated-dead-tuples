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