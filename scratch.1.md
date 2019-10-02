ca-certificates dbus fontconfig-config fonts-dejavu-core java-common krb5-locales libapparmor1 libavahi-client3 libavahi-common-data libavahi-common3 libbsd0 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libfreetype6 libgssapi-krb5-2 libjpeg62-turbo libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 liblcms2-2 libnspr4 libnss3 libpcsclite1 libpng16-16 libsqlite3-0 libssl1.1 libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 libxext6 libxi6 libxrender1 libxtst6 lsb-base openssl sensible-utils ucf x11-common

openjdk-8-jre-headless
ca-certificates-java




```bash
jinfo='/usr/lib/jvm/.java-1.8.0-openjdk-amd64.jinfo'; export jinfo; sed_cmd='sed -i'; export sed_cmd; for f in $(awk '/^(hl|jre|jdk|plugin)/ {print $3}' ${jinfo}); do if [ ! -f "${f}" ]; then sed_cmd="${sed_cmd} -e \\#${f}#d"; fi; done; ${sed_cmd} ${jinfo}; unset jinfo; unset sed_cmd
```

```bash
jinfo='/usr/lib/jvm/.java-1.8.0-openjdk-amd64.jinfo'; export jinfo; awk '/^(hl|jre|jdk|plugin)/ {print $2 " " $3}' ${jinfo} | sort -u | while read name location; do update-alternatives --install /usr/bin/${name} ${name} ${location} 1000; done; unset jinfo;
```

# sbin/start-all.sh 

```bash
#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Start all spark daemons.
# Starts the master on this node.
# Starts a worker on each node specified in conf/slaves

if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

# Load the Spark configuration
. "${SPARK_HOME}/sbin/spark-config.sh"

# Start Master
"${SPARK_HOME}/sbin"/start-master.sh

# Start Workers
"${SPARK_HOME}/sbin"/start-slaves.sh
```

# sbin/start-master.sh 

```bash
#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Starts the master on the machine this script is executed on.

if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

# NOTE: This exact class name is matched downstream by SparkSubmit.
# Any changes need to be reflected there.
CLASS="org.apache.spark.deploy.master.Master"

if [[ "$@" = *--help ]] || [[ "$@" = *-h ]]; then
  echo "Usage: ./sbin/start-master.sh [options]"
  pattern="Usage:"
  pattern+="\|Using Spark's default log4j profile:"
  pattern+="\|Registered signal handlers for"

  "${SPARK_HOME}"/bin/spark-class $CLASS --help 2>&1 | grep -v "$pattern" 1>&2
  exit 1
fi

ORIGINAL_ARGS="$@"

. "${SPARK_HOME}/sbin/spark-config.sh"

. "${SPARK_HOME}/bin/load-spark-env.sh"

if [ "$SPARK_MASTER_PORT" = "" ]; then
  SPARK_MASTER_PORT=7077
fi

if [ "$SPARK_MASTER_HOST" = "" ]; then
  case `uname` in
      (SunOS)
          SPARK_MASTER_HOST="`/usr/sbin/check-hostname | awk '{print $NF}'`"
          ;;
      (*)
          SPARK_MASTER_HOST="`hostname -f`"
          ;;
  esac
fi

if [ "$SPARK_MASTER_WEBUI_PORT" = "" ]; then
  SPARK_MASTER_WEBUI_PORT=8080
fi

"${SPARK_HOME}/sbin"/spark-daemon.sh start $CLASS 1 \
  --host $SPARK_MASTER_HOST --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT \
  $ORIGINAL_ARGS
```

# sbin/spark-daemon.sh 

