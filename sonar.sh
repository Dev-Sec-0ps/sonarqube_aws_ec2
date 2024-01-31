#!/bin/bash

# Update package lists and upgrade installed packages
sudo apt update && sudo apt upgrade -y

# Install Python 3 and pip
sudo apt install -y python3 python3-pip

# Install Docker Compose
python3 -m pip install docker-compose

# Add the current user to the docker group
sudo usermod -aG docker $USER

# Log in to this group (this might require logging out and logging back in, or using 'newgrp' command)
newgrp docker

# Create Docker Compose file
cat > ./docker-compose.yml <<-TEMPLATE
version: "3"

services:
  sonarqube:
    container_name: sonarqube
    image: sonarqube:10.2.1-community
    restart: always
    ports:
      - "9000:9000"
    environment:
      - SONAR_JDBC_URL=jdbc:postgresql://sonarqube-db:5432/sonar
      - SONAR_JDBC_USERNAME=username
      - SONAR_JDBC_PASSWORD=password
    volumes:
      - sonarqube-conf:/opt/sonarqube/conf
      - sonarqube-data:/opt/sonarqube/data
      - sonarqube-extensions:/opt/sonarqube/extensions
    depends_on:
      - sonarqube-db
    networks:
      - sonarqube

  sonarqube-db:
    container_name: sonarqube-db
    image: postgres:13.8
    restart: always
    environment:
      - POSTGRES_USER=username
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=sonar
    volumes:
      - postgresql-root:/var/lib/postgresql
      - postgresql-data:/var/lib/postgresql/data
      - ./backup_sonar_db:/backup_sonar_db/
    networks:
      - sonarqube

networks:
  sonarqube:
    driver: bridge

volumes:
  sonarqube-conf:
  sonarqube-data:
  sonarqube-extensions:
  postgresql-root:
  postgresql-data:
TEMPLATE

cat > /etc/systemd/system/custom_service.service <<-TEMPLATE
[Unit]
Description=docker service
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/docker-compose -f ./docker-compose.yml up
Restart=on-failure
[Install]
WantedBy=multi-user.target
TEMPLATE

#start our new service 
systemctl start custom_service

#start our new service on start up
systemctl enable custom_service

# Install Docker via pip
python3 -m pip install docker==6.1.3

# Verify Docker and Docker Compose installation
docker --version && docker-compose --version
