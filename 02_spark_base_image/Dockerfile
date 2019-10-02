FROM debian_base:10.1-slim

# Tasks:
#   - modify sources add oldstable (stretch)
#   - install
#     - procps
#     - openssh-client
#     - openssh-server
#     - wget
#     - gawk
#     - openjdk-8-jdk-headless
#     - ca-certificates-java
#     - python3
#   - clean up apt
#   - fix .jinfo files
#   - download, check and unpack spark in /opt

# procps - Spark needs ps command
#     root@5c3bd31be061:/opt/spark-2.4.4-bin-hadoop2.7# ls -l ./sbin/start-all.sh 
#     -rwxr-xr-x 1 1000 1000 1190 Aug 27 21:30 ./sbin/start-all.sh
#     root@5c3bd31be061:/opt/spark-2.4.4-bin-hadoop2.7# ./sbin/start-all
#     bash: ./sbin/start-all: No such file or directory
#     root@5c3bd31be061:/opt/spark-2.4.4-bin-hadoop2.7# ./sbin/start-all.sh 
#     starting org.apache.spark.deploy.master.Master, logging to /opt/spark-2.4.4-bin-hadoop2.7/logs/spark--org.apache.spark.deploy.master.Master-1-5c3bd31be061.out
#     /opt/spark-2.4.4-bin-hadoop2.7/sbin/spark-daemon.sh: line 136: ps: command not found
#     /opt/spark-2.4.4-bin-hadoop2.7/sbin/spark-daemon.sh: line 136: ps: command not found
#     /opt/spark-2.4.4-bin-hadoop2.7/sbin/spark-daemon.sh: line 136: ps: command not found
#     /opt/spark-2.4.4-bin-hadoop2.7/sbin/spark-daemon.sh: line 136: ps: command not found
#     /opt/spark-2.4.4-bin-hadoop2.7/sbin/spark-daemon.sh: line 136: ps: command not found
#     /opt/spark-2.4.4-bin-hadoop2.7/sbin/spark-daemon.sh: line 136: ps: command not found
#     /opt/spark-2.4.4-bin-hadoop2.7/sbin/spark-daemon.sh: line 136: ps: command not found

# openjdk-8-headless - openjdk-11 didn't work: Spark 2.4.4 protested with illegal access warnings in Java classes.
#     Files can be gotten from
#         http://ftp.ca.debian.org/debian/pool/main/o/openjdk-8/openjdk-8-jdk-headless_8u222-b10-1_amd64.deb
#         http://ftp.ca.debian.org/debian/pool/main/o/openjdk-8/openjdk-8-jre-headless_8u222-b10-1_amd64.deb
#         http://ftp.ca.debian.org/debian/pool/main/o/openjdk-8/openjdk-8-source_8u222-b10-1_all.deb
#     For now, start with adding Debian 9 'stretch' repositories and fetch openjdk from there. 
#     There are a few issues with the .jinfo files. A number of binaries don't exists in 
#     the filesystem, b/c headless. Fix them up so they don't generate errors
# python3 - setup python 3 and create /usr/bin/python to run python 3
# openssh-client and server - Spark uses ssh to connect to workers in cluster
# wget - download tar balls
# gawk - patch up .jinfo files
 

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y \
        procps \
        openssh-client \
        openssh-server \
        wget \
        gawk \
        libpq-dev \
        python3 \
        python3-pip \
        python3-levenshtein \
    && apt-get clean \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2000 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 2000 \
    && pip install --no-binary :all: psycopg2 \
    && pip install pytz \
    && update-alternatives --remove-all pip \
    && apt-get remove -y python3-pip libpq-dev \
    && apt-get autoremove -y \
    && apt-get clean -y


# By tricking out the apt-get, the package openjdk-8-jre-headless will be installed. The standard postinstall
# tries to install man pages, for which the folder does not exist. A number of files in the .jinfo do not exist.
# Clean that behavior up.

RUN set -eux \
    && printf "deb http://deb.debian.org/debian stretch main\ndeb http://deb.debian.org/debian stretch-updates main\n" > /etc/apt/sources.list.d/stretch.list \
    && apt-get update \
    && cp /usr/bin/update-alternatives /usr/bin/update-alternatives.paused \
    && echo 'exit 0' > /usr/bin/update-alternatives \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y \
            openjdk-8-jre-headless \
            ca-certificates-java \
    && mv /usr/bin/update-alternatives.paused /usr/bin/update-alternatives \
    && jinfo='/usr/lib/jvm/.java-1.8.0-openjdk-amd64.jinfo'; export jinfo; sed_cmd='sed -i'; export sed_cmd; \
        for f in $(awk '/^(hl|jre|jdk|plugin)/ {print $3}' ${jinfo}); do \
        if [ ! -f "${f}" ]; then sed_cmd="${sed_cmd} -e \\#${f}#d"; fi; done; ${sed_cmd} ${jinfo}; \
        unset jinfo; unset sed_cmd \
    && jinfo='/usr/lib/jvm/.java-1.8.0-openjdk-amd64.jinfo'; export jinfo; \
        awk '/^(hl|jre|jdk|plugin)/ {print $2 " " $3}' ${jinfo} | sort -u | while read name location; \
        do update-alternatives --install /usr/bin/${name} ${name} ${location} 1000; done; unset jinfo \
    && update-java-alternatives -s java-1.8.0-openjdk-amd64 \
    && printf "Downloading spark. This is a big file. Be patient..." \
    && wget -q 'http://apache.mirrors.ionfish.org/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz' \
    && wget -qO- 'https://www.apache.org/dist/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz.sha512'\
       | awk 'BEGIN { FS = ":[ ]*"; line1 = 1; hash = ""; } { if (line1) { line1 = 0; fn = $1; hash = gensub("[ ]*", "", "g", $2); } else { hash=hash gensub("[ ]*", "", "g", $1); } } END { print hash " " fn }'\
       | sha512sum -c \
    && tar xzf spark-2.4.4-bin-hadoop2.7.tgz -C /opt \
    && rm -f spark-2.4.4-bin-hadoop2.7.tgz

USER 0:0

WORKDIR /opt/spark-2.4.4-bin-hadoop2.7

CMD [ "/bin/bash" ]