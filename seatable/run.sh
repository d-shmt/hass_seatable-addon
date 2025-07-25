#!/usr/bin/with-contenv bashio

SEATABLE_DIR="/opt/seatable"

bashio::log.info "=== DEBUGGING-LAUF GESTARTET ==="

# Verzeichnis für einen sauberen Test leeren
bashio::log.info "Lösche altes Verzeichnis..."
rm -rf ${SEATABLE_DIR}/*

# Verzeichnis erstellen und dorthin wechseln
mkdir -p "${SEATABLE_DIR}"
cd "${SEATABLE_DIR}" || exit 1

bashio::log.info "Lade Datei herunter..."
wget -O seatable-compose.tar.gz "https://github.com/seatable/seatable-release/releases/latest/download/seatable-compose.tar.gz"

bashio::log.info "Entpacke die Datei..."
tar -xzf seatable-compose.tar.gz

bashio::log.info "=== START: INHALT VON ${SEATABLE_DIR} ==="
ls -lR
bashio::log.info "=== ENDE: INHALT VON ${SEATABLE_DIR} ==="

bashio::log.info "Debugging beendet. Bitte kopiere die gesamten Logs ab 'DEBUGGING-LAUF GESTARTET'."

# Skript hier absichtlich beenden
exit 0
