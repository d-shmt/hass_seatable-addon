#!/usr/bin/with-contenv bashio

SEATABLE_DIR="/opt/seatable"

# Prüfen, ob die Installation bereits vorhanden ist
if [ ! -f "${SEATABLE_DIR}/seatable.sh" ]; then
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

# Sicherstellen, dass wir im richtigen Verzeichnis sind
cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das SeaTable-Verzeichnis wechseln."

# Das Start-Skript ausführen
./seatable.sh start

bashio::log.info "SeaTable wurde gestartet. Es kann einige Minuten dauern, bis die Weboberfläche erreichbar ist."

# Endlosschleife
while true; do
  sleep 3600
done
