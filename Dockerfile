# Obraz autorytatywnego serwera DNS (BIND 9) dla strefy wewnętrznej koziol.lan
FROM debian:stable-slim

# Wersje pakietów apt celowo nie są przypinane (reguła DL3008 narzędzia hadolint):
# obraz jest cyklicznie przebudowywany, aby zawierał bieżące poprawki bezpieczeństwa.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends bind9 bind9-dnsutils \
    && rm -rf /var/lib/apt/lists/*

COPY bind-config/ /etc/bind/

EXPOSE 53/udp 53/tcp

CMD ["named", "-f", "-g"]
