
if [ $(id -u) != 0 ]; then
  echo "Run script from user root. Your user is ${USER}"
  exit 1
fi

function install_docker(){
   apt update -qq && apt install -yqq ca-certificates curl gnupg lsb-release
   mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
   apt update -yqq && apt install -yqq docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

MINIMA_PORTS='9001-9004'
MINIMA_CONTAINER_NAME='minima-node'
MINIMA_MDS_PASSWORD=''
DATA_DIR=/opt/data/${MINIMA_CONTAINER_NAME}
CONF_DIR=/opt/conf/${MINIMA_CONTAINER_NAME}


while ! [[ "${MINIMA_MDS_PASSWORD}" =~ [a-z0-9]{5} ]];
do
  read -p "Enter and remember your minima wallet password, 5 symbols - only numbers and small letters]: " MINIMA_MDS_PASSWORD
done

echo "Setting up minima container"
mkdir -p $DATA_DIR
mkdir -p $CONF_DIR


if ! command -v docker-compose &> /dev/null; then
  echo "Installing docker..."
  install_docker
fi


mkdir -p $DATA_DIR
mkdir -p $CONF_DIR


echo "version: '3'

services:
  ${MINIMA_CONTAINER_NAME}:
    image: minimaglobal/minima:latest
    container_name: ${MINIMA_CONTAINER_NAME}
    environment:
      minima_mdspassword: ${MINIMA_MDS_PASSWORD}
      minima_server: 'true'
    ports:
      - ${MINIMA_PORTS}:${MINIMA_PORTS}
    logging:
      driver: 'syslog'
    restart: unless-stopped
    volumes:
      - ${DATA_DIR}:/home/minima/data

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    environment:
      WATCHTOWER_CLEANUP: 'true'
      WATCHTOWER_TIMEOUT: '60s'
    logging:
      driver: 'syslog'
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock" > ${CONF_DIR}/docker-compose.yml

cd ${CONF_DIR}
docker-compose up -d


echo "Your data directory for container minima-node: ${DATA_DIR}"
echo "Docker compose config file can be found in: ${CONF_DIR}"
echo "Command for restart container: docker restart ${MINIMA_CONTAINER_NAME}"