```bash
#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Runs a Spark command as a daemon.
#
# Environment Variables
#
#   SPARK_CONF_DIR  Alternate conf dir. Default is ${SPARK_HOME}/conf.
#   SPARK_LOG_DIR   Where log files are stored. ${SPARK_HOME}/logs by default.
#   SPARK_MASTER    host:path where spark code should be rsync'd from
#   SPARK_PID_DIR   The pid files are stored. /tmp by default.
#   SPARK_IDENT_STRING   A string representing this instance of spark. $USER by default
#   SPARK_NICENESS The scheduling priority for daemons. Defaults to 0.
#   SPARK_NO_DAEMONIZE   If set, will run the proposed command in the foreground. It will not output a PID file.
##

usage="Usage: spark-daemon.sh [--config <conf-dir>] (start|stop|submit|status) <spark-command> <spark-instance-number> <args...>"

# if no args specified, show usage
if [ $# -le 1 ]; then
  echo $usage
  exit 1
fi

if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

. "${SPARK_HOME}/sbin/spark-config.sh"

# get arguments

# Check if --config is passed as an argument. It is an optional parameter.
# Exit if the argument is not a directory.

if [ "$1" == "--config" ]
then
  shift
  conf_dir="$1"
  if [ ! -d "$conf_dir" ]
  then
    echo "ERROR : $conf_dir is not a directory"
    echo $usage
    exit 1
  else
    export SPARK_CONF_DIR="$conf_dir"
  fi
  shift
fi

option=$1
shift
command=$1
shift
instance=$1
shift

spark_rotate_log ()
{
    log=$1;
    num=5;
    if [ -n "$2" ]; then
        num=$2
    fi
    if [ -f "$log" ]; then # rotate logs
        while [ $num -gt 1 ]; do
            prev=`expr $num - 1`
            [ -f "$log.$prev" ] && mv "$log.$prev" "$log.$num"
            num=$prev
        done
        mv "$log" "$log.$num";
    fi
}

. "${SPARK_HOME}/bin/load-spark-env.sh"

if [ "$SPARK_IDENT_STRING" = "" ]; then
  export SPARK_IDENT_STRING="$USER"
fi


export SPARK_PRINT_LAUNCH_COMMAND="1"

# get log directory
if [ "$SPARK_LOG_DIR" = "" ]; then
  export SPARK_LOG_DIR="${SPARK_HOME}/logs"
fi
mkdir -p "$SPARK_LOG_DIR"
touch "$SPARK_LOG_DIR"/.spark_test > /dev/null 2>&1
TEST_LOG_DIR=$?
if [ "${TEST_LOG_DIR}" = "0" ]; then
  rm -f "$SPARK_LOG_DIR"/.spark_test
else
  chown "$SPARK_IDENT_STRING" "$SPARK_LOG_DIR"
fi

if [ "$SPARK_PID_DIR" = "" ]; then
  SPARK_PID_DIR=/tmp
fi

# some variables
log="$SPARK_LOG_DIR/spark-$SPARK_IDENT_STRING-$command-$instance-$HOSTNAME.out"
pid="$SPARK_PID_DIR/spark-$SPARK_IDENT_STRING-$command-$instance.pid"

# Set default scheduling priority
if [ "$SPARK_NICENESS" = "" ]; then
    export SPARK_NICENESS=0
fi

execute_command() {
  if [ -z ${SPARK_NO_DAEMONIZE+set} ]; then
      nohup -- "$@" >> $log 2>&1 < /dev/null &
      newpid="$!"

      echo "$newpid" > "$pid"

      # Poll for up to 5 seconds for the java process to start
      for i in {1..10}
      do
        if [[ $(ps -p "$newpid" -o comm=) =~ "java" ]]; then
           break
        fi
        sleep 0.5
      done

      sleep 2
      # Check if the process has died; in that case we'll tail the log so the user can see
      if [[ ! $(ps -p "$newpid" -o comm=) =~ "java" ]]; then
        echo "failed to launch: $@"
        tail -10 "$log" | sed 's/^/  /'
        echo "full log in $log"
      fi
  else
      "$@"
  fi
}

run_command() {
  mode="$1"
  shift

  mkdir -p "$SPARK_PID_DIR"

  if [ -f "$pid" ]; then
    TARGET_ID="$(cat "$pid")"
    if [[ $(ps -p "$TARGET_ID" -o comm=) =~ "java" ]]; then
      echo "$command running as process $TARGET_ID.  Stop it first."
      exit 1
    fi
  fi

  if [ "$SPARK_MASTER" != "" ]; then
    echo rsync from "$SPARK_MASTER"
    rsync -a -e ssh --delete --exclude=.svn --exclude='logs/*' --exclude='contrib/hod/logs/*' "$SPARK_MASTER/" "${SPARK_HOME}"
  fi

  spark_rotate_log "$log"
  echo "starting $command, logging to $log"

  case "$mode" in
    (class)
      execute_command nice -n "$SPARK_NICENESS" "${SPARK_HOME}"/bin/spark-class "$command" "$@"
      ;;

    (submit)
      execute_command nice -n "$SPARK_NICENESS" bash "${SPARK_HOME}"/bin/spark-submit --class "$command" "$@"
      ;;

    (*)
      echo "unknown mode: $mode"
      exit 1
      ;;
  esac

}

case $option in

  (submit)
    run_command submit "$@"
    ;;

  (start)
    run_command class "$@"
    ;;

  (stop)

    if [ -f $pid ]; then
      TARGET_ID="$(cat "$pid")"
      if [[ $(ps -p "$TARGET_ID" -o comm=) =~ "java" ]]; then
        echo "stopping $command"
        kill "$TARGET_ID" && rm -f "$pid"
      else
        echo "no $command to stop"
      fi
    else
      echo "no $command to stop"
    fi
    ;;

  (status)

    if [ -f $pid ]; then
      TARGET_ID="$(cat "$pid")"
      if [[ $(ps -p "$TARGET_ID" -o comm=) =~ "java" ]]; then
        echo $command is running.
        exit 0
      else
        echo $pid file is present but $command not running
        exit 1
      fi
    else
      echo $command not running.
      exit 2
    fi
    ;;

  (*)
    echo $usage
    exit 1
    ;;

esac
```

