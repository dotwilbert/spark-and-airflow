FROM airflow_spark_conda:1.1.0

COPY req-sc-jail-project.txt /root/req-sc-jail-project.txt

RUN set -eux \
    && cd /root \
    && . /root/.bashrc \
    && CONDA_PROJECT=sc-jail-project \
    && conda create --yes --name ${CONDA_PROJECT} python=3.7.3 \
    && conda activate ${CONDA_PROJECT} \
    && conda config --env --append channels conda-forge \
    && conda config --env --set channel_priority flexible \
    && conda install --yes --file=req-${CONDA_PROJECT}.txt \
    && conda clean --all \
    && mkdir -p ~/scripts/sc-jail-project ~/dags 
    
COPY --chown=1717:1717 spark-sc-jail-project/dl-santa-clara-dpcs.py /home/airflow/scripts/sc-jail-project/dl-santa-clara-dpcs.py
COPY --chown=1717:1717 spark-sc-jail-project/convert-dpcs-to-text.py /home/airflow/scripts/sc-jail-project/convert-dpcs-to-text.py
COPY --chown=1717:1717 spark-sc-jail-project/load-dpcs.py /home/airflow/scripts/sc-jail-project/load-dpcs.py
COPY --chown=1717:1717 spark-sc-jail-project/dag-sc-jail.py /home/airflow/dags/dag-sc-jail.py

USER 1717:1717

WORKDIR /home/airflow

ENTRYPOINT [ "/home/airflow/docker_entrypoint.sh"]
