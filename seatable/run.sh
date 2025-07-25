#!/usr/bin/with-contenv bashio

# Daten im persistenten /data-Verzeichnis speichern
SEATABLE_DIR="/data/seatable"

# Passwort aus der Konfiguration lesen
DB_PASSWORD=$(bashio::config 'mariadb_password')

# Sicherstellen, dass ein Passwort gesetzt wurde
if [ -z "$DB_PASSWORD" ]; then
    bashio::log.fatal "Das MariaDB-Passwort ist nicht gesetzt! Bitte gehe zum 'Konfiguration'-Tab des Add-ons und setze ein sicheres Passwort."
    bashio::exit.nok
fi

# Passwort als Umgebungsvariable für Docker Compose exportieren
export MARIADB_PASSWORD=$DB_PASSWORD

# Prüfen, ob die Installation bereits vorhanden ist
if [ ! -f "${SEATABLE_DIR}/seatable-server.yml" ]; then
    bashio::log.info "Keine SeaTable-Installation gefunden. Lade die neueste Version herunter..."
    mkdir -p "${SEATABLE_DIR}"
    cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das Verzeichnis wechseln."
    
    wget -O seatable-compose.tar.gz "https://github.com/seatable/seatable-release/releases/latest/download/seatable-compose.tar.gz"
    
    tar -xzf seatable-compose.tar.gz
    rm seatable-compose.tar.gz
    bashio::log.info "Download und Entpacken abgeschlossen."
fi

# --- SeaTable Start ---
bashio::log.info "Starte den SeaTable Server via Docker Compose..."

# Sicherstellen, dass wir im richtigen Verzeichnis sind
cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das SeaTable-Verzeichnis wechseln."

# Der KORREKTE Startbefehl
docker compose -f seatable-server.yml up -d

bashio::log.info "SeaTable-Container wurden gestartet. Der erste Start kann mehrere Minuten dauern."
bashio::log.info "Der Status der einzelnen SeaTable-Dienste ist in deren eigenen Logs ersichtlich, nicht unbedingt hier."

# Endlosschleife, damit das Add-on aktiv bleibt
while true; do
  sleep 3600
done
