# /seatable/Dockerfile

# Nutzt das offizielle Home Assistant Basis-Image
ARG BUILD_FROM
FROM $BUILD_FROM

# Installiert alle notwendigen Pakete in einer Zeile
# wget: zum Herunterladen
# tar: zum Entpacken
# sed: zum Bearbeiten von Textdateien (für die Port-Anpassung)
# docker-cli & docker-compose: um SeaTable zu starten
# iproute2: für die alternative IP-Ermittlung
RUN apk add --no-cache wget tar sed docker-cli docker-compose iproute2

# Kopiert das Start-Skript in das Image und macht es ausführbar
COPY run.sh /
RUN chmod a+x /run.sh

# Definiert das Kommando, das beim Start des Containers ausgeführt wird
CMD [ "/run.sh" ]
