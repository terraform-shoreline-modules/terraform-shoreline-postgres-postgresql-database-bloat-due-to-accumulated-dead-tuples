#!/bin/bash

# Set the necessary variables
DATABASE_NAME=${DATABASE_NAME}
DATABASE_TABLE=${DATABASE_TABLE}
DATABASE_INDEX=${DATABASE_INDEX}

# Monitor the database for bloat using pgstattuple
pgstattuple -d $DATABASE_NAME -t $DATABASE_TABLE -i $DATABASE_INDEX

# Use pg_repack to get rid of bloat
pg_repack -d $DATABASE_NAME -t $DATABASE_TABLE -i $DATABASE_INDEX