#! /bin/bash -l

# set -eux
sudo chmod 777 /bigdata

cd ${AIRFLOW_HOME}
. ~/.bashrc
conda activate airflow-project

# Make sure we can reach the database
nc -z "${POSTGRES_HOST}" "${POSTGRES_PORT}" >/dev/null 2>&1 || { printf "There is no connection to database host %s on the network\n" "${POSTGRES_HOST}"; exit 1; }

# Create configuration file
# substvars='${AIRFLOW__CORE__FERNET_KEY}:${AIRFLOW_HOME}:${POSTGRES_PASSWORD}:${POSTGRES_HOST}:${POSTGRES_USER}:${POSTGRES_DB}'
# [[ -f "${AIRFLOW_HOME}"/airflow.cfg ]] || envsubst "${substvars}" <"${AIRFLOW_HOME}"/airflow.cfg.template >"${AIRFLOW_HOME}"/airflow.cfg
[[ -f "${AIRFLOW_HOME}"/airflow.cfg ]] || envsubst <"${AIRFLOW_HOME}"/airflow.cfg.template >"${AIRFLOW_HOME}"/airflow.cfg

# We're good.

# Initialize db
airflow initdb

# Start webserver. For some reason can't start it with -D.
# Start it as a background task instead.
airflow webserver &

# Start the main process.
exec airflow scheduler