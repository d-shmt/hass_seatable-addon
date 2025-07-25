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
    bashio::exit.nok "Wichtige Konfigurationswerte (DB-Passwort, Admin-E-Mail oder Admin-Passwort) fehlen. Bitte im 'Konfiguration'-Tab ausfüllen."
fi

# --- Ermittle oder generiere systemische Werte ---
HOSTNAME=$(bashio::network.ipv4_address || ip route | awk '/default/ { print $3 }')
TIME_ZONE=$(bashio::info.timezone)

# Redis-Passwort
REDIS_PW_FILE="/data/redis_password.txt"
if [ ! -f "$REDIS_PW_FILE" ]; then
    REDIS_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32); echo "$REDIS_PASSWORD" > "$REDIS_PW_FILE"
else
    REDIS_PASSWORD=$(cat "$REDIS_PW_FILE")
fi

# JWT Private Key
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

# --- Erstelle die .env Datei für Docker Compose (NEUE, ZUVERLÄSSIGE METHODE) ---
bashio::log.info "Schreibe Konfiguration in .env Datei..."
cat > .env << EOF
TIME_ZONE=${TIME_ZONE}
SEATABLE_SERVER_HOSTNAME=${HOSTNAME}
MARIADB_PASSWORD=${DB_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
JWT_PRIVATE_KEY=${JWT_PRIVATE_KEY}
SEATABLE_ADMIN_EMAIL=${ADMIN_EMAIL}
SEATABLE_ADMIN_PW=${ADMIN_PW}
EOF

# --- Passe Ports in der docker-compose Datei an ---
sed -i "s/\"80:80\"/\"${HTTP_PORT}:80\"/g" seatable-server.yml
sed -i "s/\"443:443\"/\"${HTTPS_PORT}:443\"/g" seatable-server.yml

# ==============================================================================
# SECTION 4: SEATABLE STARTEN
# ==============================================================================
bashio::log.info "Starte SeaTable-Dienste..."
docker compose -f seatable-server.yml up -d

bashio::log.info "SeaTable wurde erfolgreich gestartet! ✅"
bashio::log.info "Die Weboberfläche sollte unter http://${HOSTNAME}:${HTTP_PORT} erreichbar sein."

# ==============================================================================
# SECTION 5: ADD-ON AM LEBEN HALTEN
# ==============================================================================
while true; do sleep 3600; done
