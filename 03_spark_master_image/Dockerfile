FROM spark_base:2.0.1

ENV SPARK_NO_DAEMONIZE yes 

EXPOSE 7077/tcp 8080/tcp

WORKDIR /opt/spark-2.4.4-bin-hadoop2.7

ENTRYPOINT [ "./sbin/start-master.sh" ]