# sbin/start-slaves.sh 

```bash
#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Starts a slave instance on each machine specified in the conf/slaves file.

if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

. "${SPARK_HOME}/sbin/spark-config.sh"
. "${SPARK_HOME}/bin/load-spark-env.sh"

# Find the port number for the master
if [ "$SPARK_MASTER_PORT" = "" ]; then
  SPARK_MASTER_PORT=7077
fi

if [ "$SPARK_MASTER_HOST" = "" ]; then
  case `uname` in
      (SunOS)
          SPARK_MASTER_HOST="`/usr/sbin/check-hostname | awk '{print $NF}'`"
          ;;
      (*)
          SPARK_MASTER_HOST="`hostname -f`"
          ;;
  esac
fi

# Launch the slaves
"${SPARK_HOME}/sbin/slaves.sh" cd "${SPARK_HOME}" \; "${SPARK_HOME}/sbin/start-slave.sh" "spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT"
```

# sbin/start-slave.sh

```bash
#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Starts a slave on the machine this script is executed on.
#
# Environment Variables
#
#   SPARK_WORKER_INSTANCES  The number of worker instances to run on this
#                           slave.  Default is 1.
#   SPARK_WORKER_PORT       The base port number for the first worker. If set,
#                           subsequent workers will increment this number.  If
#                           unset, Spark will find a valid port number, but
#                           with no guarantee of a predictable pattern.
#   SPARK_WORKER_WEBUI_PORT The base port for the web interface of the first
#                           worker.  Subsequent workers will increment this
#                           number.  Default is 8081.

if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

# NOTE: This exact class name is matched downstream by SparkSubmit.
# Any changes need to be reflected there.
CLASS="org.apache.spark.deploy.worker.Worker"

if [[ $# -lt 1 ]] || [[ "$@" = *--help ]] || [[ "$@" = *-h ]]; then
  echo "Usage: ./sbin/start-slave.sh <master> [options]"
  pattern="Usage:"
  pattern+="\|Using Spark's default log4j profile:"
  pattern+="\|Registered signal handlers for"

  "${SPARK_HOME}"/bin/spark-class $CLASS --help 2>&1 | grep -v "$pattern" 1>&2
  exit 1
fi

. "${SPARK_HOME}/sbin/spark-config.sh"

. "${SPARK_HOME}/bin/load-spark-env.sh"

# First argument should be the master; we need to store it aside because we may
# need to insert arguments between it and the other arguments
MASTER=$1
shift

# Determine desired worker port
if [ "$SPARK_WORKER_WEBUI_PORT" = "" ]; then
  SPARK_WORKER_WEBUI_PORT=8081
fi

# Start up the appropriate number of workers on this machine.
# quick local function to start a worker
function start_instance {
  WORKER_NUM=$1
  shift

  if [ "$SPARK_WORKER_PORT" = "" ]; then
    PORT_FLAG=
    PORT_NUM=
  else
    PORT_FLAG="--port"
    PORT_NUM=$(( $SPARK_WORKER_PORT + $WORKER_NUM - 1 ))
  fi
  WEBUI_PORT=$(( $SPARK_WORKER_WEBUI_PORT + $WORKER_NUM - 1 ))

  "${SPARK_HOME}/sbin"/spark-daemon.sh start $CLASS $WORKER_NUM \
     --webui-port "$WEBUI_PORT" $PORT_FLAG $PORT_NUM $MASTER "$@"
}

if [ "$SPARK_WORKER_INSTANCES" = "" ]; then
  start_instance 1 "$@"
else
  for ((i=0; i<$SPARK_WORKER_INSTANCES; i++)); do
    start_instance $(( 1 + $i )) "$@"
  done
fi
```

