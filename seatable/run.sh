#!/usr/bin/with-contenv bashio

# Download und Ausführen des SeaTable Installers
if [ ! -f "/opt/seatable-server-latest/seatable.sh" ]; then
    bashio::log.info "Downloading SeaTable..."
    cd /opt
    wget -O seatable-server-latest.tar.gz "https://download.seatable.io/seatable-server-latest-de.tar.gz"
    tar -xzf seatable-server-latest.tar.gz
fi

# Starte SeaTable Server
bashio::log.info "Starting SeaTable Server..."
cd /opt/seatable-server-latest
./seatable.sh start
