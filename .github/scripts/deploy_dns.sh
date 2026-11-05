#!/usr/bin/env bash
set -euo pipefail
: "${OBRAZ:?Brak obrazu}"
: "${TAG:?Brak tagu}"
: "${DNS_SERVER_IP:?Brak IP srodowiska}"
[[ "$TAG" =~ ^b[0-9]+-[a-f0-9]{7}$ ]] || { echo 'Wymagany tag unikalny bNUMER-SHA.'; exit 1; }
docker compose pull
expected=$(docker run --rm "$OBRAZ:$TAG" named-checkzone koziol.lan /etc/bind/db.koziol.lan | sed -n 's/.*loaded serial \([0-9]*\).*/\1/p')
[[ "$expected" =~ ^[0-9]+$ ]] || exit 1
docker compose up -d
for attempt in {1..12}; do
  a=$(docker exec serwer-dns dig @"$DNS_SERVER_IP" www.koziol.lan A +short +time=2 +tries=1 || true)
  ptr=$(docker exec serwer-dns dig @"$DNS_SERVER_IP" -x 192.168.60.14 +short +time=2 +tries=1 || true)
  soa=$(docker exec serwer-dns dig @"$DNS_SERVER_IP" koziol.lan SOA +short +time=2 +tries=1 | awk '{print $3}' || true)
  printf 'Proba %s: A=%s PTR=%s SOA=%s oczekiwany=%s\n' "$attempt" "$a" "$ptr" "$soa" "$expected"
  if [[ "$a" == '192.168.60.14' && "$ptr" == 'prod.koziol.lan.' && "$soa" == "$expected" ]]; then
    mkdir -p dowod-testu
    printf '%s\n' "$TAG" > dowod-testu/tag.txt
    docker image inspect "$OBRAZ:$TAG" --format '{{json .RepoDigests}}' > dowod-testu/digest.json
    exit 0
  fi
  sleep 3
done
echo 'Test wdrozenia DNS nie powiodl sie.' >&2
exit 1