# sbin/slaves.sh

```bash
#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Run a shell command on all slave hosts.
#
# Environment Variables
#
#   SPARK_SLAVES    File naming remote hosts.
#     Default is ${SPARK_CONF_DIR}/slaves.
#   SPARK_CONF_DIR  Alternate conf dir. Default is ${SPARK_HOME}/conf.
#   SPARK_SLAVE_SLEEP Seconds to sleep between spawning remote commands.
#   SPARK_SSH_OPTS Options passed to ssh when running remote commands.
##

usage="Usage: slaves.sh [--config <conf-dir>] command..."

# if no args specified, show usage
if [ $# -le 0 ]; then
  echo $usage
  exit 1
fi

if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

. "${SPARK_HOME}/sbin/spark-config.sh"

# If the slaves file is specified in the command line,
# then it takes precedence over the definition in
# spark-env.sh. Save it here.
if [ -f "$SPARK_SLAVES" ]; then
  HOSTLIST=`cat "$SPARK_SLAVES"`
fi

# Check if --config is passed as an argument. It is an optional parameter.
# Exit if the argument is not a directory.
if [ "$1" == "--config" ]
then
  shift
  conf_dir="$1"
  if [ ! -d "$conf_dir" ]
  then
    echo "ERROR : $conf_dir is not a directory"
    echo $usage
    exit 1
  else
    export SPARK_CONF_DIR="$conf_dir"
  fi
  shift
fi

. "${SPARK_HOME}/bin/load-spark-env.sh"

if [ "$HOSTLIST" = "" ]; then
  if [ "$SPARK_SLAVES" = "" ]; then
    if [ -f "${SPARK_CONF_DIR}/slaves" ]; then
      HOSTLIST=`cat "${SPARK_CONF_DIR}/slaves"`
    else
      HOSTLIST=localhost
    fi
  else
    HOSTLIST=`cat "${SPARK_SLAVES}"`
  fi
fi



# By default disable strict host key checking
if [ "$SPARK_SSH_OPTS" = "" ]; then
  SPARK_SSH_OPTS="-o StrictHostKeyChecking=no"
fi

for slave in `echo "$HOSTLIST"|sed  "s/#.*$//;/^$/d"`; do
  if [ -n "${SPARK_SSH_FOREGROUND}" ]; then
    ssh $SPARK_SSH_OPTS "$slave" $"${@// /\\ }" \
      2>&1 | sed "s/^/$slave: /"
  else
    ssh $SPARK_SSH_OPTS "$slave" $"${@// /\\ }" \
      2>&1 | sed "s/^/$slave: /" &
  fi
  if [ "$SPARK_SLAVE_SLEEP" != "" ]; then
    sleep $SPARK_SLAVE_SLEEP
  fi
done

wait
```

# Install networking tools in dev

```bash
apt install -y iproute2 inetutils-ping
apt-get install inetutils-ping
```

