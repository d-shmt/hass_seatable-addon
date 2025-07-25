#!/usr/bin/with-contenv bashio

SEATABLE_DIR="/data/seatable"

# --- Konfiguration auslesen ---
HTTP_PORT=$(bashio::config 'http_port')
HTTPS_PORT=$(bashio::config 'https_port')
DB_PASSWORD=$(bashio::config 'mariadb_password')

# --- Passwort validieren ---
if [ -z "$DB_PASSWORD" ]; then
    bashio::log.fatal "Das MariaDB-Passwort ist nicht gesetzt! Bitte gehe zum 'Konfiguration'-Tab und setze ein Passwort."
    bashio::exit.nok
fi
export MARIADB_PASSWORD=$DB_PASSWORD

# --- Installation (falls nötig) ---
if [ ! -f "${SEATABLE_DIR}/seatable-server.yml" ]; then
    bashio::log.info "Keine SeaTable-Installation gefunden. Lade die neueste Version herunter..."
    mkdir -p "${SEATABLE_DIR}"
    cd "${SEATABLE_DIR}" || bashio::exit.nok
    
    wget -O seatable-compose.tar.gz "https://github.com/seatable/seatable-release/releases/latest/download/seatable-compose.tar.gz"
    tar -xzf seatable-compose.tar.gz
    rm seatable-compose.tar.gz
    bashio::log.info "Download und Entpacken abgeschlossen."
fi

# --- SeaTable Start ---
bashio::log.info "Starte den SeaTable Server..."
cd "${SEATABLE_DIR}" || bashio::exit.nok

# --- Ports dynamisch anpassen ---
bashio::log.info "Passe Ports an: HTTP=${HTTP_PORT}, HTTPS=${HTTPS_PORT}"
# Ersetzt die Standard-Ports in der SeaTable-Konfigurationsdatei
sed -i "s/\"80:80\"/\"${HTTP_PORT}:80\"/g" seatable-server.yml
sed -i "s/\"443:443\"/\"${HTTPS_PORT}:443\"/g" seatable-server.yml

# --- Docker Compose ausführen ---
docker compose -f seatable-server.yml up -d

bashio::log.info "SeaTable-Container wurden gestartet."

# Endlosschleife
while true; do
  sleep 3600
done
