#!/usr/bin/with-contenv bashio

SEATABLE_DIR="/data/seatable"

# ==============================================================================
# --- Konfiguration & Geheimnisse verwalten ---
# ==============================================================================
bashio::log.info "Konfiguration wird geladen..."

# --- 1. Hostname automatisch ermitteln ---
HOSTNAME=$(bashio::network.ipv4_address)
bashio::log.info "SeaTable Hostname wird auf '${HOSTNAME}' gesetzt."
export SEATABLE_SERVER_HOSTNAME=$HOSTNAME

# --- 2. MariaDB-Passwort aus der Konfiguration lesen ---
DB_PASSWORD=$(bashio::config 'mariadb_password')
if [ -z "$DB_PASSWORD" ]; then
    bashio::log.fatal "Das MariaDB-Passwort ist nicht gesetzt! Bitte gehe zum 'Konfiguration'-Tab des Add-ons und setze ein Passwort."
    bashio::exit.nok
fi
export MARIADB_PASSWORD=$DB_PASSWORD

# --- 3. Redis-Passwort automatisch generieren/laden ---
REDIS_PW_FILE="/data/redis_password.txt"
if [ ! -f "$REDIS_PW_FILE" ]; then
    bashio::log.info "Generiere ein neues, zufälliges Passwort für Redis..."
    REDIS_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
    echo "$REDIS_PASSWORD" > "$REDIS_PW_FILE"
else
    REDIS_PASSWORD=$(cat "$REDIS_PW_FILE")
fi
export REDIS_PASSWORD=$REDIS_PASSWORD

# ==============================================================================
# --- Installation (falls nötig) ---
# ==============================================================================
if [ ! -f "${SEATABLE_DIR}/seatable-server.yml" ]; then
    bashio::log.info "Keine SeaTable-Installation gefunden. Lade die neueste Version herunter..."
    mkdir -p "${SEATABLE_DIR}"
    cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das Verzeichnis wechseln."

    wget -O seatable-compose.tar.gz "https://github.com/seatable/seatable-release/releases/latest/download/seatable-compose.tar.gz"
    tar -xzf seatable-compose.tar.gz
    rm seatable-compose.tar.gz
    bashio::log.info "Download und Entpacken abgeschlossen."
fi

# ==============================================================================
# --- SeaTable Start ---
# ==============================================================================
bashio::log.info "Starte den SeaTable Server..."
cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das SeaTable-Verzeichnis wechseln."

# --- Docker Compose ausführen ---
# Die Umgebungsvariablen werden automatisch an Docker Compose übergeben
docker compose -f seatable-server.yml up -d

bashio::log.info "SeaTable-Container wurden gestartet. ✅"
bashio::log.info "Der erste Start kann einige Minuten dauern. Bitte habe etwas Geduld."
bashio::log.info "Du solltest SeaTable jetzt unter http://${HOSTNAME}:$(bashio::config 'http_port') erreichen können."

# Endlosschleife
while true; do
  sleep 3600
done
