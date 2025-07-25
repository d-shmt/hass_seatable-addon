#!/usr/bin/with-contenv bashio

# ==============================================================================
# SECTION 1: KONFIGURATION & GEHEIMNISSE VERWALTEN
# ==============================================================================
bashio::log.info "Lade Konfiguration und richte Umgebung ein..."
SEATABLE_DIR="/data/seatable"

# --- Lies alle Werte aus der Add-on Konfiguration ---
HTTP_PORT=$(bashio::config 'http_port')
HTTPS_PORT=$(bashio::config 'https_port')
DB_PASSWORD=$(bashio::config 'mariadb_password')
ADMIN_EMAIL=$(bashio::config 'seatable_admin_email')
ADMIN_PW=$(bashio::config 'seatable_admin_pw')

# --- Validiere die Benutzereingaben ---
if [ -z "$DB_PASSWORD" ] || [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PW" ]; then
    bashio::exit.nok "Wichtige Konfigurationswerte fehlen. Bitte im 'Konfiguration'-Tab ausfüllen."
fi

# --- Ermittle oder generiere systemische Werte ---
HOSTNAME=$(ip route | awk '/default/ { print $3 }')
TIME_ZONE=$(bashio::info.timezone)
REDIS_PW_FILE="/data/redis_password.txt"
if [ ! -f "$REDIS_PW_FILE" ]; then
    REDIS_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32); echo "$REDIS_PASSWORD" > "$REDIS_PW_FILE"
else
    REDIS_PASSWORD=$(cat "$REDIS_PW_FILE")
fi
JWT_KEY_FILE="/data/jwt_private_key.txt"
if [ ! -f "$JWT_KEY_FILE" ]; then
    JWT_PRIVATE_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 40); echo "$JWT_PRIVATE_KEY" > "$JWT_KEY_FILE"
else
    JWT_PRIVATE_KEY=$(cat "$JWT_KEY_FILE")
fi

# ==============================================================================
# SECTION 2: SEATABLE INSTALLATION (falls nötig)
# ==============================================================================
if [ ! -f "${SEATABLE_DIR}/seatable-server.yml" ]; then
    bashio::log.info "Keine SeaTable-Installation gefunden. Lade neueste Version..."
    mkdir -p "${SEATABLE_DIR}"; cd "${SEATABLE_DIR}" || bashio::exit.nok
    wget -O seatable-compose.tar.gz "https://github.com/seatable/seatable-release/releases/latest/download/seatable-compose.tar.gz"
    tar -xzf seatable-compose.tar.gz; rm seatable-compose.tar.gz
fi

# ==============================================================================
# SECTION 3: KONFIGURATION ANWENDEN
# ==============================================================================
cd "${SEATABLE_DIR}" || bashio::exit.nok

bashio::log.info "Schreibe Konfiguration in .env Datei..."
cat > .env << EOF
TIME_ZONE=${TIME_ZONE}
SEATABLE_SERVER_HOSTNAME=${HOSTNAME}
MARIADB_PASSWORD=${DB_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
JWT_PRIVATE_KEY=${JWT_PRIVATE_KEY}
SEATABLE_ADMIN_EMAIL=${ADMIN_EMAIL}
SEATABLE_ADMIN_PASSWORD=${ADMIN_PW}
EOF

sed -i "s/\"80:80\"/\"${HTTP_PORT}:80\"/g" seatable-server.yml
sed -i "s/\"443:443\"/\"${HTTPS_PORT}:443\"/g" seatable-server.yml

# ==============================================================================
# SECTION 4: SEATABLE STARTEN
# ==============================================================================
bashio::log.info "Starte SeaTable-Dienste..."
docker compose -f seatable-server.yml up -d

bashio::log.info "Befehl zum Starten von SeaTable wurde abgesetzt. ✅"

while true; do sleep 3600; done
