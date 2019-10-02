FROM spark_base:2.0.0

ENV SPARK_NO_DAEMONIZE=yes

EXPOSE 8081/tcp

WORKDIR /opt/spark-2.4.4-bin-hadoop2.7

ENTRYPOINT [ "./sbin/start-slave.sh" ]
CMD [ "spark://sparkmaster:7077" ]
# CMD [ "/bin/bash" ]
# 172.26.0.2:7077
# This container needs to be started with --link="cfc879c80994:sparkmaster" cfc879c80994 is container_id