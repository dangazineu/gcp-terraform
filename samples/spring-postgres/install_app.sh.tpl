#! /bin/bash

set -e

sleep 5

sudo apt update
sudo apt install -y wget apt-transport-https
sudo mkdir -p /etc/apt/keyrings
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc

echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb \
  $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt update
sudo apt install -y temurin-17-jdk
echo "Downloading application from ${STAGED_BINARY}"
sudo mkdir -p /var/app
sudo gsutil cp "${STAGED_BINARY}" /var/app/app.jar

sudo tee /var/app/start > /dev/null <<  EOSTARTSCRIPT
#! /bin/bash
set -e
export SPRING_DATASOURCE_USERNAME=${DB_USERNAME}
export SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
export SPRING_CLOUD_GCP_SQL_DATABASE_NAME=${DB_NAME}
export SPRING_CLOUD_GCP_SQL_INSTANCE_CONNECTION_NAME=${DB_CONNECTION_NAME}
export SPRING_CLOUD_GCP_PROJECT_ID=${DB_PROJECT_ID}

java -jar /var/app/app.jar
EOSTARTSCRIPT

sudo chmod +x /var/app/start

sudo tee /etc/systemd/system/app.service > /dev/null << EOSERVICECONFIG
      [Unit]
      Description="Spring Application Service"
      After=network.target
      [Service]
      ExecStart=/var/app/start
      [Install]
      WantedBy=multi-user.target
EOSERVICECONFIG

echo "Starting application"
sudo systemctl enable app
sudo systemctl start app
sudo systemctl status app