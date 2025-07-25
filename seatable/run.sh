#!/usr/bin/with-contenv bashio

# --- Konfiguration auslesen ---
# (Hier bleibt alles wie gehabt)

# --- SeaTable Installation ---
SEATABLE_DIR="/opt/seatable" # Verzeichnis ggf. anpassen
if [ ! -f "${SEATABLE_DIR}/seatable.sh" ]; then
    bashio::log.info "Keine SeaTable-Installation gefunden. Lade die neueste Version herunter..."
    mkdir -p "${SEATABLE_DIR}"
    cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das Verzeichnis wechseln."
    
    # KORRIGIERTE DOWNLOAD-ZEILE
    wget -O seatable-compose.tar.gz "https://github.com/seatable/seatable-release/releases/latest/download/seatable-compose.tar.gz"
    
    tar -xzf seatable-compose.tar.gz
    rm seatable-compose.tar.gz
    bashio::log.info "Download und Entpacken abgeschlossen."
fi

# --- SeaTable Start ---
bashio::log.info "Starte den SeaTable Server..."
cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das SeaTable-Verzeichnis wechseln."

./seatable.sh start

bashio::log.info "SeaTable wurde gestartet. Es kann einige Minuten dauern, bis die Weboberfläche erreichbar ist."

# Endlosschleife, damit das Add-on nicht beendet wird
while true; do
  sleep 3600 # Eine Stunde schlafen, um die CPU zu schonen
done
