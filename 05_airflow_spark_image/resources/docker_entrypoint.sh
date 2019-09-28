#! /bin/bash

set -eux
cd ${AIRFLOW_HOME}

# Make sure we can reach the database
nc -z "${POSTGRES_HOST}" "${POSTGRES_PORT}" >/dev/null 2>&1 || { printf "There is no connection to database host %s on the network\n" "${POSTGRES_HOST}"; exit 1; }

# Create configuration file
# substvars='${AIRFLOW__CORE__FERNET_KEY}:${AIRFLOW_HOME}:${POSTGRES_PASSWORD}:${POSTGRES_HOST}:${POSTGRES_USER}:${POSTGRES_DB}'
# [[ -f "${AIRFLOW_HOME}"/airflow.cfg ]] || envsubst "${substvars}" <"${AIRFLOW_HOME}"/airflow.cfg.template >"${AIRFLOW_HOME}"/airflow.cfg
[[ -f "${AIRFLOW_HOME}"/airflow.cfg ]] || gosu airflow envsubst <"${AIRFLOW_HOME}"/airflow.cfg.template >"${AIRFLOW_HOME}"/airflow.cfg

# We're good.

# Initialize db
gosu airflow airflow initdb

# Start webserver. For some reason can't start it with -D.
# Start it as a background task instead.
gosu airflow airflow webserver &

# Start the main process.
exec gosu airflow airflow scheduler