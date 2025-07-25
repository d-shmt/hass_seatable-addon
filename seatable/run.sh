#!/usr/bin/with-contenv bashio

# --- (Der obere Teil bleibt unverändert) ---

# --- SeaTable Installation ---
SEATABLE_DIR="/opt/seatable"
if [ ! -f "${SEATABLE_DIR}/seatable-compose/seatable.sh" ]; then
    bashio::log.info "Keine SeaTable-Installation gefunden. Lade die neueste Version herunter..."
    mkdir -p "${SEATABLE_DIR}"
    cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das Verzeichnis wechseln."
    
    wget -O seatable-compose.tar.gz "https://github.com/seatable/seatable-release/releases/latest/download/seatable-compose.tar.gz"
    
    tar -xzf seatable-compose.tar.gz
    rm seatable-compose.tar.gz
    bashio::log.info "Download und Entpacken abgeschlossen."
fi

# --- SeaTable Start ---
bashio::log.info "Starte den SeaTable Server..."

# HIER IST DIE KORREKTUR: In das neu erstellte Verzeichnis wechseln
cd "${SEATABLE_DIR}/seatable-compose" || bashio::exit.nok "Konnte nicht in das SeaTable-Unterverzeichnis wechseln."

./seatable.sh start

bashio::log.info "SeaTable wurde gestartet. Es kann einige Minuten dauern, bis die Weboberfläche erreichbar ist."

# Endlosschleife, damit das Add-on nicht beendet wird
while true; do
  sleep 3600
done
