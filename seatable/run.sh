#!/usr/bin/with-contenv bashio

# ==============================================================================
# SECTION 1: KONFIGURATION & GEHEIMNISSE VERWALTEN
# ==============================================================================
bashio::log.info "Lade Konfiguration und richte Umgebung ein..."

# Das Datenverzeichnis, damit deine SeaTable-Daten persistent gespeichert werden
SEATABLE_DIR="/data/seatable"

# --- Hostname ermitteln (Robuste Methode) ---
# Versucht zuerst die offizielle HA-API. Wenn das fehlschlägt, nutzt es die Fallback-Methode.
HOSTNAME=$(bashio::network.ipv4_address || ip route | awk '/default/ { print $3 }')
if [ -z "$HOSTNAME" ]; then
    bashio::log.fatal "Konnte die Host-IP-Adresse nicht automatisch ermitteln. Breche ab."
    bashio::exit.nok
fi
export SEATABLE_SERVER_HOSTNAME=$HOSTNAME
bashio::log.info "Hostname für SeaTable auf '${HOSTNAME}' gesetzt."

# --- MariaDB-Passwort aus der Konfiguration lesen ---
DB_PASSWORD=$(bashio::config 'mariadb_password')
if [ -z "$DB_PASSWORD" ]; then
    bashio::log.fatal "Das MariaDB-Passwort ist nicht gesetzt! Bitte im 'Konfiguration'-Tab ein Passwort festlegen."
    bashio::exit.nok
fi
export MARIADB_PASSWORD=$DB_PASSWORD

# --- Redis-Passwort automatisch generieren und speichern ---
# Dies ist ein internes Passwort, das der Benutzer nicht kennen muss.
REDIS_PW_FILE="/data/redis_password.txt"
if [ ! -f "$REDIS_PW_FILE" ]; then
    bashio::log.info "Generiere ein neues, sicheres Passwort für Redis..."
    REDIS_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
    echo "$REDIS_PASSWORD" > "$REDIS_PW_FILE"
else
    REDIS_PASSWORD=$(cat "$REDIS_PW_FILE")
fi
export REDIS_PASSWORD=$REDIS_PASSWORD


# ==============================================================================
# SECTION 2: SEATABLE INSTALLATION (falls noch nicht vorhanden)
# ==============================================================================
if [ ! -f "${SEATABLE_DIR}/seatable-server.yml" ]; then
    bashio::log.info "Keine SeaTable-Installation gefunden. Lade die neueste Version herunter..."
    mkdir -p "${SEATABLE_DIR}"
    cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das Datenverzeichnis wechseln."

    # Download und Entpacken
    wget -O seatable-compose.tar.gz "https://github.com/seatable/seatable-release/releases/latest/download/seatable-compose.tar.gz"
    tar -xzf seatable-compose.tar.gz
    rm seatable-compose.tar.gz
    bashio::log.info "Download und Entpacken erfolgreich."
fi


# ==============================================================================
# SECTION 3: SEATABLE STARTEN
# ==============================================================================
bashio::log.info "Bereite den Start von SeaTable vor..."
cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das SeaTable-Verzeichnis wechseln."

# --- Konfiguration zur Laufzeit anpassen ---
HTTP_PORT=$(bashio::config 'http_port')
HTTPS_PORT=$(bashio::config 'https_port')
bashio::log.info "Passe Ports an: HTTP=${HTTP_PORT}, HTTPS=${HTTPS_PORT}"

# Ersetzt die Standard-Ports in der SeaTable-Konfigurationsdatei mit den Werten aus der Add-on-Konfiguration
sed -i "s/\"80:80\"/\"${HTTP_PORT}:80\"/g" seatable-server.yml
sed -i "s/\"443:443\"/\"${HTTPS_PORT}:443\"/g" seatable-server.yml

# --- SeaTable via Docker Compose starten ---
bashio::log.info "Starte SeaTable-Dienste... Dies kann einen Moment dauern."
docker compose -f seatable-server.yml up -d

bashio::log.info "SeaTable wurde erfolgreich gestartet! ✅"
bashio::log.info "Die Weboberfläche sollte unter http://${HOSTNAME}:${HTTP_PORT} erreichbar sein."


# ==============================================================================
# SECTION 4: ADD-ON AM LEBEN HALTEN
# ==============================================================================
while true; do
  sleep 3600
done