```bash
apt-get install gosu
apt-get install python3-pip
update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 2000

pip install apache-airflow
pip install 'apache-airflow[postgres]'
apt-get remove python3-pip
apt-get clean

# Dev
apt-get install python3-pipdeptree

apt-get install -y gosu
groupadd -r airflow --gid=1717
useradd -r -g airflow --uid=1717 --home-dir=/opt/airflow --shell=/bin/bash airflow
apt-get install -y python3-pip
update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 2000
pip install psycopg2-binary 'apache-airflow[postgres]'
mkdir /opt/airflow
chown -R airflow:airflow /opt/airflow


which pip3
pip install airflow
pip install apache-airflow
apt-get remove python3-pip
airflow 
apt-get autoremove
apt-get clean
apt-get install python3-pip
export AIRFLOW_HOME=/opt/airflow
apt-get install gosu
gosu nobody true
gosu --help
gosu nobody:root bash -c 'whoami && id'
godu 1000:1 id
gosu 1000:1 id
groupadd -r airflow --gid=1717
useradd -r -g airflow --uid=1717 --home-dir=/opt/airflow --shell=/bin/bash airflow
gosu airflow
history
su - airflow
ls /opt
mkdir /opt/airflow
chown -R airflow:airflow /opt/airflow
su - airflow
history

    1  echo $editor
    2  which editor
    3  which edit
    4  edit --help
    5  apt-get install vim
    6  vim doit.sh
    7  chmod 755 doit.sh 
    8  ./doit.sh 
    9  cat doit.sh 
   10  su - airflow
   11  apt install -y iproute2 inetutils-ping
   12  su - airflow
   13  history
   14  pip install psycopg2-binary
   15  su - airflow
   16  pip remove psycopg2
   17  pip uninstall psycopg2
   18  pip install psycopg2-binary
   19  pip help
   20  su - airflow
   21  history
```

```SQL
CREATE DATABASE airflow
  LC_COLLATE 'en_US.utf8'
  LC_CTYPE 'en_US.utf8'
;

CREATE USER airflow WITH
  ENCRYPTED PASSWORD 'airflow'
;

GRANT ALL PRIVILEGES
  ON airflow
  TO airflow
;


DROP TABLE alembic_version;
DROP TABLE chart;
DROP TABLE connection;
DROP TABLE dag;
DROP TABLE dag_pickle;
DROP TABLE dag_run;
DROP TABLE import_error;
DROP TABLE job;
DROP TABLE known_event;
DROP TABLE known_event_type;
DROP TABLE kube_resource_version;
DROP TABLE kube_worker_uuid;
DROP TABLE log;
DROP TABLE sla_miss;
DROP TABLE slot_pool;
DROP TABLE task_fail;
DROP TABLE task_instance;
DROP TABLE task_reschedule;
DROP TABLE users;
DROP TABLE variable;
DROP TABLE xcom;
```

```bash
chmod 600 /etc/sudoers
sed -i -e '/^\(root\s*ALL=(ALL:ALL).*\)/a airflow ALL=(ALL:ALL) NOPASSWD: ALL' /etc/sudoers
chmod 400 /etc/sudoers
ls -l /etc/sudoers
chmod 440 /etc/sudoers
ls -l /etc/sudoers
history
```

```bash
root@8cd202b56519:/opt/airflow# cat ~/.bashrc
# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

# You may uncomment the following lines if you want `ls' to be colorized:
# export LS_OPTIONS='--color=auto'
# eval "`dircolors`"
# alias ls='ls $LS_OPTIONS'
# alias ll='ls $LS_OPTIONS -l'
# alias l='ls $LS_OPTIONS -lA'
#
# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

root@8cd202b56519:/opt/airflow# cat ~/.profile
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n || true
```

export AIRFLOW_HOME=/opt/airflow
export POSTGRES_HOST=database
export POSTGRES_DB=airflow
export POSTGRES_USER=airflow
export POSTGRES_PASSWORD=airflow
export AIRFLOW__CORE__FERNET_KEY=uQ5Fz122Qu2yQH5PfdMrAjH0WIkgtx1df435T7GTGm4=



1. install airflow as root
2. Create entry point to check the database with psql scripts
3. if not loaded pgdump the airflow.pgsql to the airflow/airflow:ariflow database
4 cd to /opt/airflow
2. gosu to daemonize the web server
3. start the scheduler

```bash
cat 05_airflow_spark_image/Dockerfile | docker build --network=sparkcontainer_sparknet -t $(< 05_airflow_spark_image/NAME):$(< 05_airflow_spark_image/VERSION) -f- 05_airflow_spark_image/
```

```plain
                List of relations
 Schema |         Name          | Type  |  Owner  
