FROM airflow_spark_conda:1.1.0

COPY --chown=1717:1717 req-sc-jail-project.txt /home/airflow/req-sc-jail-project.txt

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && sudo -u root -g root DEBIAN_FRONTEND=noninteractive apt-get update \
    && sudo -u root -g root DEBIAN_FRONTEND=noninteractive apt-get install -y \
        poppler-utils \
        tesseract-ocr \
        libpostgresql-jdbc-java \
    && . /home/airflow/.conda_environment \
    && CONDA_PROJECT=sc-jail-project \
    && conda create --yes --name ${CONDA_PROJECT} python=3.7.3 \
    && conda activate ${CONDA_PROJECT} \
    && conda config --env --append channels conda-forge \
    && conda config --env --set channel_priority flexible \
    && conda install --yes --file=req-${CONDA_PROJECT}.txt \
    && conda clean --all \
    && sudo -u root -g root DEBIAN_FRONTEND=noninteractive apt-get clean -y \
    && mkdir -p /home/airflow/scripts/sc-jail-project /home/airflow/dags \
    && sudo -u root -g root chown -R 1717:1717 /home/airflow
    
COPY --chown=1717:1717 spark-sc-jail-project/dl-santa-clara-dpcs.py /home/airflow/scripts/sc-jail-project/dl-santa-clara-dpcs.py
COPY --chown=1717:1717 spark-sc-jail-project/convert-dpcs-to-text.py /home/airflow/scripts/sc-jail-project/convert-dpcs-to-text.py
COPY --chown=1717:1717 spark-sc-jail-project/load-dpcs.py /home/airflow/scripts/sc-jail-project/load-dpcs.py
COPY --chown=1717:1717 spark-sc-jail-project/dag-sc-jail.py /home/airflow/dags/dag-sc-jail.py

USER 1717:1717

WORKDIR /home/airflow

ENTRYPOINT [ "/home/airflow/docker_entrypoint.sh"]


# && sudo -u root -g root bash -c "echo '#! /bin/bash' > /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root bash -c "echo 'cd root' >> /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root bash -c "echo '. /root/.bashrc' >> /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root bash -c "echo 'CONDA_PROJECT=sc-jail-project' >> /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root ls -l /root \
# && sudo -u root -g root bash -c "echo 'conda create --yes --name "${'CONDA_PROJECT'}" python=3.7.3' >> /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root bash -c "echo 'conda activate ${CONDA_PROJECT}' >> /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root bash -c "echo 'conda config --env --append channels conda-forge' >> /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root bash -c "echo 'conda config --env --set channel_priority flexible' >> /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root bash -c "echo 'conda install --yes --file=req-${CONDA_PROJECT}.txt' >> /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root bash -c "echo 'conda clean --all' >> /root/conda-sc-jail-project.sh" \
# && sudo -u root -g root chmod 755 /root/conda-sc-jail-project.sh \
# && sudo -u root -g root /root/conda-sc-jail-project.sh \
    