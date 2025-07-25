#!/usr/bin/with-contenv bashio

bashio::log.warning "============================================="
bashio::log.warning "===       START DIAGNOSE-LAUF             ==="
bashio::log.warning "============================================="

# Lese den Wert aus der Konfiguration
ADMIN_PW_VALUE=$(bashio::config 'seatable_admin_pw')

# Gib den gelesenen Wert im Log aus. Die Pfeile ->...<- helfen zu sehen, ob er wirklich leer ist.
bashio::log.warning "Der gelesene Wert für 'seatable_admin_pw' ist: ->'${ADMIN_PW_VALUE}'<-"

# Überprüfe explizit, ob die Variable leer ist
if [ -z "$ADMIN_PW_VALUE" ]; then
    bashio::log.error "Diagnose-Ergebnis: Die Variable ist LEER."
else
    bashio::log.info "Diagnose-Ergebnis: Die Variable enthält einen Wert."
fi

bashio::log.warning "============================================="
bashio::log.warning "===        ENDE DIAGNOSE-LAUF             ==="
bashio::log.warning "============================================="

# Beende das Skript sauber, ohne SeaTable zu starten
exit 0
