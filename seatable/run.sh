#!/usr/bin/with-contenv bashio

# ==============================================================================
# SECTION 1: KONFIGURATION & GEHEIMNISSE VERWALTEN
# ==============================================================================
bashio::log.info "Lade Konfiguration und richte Umgebung ein..."

SEATABLE_DIR="/data/seatable"

# --- 1. Hostname ermitteln ---
HOSTNAME=$(bashio::network.ipv4_address || ip route | awk '/default/ { print $3 }')
if [ -z "$HOSTNAME" ]; then bashio::exit.nok "Konnte die Host-IP-Adresse nicht automatisch ermitteln."; fi
export SEATABLE_SERVER_HOSTNAME=$HOSTNAME
bashio::log.info "Hostname für SeaTable auf '${HOSTNAME}' gesetzt."

# --- 2. Zeitzone ermitteln (NEU) ---
export TIME_ZONE=$(bashio::info.timezone)
bashio::log.info "Zeitzone auf '${TIME_ZONE}' gesetzt."

# --- 3. MariaDB-Passwort ---
DB_PASSWORD=$(bashio::config 'mariadb_password')
if [ -z "$DB_PASSWORD" ]; then bashio::exit.nok "Das MariaDB-Passwort ist nicht gesetzt!"; fi
export MARIADB_PASSWORD=$DB_PASSWORD

# --- 4. Redis-Passwort ---
REDIS_PW_FILE="/data/redis_password.txt"
if [ ! -f "$REDIS_PW_FILE" ]; then
    REDIS_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32); echo "$REDIS_PASSWORD" > "$REDIS_PW_FILE"
else
    REDIS_PASSWORD=$(cat "$REDIS_PW_FILE")
fi
export REDIS_PASSWORD=$REDIS_PASSWORD

# --- 5. JWT Private Key ---
JWT_KEY_FILE="/data/jwt_private_key.txt"
if [ ! -f "$JWT_KEY_FILE" ]; then
    JWT_PRIVATE_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 40); echo "$JWT_PRIVATE_KEY" > "$JWT_KEY_FILE"
else
    JWT_PRIVATE_KEY=$(cat "$JWT_KEY_FILE")
fi
export JWT_PRIVATE_KEY=$JWT_PRIVATE_KEY

# --- 6. SeaTable Admin-Konto ---
ADMIN_EMAIL=$(bashio::config 'seatable_admin_email')
ADMIN_PW=$(bashio::config 'seatable_admin_pw')
if [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PW" ]; then
    bashio::exit.nok "Admin-E-Mail oder Admin-Passwort für SeaTable sind nicht gesetzt! Bitte im 'Konfiguration'-Tab festlegen."
fi
export SEATABLE_ADMIN_EMAIL=$ADMIN_EMAIL
export SEATABLE_ADMIN_PW=$ADMIN_PW

# ==============================================================================
# SECTION 2: SEATABLE INSTALLATION
# ==============================================================================
if [ ! -f "${SEATABLE_DIR}/seatable-server.yml" ]; then
    bashio::log.info "Keine SeaTable-Installation gefunden. Lade neueste Version..."
    mkdir -p "${SEATABLE_DIR}"; cd "${SEATABLE_DIR}" || bashio::exit.nok
    wget -O seatable-compose.tar.gz "https://github.com/seatable/seatable-release/releases/latest/download/seatable-compose.tar.gz"
    tar -xzf seatable-compose.tar.gz; rm seatable-compose.tar.gz
fi

# ==============================================================================
# SECTION 3: SEATABLE STARTEN
# ==============================================================================
bashio::log.info "Bereite den Start von SeaTable vor..."
cd "${SEATABLE_DIR}" || bashio::exit.nok

HTTP_PORT=$(bashio::config 'http_port')
HTTPS_PORT=$(bashio::config 'https_port')
sed -i "s/\"80:80\"/\"${HTTP_PORT}:80\"/g" seatable-server.yml
sed -i "s/\"443:443\"/\"${HTTPS_PORT}:443\"/g" seatable-server.yml

bashio::log.info "Starte SeaTable-Dienste..."
docker compose -f seatable-server.yml up -d

bashio::log.info "SeaTable wurde erfolgreich gestartet! ✅"
bashio::log.info "Die Weboberfläche sollte unter http://${HOSTNAME}:${HTTP_PORT} erreichbar sein."

# ==============================================================================
# SECTION 4: ADD-ON AM LEBEN HALTEN
# ==============================================================================
while true; do sleep 3600; done