--------+-----------------------+-------+---------
 public | alembic_version       | table | airflow
 public | chart                 | table | airflow
 public | connection            | table | airflow
 public | dag                   | table | airflow
 public | dag_pickle            | table | airflow
 public | dag_run               | table | airflow
 public | import_error          | table | airflow
 public | job                   | table | airflow
 public | known_event           | table | airflow
 public | known_event_type      | table | airflow
 public | kube_resource_version | table | airflow
 public | kube_worker_uuid      | table | airflow
 public | log                   | table | airflow
 public | sla_miss              | table | airflow
 public | slot_pool             | table | airflow
 public | task_fail             | table | airflow
 public | task_instance         | table | airflow
 public | task_reschedule       | table | airflow
 public | users                 | table | airflow
 public | variable              | table | airflow
 public | xcom                  | table | airflow
(21 rows)
```

```bash
root@0e121310c0d6:~# conda init --dry-run -vvv
```

```plain
DEBUG conda.gateways.logging:set_verbosity(231): verbosity set to 3
DEBUG conda.gateways.subprocess:subprocess_call(69): executing>> /opt/miniconda/bin/python --version
TRACE conda.gateways.subprocess:subprocess_call(87): $ /opt/miniconda/bin/python --version
==> cwd: /opt/miniconda <==
==> exit code: 0 <==
==> stdout <==
Python 3.7.3

==> stderr <==




/root/.bashrc
--- 

+++ 

@@ -16,3 +16,19 @@

 # alias rm='rm -i'
 # alias cp='cp -i'
 # alias mv='mv -i'
+
+# >>> conda initialize >>>
+# !! Contents within this block are managed by 'conda init' !!
+__conda_setup="$('/opt/miniconda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
+if [ $? -eq 0 ]; then
+    eval "$__conda_setup"
+else
+    if [ -f "/opt/miniconda/etc/profile.d/conda.sh" ]; then
+        . "/opt/miniconda/etc/profile.d/conda.sh"
+    else
+        export PATH="/opt/miniconda/bin:$PATH"
+    fi
+fi
+unset __conda_setup
+# <<< conda initialize <<<
+
no change     /opt/miniconda/condabin/conda
no change     /opt/miniconda/bin/conda
no change     /opt/miniconda/bin/conda-env
no change     /opt/miniconda/bin/activate
no change     /opt/miniconda/bin/deactivate
no change     /opt/miniconda/etc/profile.d/conda.sh
no change     /opt/miniconda/etc/fish/conf.d/conda.fish
no change     /opt/miniconda/shell/condabin/Conda.psm1
no change     /opt/miniconda/shell/condabin/conda-hook.ps1
no change     /opt/miniconda/lib/python3.7/site-packages/xontrib/conda.xsh
no change     /opt/miniconda/etc/profile.d/conda.csh
modified      /root/.bashrc

==> For changes to take effect, close and re-open your current shell. <==
```

```bash
root@0e121310c0d6:~# '/opt/miniconda/bin/conda' 'shell.bash' 'hook'
export CONDA_EXE='/opt/miniconda/bin/conda'
export _CE_M=''
export _CE_CONDA=''
export CONDA_PYTHON_EXE='/opt/miniconda/bin/python'

# Copyright (C) 2012 Anaconda, Inc
# SPDX-License-Identifier: BSD-3-Clause

