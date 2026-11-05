# Serwer DNS firmy KoziołNet (repozytorium `dns_koziol`)

Autorytatywny serwer DNS (BIND 9) w kontenerze Docker dla strefy `koziol.lan` oraz
strefy odwrotnej `60.168.192.in-addr.arpa`. Przepływy GitHub Actions są częścią
projektu do samodzielnego wykonania.

## Zawartość

| Plik / katalog | Przeznaczenie |
|---|---|
| `Dockerfile` | Obraz serwera BIND (Debian stable-slim + bind9 + narzędzia dig) |
| `bind-config/named.conf*` | Konfiguracja BIND (serwer autorytatywny, bez rekurencji) |
| `bind-config/db.koziol.lan` | Strefa wewnętrzna (rekordy A) |
| `bind-config/db.60.168.192` | Strefa odwrotna (rekordy PTR) |
| `docker-compose.yml` | Uruchomienie kontenera na TEST/PROD (obraz i tag ze zmiennych `OBRAZ` i `TAG`) |
| `.dockerignore` | Pliki pomijane przy budowaniu obrazu |

## Zasady pracy ze strefami

- Przy **każdej** zmianie pliku strefy należy zwiększyć numer seryjny SOA (format
  `RRRRMMDDNN`). Przepływ CI ma wykrywać zmianę strefy bez zwiększenia numeru (Część 3, pkt 4).
- Czasy TTL są celowo krótkie, aby zmiany szybko docierały do klientów przez AdGuard Home.
- Strefa odwrotna zawiera **jeden** rekord PTR na adres, wskazujący nazwę kanoniczną serwera
  (`prod`, `test`, `jenkins`, `agent`, `agh`, `gitlab`). Nazwy pomocnicze wskazujące ten sam adres
  (`ns1`, `www`, `www-test`) nie mają własnych rekordów PTR.

## Testy lokalne (np. na AGENT lub TEST z zainstalowanym Dockerem)

```bash
docker build -t dns-test .
docker run --rm dns-test named-checkconf /etc/bind/named.conf
docker run --rm dns-test named-checkzone koziol.lan /etc/bind/db.koziol.lan
docker run --rm dns-test named-checkzone 60.168.192.in-addr.arpa /etc/bind/db.60.168.192
```

Test działającego serwera (np. po wdrożeniu na TEST):

```bash
dig @127.0.0.1 www.koziol.lan +short          # oczekiwany adres PROD
dig @127.0.0.1 -x 192.168.60.14 +short               # oczekiwana nazwa prod.koziol.lan.
dig @127.0.0.1 koziol.lan SOA +short          # trzecie pole = numer seryjny strefy
```

Numer seryjny SOA pozwala sprawdzić, że serwer działa z właściwą wersją strefy. Wartość
oczekiwaną można odczytać z pliku strefy w obrazie, który miał zostać wdrożony, np.:

```bash
docker run --rm "$OBRAZ:$TAG" named-checkzone koziol.lan /etc/bind/db.koziol.lan
# wynik zawiera: "loaded serial <numer>"
```

Jeżeli na serwerze nie ma polecenia `dig`, można użyć narzędzi z obrazu, np.
`docker exec serwer-dns dig @127.0.0.1 www.koziol.lan +short`.

## Wdrożenie (kontrakt dla przepływu)

```bash
OBRAZ=login_docker_hub/dns_koziol TAG=b57-1a2b3c4 docker compose pull
OBRAZ=login_docker_hub/dns_koziol TAG=b57-1a2b3c4 docker compose up -d
```

Zmienne `OBRAZ` i `TAG` są wymagane - brak któregokolwiek przerywa polecenie. Dzięki temu na
TEST i PROD zawsze trafia jawnie wskazany, przetestowany obraz.

## Do wykonania samodzielnie (nie ma w tym repozytorium)

- przepływy w katalogu `.github/workflows/` (CI, CD, wycofanie zmian) - Część 3 projektu.
