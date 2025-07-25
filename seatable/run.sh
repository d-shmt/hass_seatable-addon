#!/usr/bin/with-contenv bashio

# --- Konfiguration auslesen ---
HTTP_PORT=$(bashio::config 'http_port')
HTTPS_PORT=$(bashio::config 'https_port')
export SEATABLE_SERVER_HOSTNAME=$(bashio::network.ingress_entry) # Hostname aus Ingress holen

bashio::log.info "Konfiguration wird geladen..."
bashio::log.info "Hostname: ${SEATABLE_SERVER_HOSTNAME}"
bashio::log.info "HTTP Port: ${HTTP_PORT}"
bashio::log.info "HTTPS Port: ${HTTPS_PORT}"


# --- Docker-in-Docker vorbereiten ---
# Docker benötigt Zugriff auf den Docker-Socket des Hosts. Dies ist ein Sicherheitsrisiko, aber für dieses Add-on notwendig.
# WICHTIG: Das muss in der config.yaml (oder .json) mit "docker_api": true aktiviert werden.
if ! bashio::services.available "docker"; then
    bashio::log.fatal "Der Docker-Dienst ist nicht verfügbar. Bitte stelle sicher, dass das Add-on mit 'docker_api: true' konfiguriert ist."
    bashio::exit.nok
fi

# --- SeaTable Installation ---
SEATABLE_DIR="/opt/seatable-server-latest"
if [ ! -f "${SEATABLE_DIR}/seatable.sh" ]; then
    bashio::log.info "Keine SeaTable-Installation gefunden. Lade die neueste Version herunter..."
    mkdir -p /opt
    cd /opt || bashio::exit.nok "Konnte nicht in das /opt Verzeichnis wechseln."
    
    wget -O seatable-server-latest.tar.gz "https://download.seatable.io/seatable-server-latest-de.tar.gz"
    tar -xzf seatable-server-latest.tar.gz
    rm seatable-server-latest.tar.gz
    bashio::log.info "Download und Entpacken abgeschlossen."
fi

# --- SeaTable Start ---
bashio::log.info "Starte den SeaTable Server..."
cd "${SEATABLE_DIR}" || bashio::exit.nok "Konnte nicht in das SeaTable-Verzeichnis wechseln."

# Das offizielle Skript ist interaktiv. Wir müssen es automatisieren.
# Dies ist der knifflige Teil. Möglicherweise muss die docker-compose.yml angepasst werden.
# Wir starten hier erstmal den Server.
# HINWEIS: Das SeaTable-Skript startet seinerseits Docker-Container. Dies wird "Docker-in-Docker" genannt.

# TODO: docker-compose.yml anpassen, um die Ports aus der Konfiguration zu verwenden.
# sed -i "s/80:80/${HTTP_PORT}:80/g" docker-compose.yml
# sed -i "s/443:443/${HTTPS_PORT}:443/g" docker-compose.yml

./seatable.sh start

bashio::log.info "SeaTable wurde gestartet. Es kann einige Minuten dauern, bis die Weboberfläche erreichbar ist."

# Endlosschleife, damit das Add-on nicht beendet wird
while true; do
  sleep 60
done
