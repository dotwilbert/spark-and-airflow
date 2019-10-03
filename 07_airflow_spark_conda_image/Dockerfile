FROM spark_conda_base:1.0.0

ENV AIRFLOW_HOME=/home/airflow \
    POSTGRES_HOST=database \
    POSTGRES_PORT=5432 \
    POSTGRES_DB=airflow \
    POSTGRES_USER=airflow \
    POSTGRES_PASSWORD=airflow \
    AIRFLOW__CORE__FERNET_KEY=uQ5Fz122Qu2yQH5PfdMrAjH0WIkgtx1df435T7GTGm4= \
    AIRFLOW__CORE__LOAD_EXAMPLES=False

COPY req-airflow-project.txt /root/req-airflow-project.txt

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y \
        gosu \
        sudo \
        gettext \
        netcat \
    && apt-get clean -y \
    && groupadd -r airflow --gid=1717 \
    && useradd -m -r -g airflow --uid=1717 --home-dir=/home/airflow --shell=/bin/bash airflow \
    && sed -i -e '/^\(root\s*ALL=(ALL:ALL).*\)/a airflow ALL=(ALL:ALL) NOPASSWD: ALL' /etc/sudoers

RUN set -eux \
    && cd /root \
    && . /root/.bashrc \
    && export CONDA_PROJECT=airflow-project \
    && conda create --yes --name ${CONDA_PROJECT} \
    && conda activate ${CONDA_PROJECT} \
    && conda config --env --append channels conda-forge \
    && conda config --env --set channel_priority flexible \
    && conda install --file req-${CONDA_PROJECT}.txt \
    && gosu airflow /opt/miniconda/bin/conda init -v \
    && conda clean --all
    
USER 1717:1717

RUN set -eux \
    && sed -e '1,+93d' /home/airflow/.bashrc > /home/airflow/.conda_environment
    
COPY --chown=1717:1717 airflow.cfg.template /home/airflow/airflow.cfg.template
COPY --chown=1717:1717 docker_entrypoint.sh /home/airflow/docker_entrypoint.sh

USER 1717:1717

WORKDIR /home/airflow

ENTRYPOINT [ "/home/airflow/docker_entrypoint.sh"]
# CMD [ "/bin/bash" ]