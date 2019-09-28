FROM spark_base:1.0.0

ENV AIRFLOW_HOME=/opt/airflow \
    POSTGRES_HOST=database \
    POSTGRES_PORT=5432 \
    POSTGRES_DB=airflow \
    POSTGRES_USER=airflow \
    POSTGRES_PASSWORD=airflow \
    AIRFLOW__CORE__FERNET_KEY=uQ5Fz122Qu2yQH5PfdMrAjH0WIkgtx1df435T7GTGm4= \
    AIRFLOW__CORE__LOAD_EXAMPLES=False

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y \
        gosu \
        sudo \
        gettext \
        python3-six \
        python3-lib2to3 \
        python3-setuptools \
        python3-crypto \
        python3-cryptography \
        python3-levenshtein \
        python3-requests \
        python3-pip \
        libpq5 \
        libpq-dev \
        zlib1g \
        netcat \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 2000 \
    && pip install --no-binary :all: psycopg2 \
    && pip install pytz apache-airflow[crypto]==1.10.5 \
    && groupadd -r airflow --gid=1717 \
    && useradd -r -g airflow --uid=1717 --home-dir=/opt/airflow --shell=/bin/bash airflow \
    && mkdir -p /opt/airflow \
    && chown -R airflow:airflow /opt/airflow \
    && sed -i -e '/^\(root\s*ALL=(ALL:ALL).*\)/a airflow ALL=(ALL:ALL) NOPASSWD: ALL' /etc/sudoers \
    && update-alternatives --remove-all pip \
    && apt-get remove -y python3-pip libpq-dev \
    && apt-get autoremove -y \
    && apt-get clean -y

EXPOSE 8080

WORKDIR /opt/airflow

ADD --chown=1717:1717 resources/airflow.cfg.template airflow.cfg.template
ADD resources/docker_entrypoint.sh /opt/docker_entrypoint.sh

USER 0:0

ENTRYPOINT [ "/opt/docker_entrypoint.sh" ]
