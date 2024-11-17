#!/bin/bash

# Dowload on $HOME

# HOME=`eval echo ~$USER`
REPO_HOME="$HOME/fsm-data-pipeline"
# REPO_HOME="/home/skalogerakis/Documents/Workspace/fsm-data-pipeline"
DOWNLOADS="${HOME}/DOWNLOADS"
KAFKA_HOME="${HOME}/kafka_2.12-3.3.2"
FLINK_HOME="${HOME}/flink"

USAGE_MSG="$0 <install, stop, start>"

PARALLELISM=1

##################### HELPING UTILITIES #####################

function help() {
    echo "Syntax: $0 install| start [-p parallelim] [-i inteval1] [-j interval2] | stop"
    echo "options:"
    echo "install   Intall the necessary software stack (utilities, processing platforms)"
    echo "build     Build application from source code"
    echo "start     Deploy and start the processes for fetching and analysing data"
    echo "      optional start arguments:"
    echo "      -p <number>  Flink parallelism (Default: 1)"
    echo "      -i <number>  Interval 1 (Default 38)"
    echo "      -j <number>  Interval 2 (Default 100)"
    echo "      -c <minutes> Checkpointing interval in minutes (Default: no checkpointing)" 
    echo "      -q <number>  Specify the reported queries. 1 for Q1, 2 for Q2. (Default report both queries)"
    echo "stop      Stops processing and processing platform"
    echo ""
    echo "e.g. ./manage.sh start -p 2 -i 50 -j 90 -q 1"
}


function install_utilities() {
    echo "$(date +'%d/%m/%y %T') Install necessary dependencies. This may take a while. Please wait"

    sudo apt-get update > /dev/null 2>&1
    sudo apt-get install -y htop build-essential openjdk-8-jdk maven git > /dev/null 2>&1
    sudo timedatectl set-timezone Europe/Athens
	cd ${HOME}
    mkdir -p $DOWNLOADS

    sleep 3

    install_docker
    
}

function install_docker() {
    echo "$(date +'%d/%m/%y %T') Start installing docker"

    cd ${DOWNLOADS}

    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common > /dev/null 2>&1

    sleep 3

    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # Add Docker repository
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # Update package list again
    sudo apt update > /dev/null 2>&1

    # Install Docker
    sudo apt install -y docker-ce > /dev/null 2>&1

    sleep 3
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker

    # Add your user to the docker group (optional, to run Docker without sudo)
    sudo usermod -aG docker $USER

    # Install Docker Compose (optional)
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Test Docker installation
    docker --version

    # Test Docker Compose installation
    docker-compose --version
}


function visit_job_start() {
    echo "$(date +'%d/%m/%y %T') Start flink job"
    APP_BIN="${REPO_HOME}/visit-pipeline/target/visit-pipeline-0.1.jar"
    # ${FLINK_HOME}/bin/flink run -d -p ${PARALLELISM} ${APP_BIN}
    ${FLINK_HOME}/bin/flink run -d ${APP_BIN}
}

function network_job_start() {
    echo "$(date +'%d/%m/%y %T') Start flink job"
    APP_BIN="${REPO_HOME}/network-pipeline/target/network-pipeline-0.1.jar"
    ${FLINK_HOME}/bin/flink run -d ${APP_BIN}
}

function application_build() {
    echo "$(date +'%d/%m/%y %T') Build binaries"

    DATA_LOADER_HOME="${REPO_HOME}/visit-pipeline"
    cd ${DATA_LOADER_HOME}
    mvn clean package

    DATA_LOADER_HOME="${REPO_HOME}/network-pipeline"
    cd ${DATA_LOADER_HOME}
    mvn clean package
}

##################### FLINK UTILITIES #####################

function flink_install() {
    echo "$(date +'%d/%m/%y %T') Install Flink"
    cd ${DOWNLOADS}
    wget --quiet https://archive.apache.org/dist/flink/flink-1.14.3/flink-1.14.3-bin-scala_2.12.tgz
    tar -zxvf flink-1.14.3-bin-scala_2.12.tgz > /dev/null 2>&1

    cd ${HOME}
    ln -sf ${DOWNLOADS}/flink-1.14.3 ${FLINK_HOME}

    cd ${FLINK_HOME}
    mkdir -p "./plugins/s3-fs-hadoop"
    cp ./opt/flink-s3-fs-hadoop-1.14.3.jar ./plugins/s3-fs-hadoop/

    flink_config
}

# FIXME ideally add config for the whole cluster
function flink_config() {
    # sed -i -e "/taskmanager\.memory\.process\.size:/ s/: .*/: 3000m/" ${FLINK_HOME}/conf/flink-conf.yaml
    sed -i -e "/taskmanager\.numberOfTaskSlots:/ s/: .*/: ${PARALLELISM}/" ${FLINK_HOME}/conf/flink-conf.yaml 
}

function flink_cluster_start() {
    echo "Starting Flink Cluster "

    cd ${FLINK_HOME}/bin && ./start-cluster.sh $1
}

function flink_cluster_stop() {
    echo "Stopping Flink Cluster "

    cd ${FLINK_HOME}/bin && ./stop-cluster.sh $1
}

function flink_clean() {
    echo "$(date +'%d/%m/%y %T') Flink clean logs"
    rm -rf ${FLINK_HOME}/log/*
}

##################### DOCKER UTILITIES #####################

function docker-cmp-activate() {
    echo "Activating Docker Compose"
    cd ${REPO_HOME}
    docker-compose -f docker-compose.yml up -d
}

function docker-cmp-close() {
    echo "Closing Docker Compose"

    cd ${REPO_HOME}
    docker-compose -f docker-compose.yml down
}



# Check num of arguments
if [ $# -lt 1 ]; then
    echo "Wrong arguments!"
    echo $USAGE_MSG
    help
  exit 1
fi

ACTION=$1

case "$ACTION" in
    install)
    	install_utilities
	    # kafka_install
    	flink_install
        exit
	    ;;
    build)
        application_build
        exit
        ;;
    visit)    # process runs the processing app, must have already executed the ingest and ingest-stop
        shift   # ignore "start" parameter and parse next params
        sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches "
        docker-cmp-activate
        sleep 5
        #kafka_create_q1_q2
        flink_cluster_start
        sleep 3
        visit_job_start
        exit
        ;;
    network)    # process runs the processing app, must have already executed the ingest and ingest-stop
        shift   # ignore "start" parameter and parse next params
        sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches "
        docker-cmp-activate
        sleep 5
        #kafka_create_q1_q2
        flink_cluster_start
        sleep 3
        network_job_start
        exit
        ;;
    stop)
        # docker-cmp-close
        sleep 3
        flink_cluster_stop
        #kafka_delete_q1_q2
        sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches "
        flink_clean
        exit
        ;;   
    *)
        echo "Unknown argument $ACTION"
        echo ""
        help
        exit
        ;;
esac