__add_sys_prefix_to_path() {
    # In dev-mode CONDA_EXE is python.exe and on Windows
    # it is in a different relative location to condabin.
    if [ -n "${_CE_CONDA}" ] && [ -n "${WINDIR+x}" ]; then
        SYSP=$(\dirname "${CONDA_EXE}")
    else
        SYSP=$(\dirname "${CONDA_EXE}")
        SYSP=$(\dirname "${SYSP}")
    fi

    if [ -n "${WINDIR+x}" ]; then
        PATH="${SYSP}/bin:${PATH}"
        PATH="${SYSP}/Scripts:${PATH}"
        PATH="${SYSP}/Library/bin:${PATH}"
        PATH="${SYSP}/Library/usr/bin:${PATH}"
        PATH="${SYSP}/Library/mingw-w64/bin:${PATH}"
        PATH="${SYSP}:${PATH}"
    else
        PATH="${SYSP}/bin:${PATH}"
    fi
    \export PATH
}

__conda_hashr() {
    if [ -n "${ZSH_VERSION:+x}" ]; then
        \rehash
    elif [ -n "${POSH_VERSION:+x}" ]; then
        :  # pass
    else
        \hash -r
    fi
}

__conda_activate() {
    if [ -n "${CONDA_PS1_BACKUP:+x}" ]; then
        # Handle transition from shell activated with conda <= 4.3 to a subsequent activation
        # after conda updated to >= 4.4. See issue #6173.
        PS1="$CONDA_PS1_BACKUP"
        \unset CONDA_PS1_BACKUP
    fi

    \local cmd="$1"
    shift
    \local ask_conda
    OLDPATH="${PATH}"
    __add_sys_prefix_to_path
    ask_conda="$(PS1="$PS1" "$CONDA_EXE" $_CE_M $_CE_CONDA shell.posix "$cmd" "$@")" || \return $?
    PATH="${OLDPATH}"
    \eval "$ask_conda"
    __conda_hashr
}

__conda_reactivate() {
    \local ask_conda
    OLDPATH="${PATH}"
    __add_sys_prefix_to_path
    ask_conda="$(PS1="$PS1" "$CONDA_EXE" $_CE_M $_CE_CONDA shell.posix reactivate)" || \return $?
    PATH="${OLDPATH}"
    \eval "$ask_conda"
    __conda_hashr
}

conda() {
    if [ "$#" -lt 1 ]; then
        "$CONDA_EXE" $_CE_M $_CE_CONDA
    else
        \local cmd="$1"
        shift
        case "$cmd" in
            activate|deactivate)
                __conda_activate "$cmd" "$@"
                ;;
            install|update|upgrade|remove|uninstall)
                OLDPATH="${PATH}"
                __add_sys_prefix_to_path
                "$CONDA_EXE" $_CE_M $_CE_CONDA "$cmd" "$@"
                \local t1=$?
                PATH="${OLDPATH}"
                if [ $t1 = 0 ]; then
                    __conda_reactivate
                else
                    return $t1
                fi
                ;;
            *)
                OLDPATH="${PATH}"
                __add_sys_prefix_to_path
                "$CONDA_EXE" $_CE_M $_CE_CONDA "$cmd" "$@"
                \local t1=$?
                PATH="${OLDPATH}"
                return $t1
                ;;
        esac
    fi
}

if [ -z "${CONDA_SHLVL+x}" ]; then
    \export CONDA_SHLVL=0
    # In dev-mode CONDA_EXE is python.exe and on Windows
    # it is in a different relative location to condabin.
    if [ -n "${_CE_CONDA+x}" ] && [ -n "${WINDIR+x}" ]; then
        PATH="$(\dirname "$CONDA_EXE")/condabin${PATH:+":${PATH}"}"
    else
        PATH="$(\dirname "$(\dirname "$CONDA_EXE")")/condabin${PATH:+":${PATH}"}"
    fi
    \export PATH

    # We're not allowing PS1 to be unbound. It must at least be set.
    # However, we're not exporting it, which can cause problems when starting a second shell
    # via a first shell (i.e. starting zsh from bash).
    if [ -z "${PS1+x}" ]; then
        PS1=
    fi
fi


conda activate base
conda install conda==4.7.12
conda clean --all
```

# new anaconda image
```docker
ENV CONDA_PROJECT=sc-jail-project
```

```bash
conda create --yes --name ${CONDA_PROJECT} python=3.7.3 \
&& conda activate ${CONDA_PROJECT} \
&& conda config --env --append channels conda-forge \
&& conda config --env --set channel_priority flexible \
&& conda install --yes --file=requirements.txt
```