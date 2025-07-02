# Cypht Multi-Account E-Mail Client

Selbstgehosteter, moderner E-Mail-Client mit nativer Multi-Account-Unterstützung für Raspberry Pi 5.

## 📋 Übersicht

**Cypht** ist ein leichtgewichtiger Webmail-Client, der speziell für die Verwaltung mehrerer E-Mail-Accounts entwickelt wurde. Perfekt geeignet für Netcup-Kunden, die alle ihre E-Mail-Accounts in einer einheitlichen, modernen Oberfläche verwalten möchten.

### ✨ Features

- 🔄 **Native Multi-Account-Unterstützung** - Keine Tricks, echte Multi-Account-Verwaltung
- 📬 **Unified Inbox** - Alle E-Mails aus allen Accounts in einer Ansicht
- 🔍 **Account-übergreifende Suche** - Durchsucht alle konfigurierten E-Mail-Accounts
- 📡 **RSS/Feed-Reader** - Integrierte Feed-Verwaltung
- 👥 **Kontakte-Verwaltung** - Lokale Kontaktverwaltung
- ⚡ **Sehr ressourcenschonend** - Ideal für Raspberry Pi (~30MB RAM)
- 🔒 **Sicher** - Moderne Argon2id-Passwort-Verschlüsselung

## 🛠️ Systemanforderungen

- **Hardware:** Raspberry Pi 4/5 (2GB+ RAM empfohlen)
- **OS:** Raspberry Pi OS (Debian-basiert)
- **Software:** Docker & Docker Compose
- **Ports:** 8100 (Webinterface), 3308 (Datenbank, optional)
- **E-Mail-Provider:** Funktioniert mit allen IMAP/SMTP-Providern (optimiert für Netcup)

## 🚀 Quick Start

### 1. Repository klonen
```bash
git clone <repository-url>
cd cypht-email-client
```

### 2. Setup ausführen
```bash
chmod +x setup.sh
./setup.sh
```

### 3. Webinterface öffnen
- **URL:** http://localhost:8100 oder http://[Pi-IP]:8100
- **Login:** admin / admin

### 4. E-Mail-Accounts hinzufügen
1. **Settings** → **Email** → **IMAP Servers** → **Add Server**
2. **Settings** → **Email** → **SMTP Servers** → **Add Server**
3. Für jeden Account wiederholen

## 📧 Netcup-Konfiguration

### IMAP (Posteingang)
- **Server:** mx2f8c.netcup.net
- **Port:** 993
- **Verschlüsselung:** SSL/TLS
- **Benutzername:** ihre-email@domain.de
- **Passwort:** Ihr Netcup E-Mail-Passwort

### SMTP (Postausgang)
- **Server:** mx2f8c.netcup.net
- **Port:** 465
- **Verschlüsselung:** SSL/TLS
- **Authentifizierung:** Ja
- **Benutzername:** ihre-email@domain.de
- **Passwort:** Ihr Netcup E-Mail-Passwort

## 🔧 Setup-Details

### Automatische Installation

Das `setup.sh` Script führt folgende Schritte aus:

1. **Verzeichnisstruktur erstellen** (`~/mail/`)
2. **Docker Compose konfigurieren** (Cypht + MariaDB)
3. **Container starten** und Initialisierung abwarten
4. **Admin-User erstellen** mit Argon2id-Verschlüsselung
5. **Bereitschaft prüfen** und Anweisungen ausgeben

### Manuelle Installation

```bash
# Verzeichnis erstellen
mkdir -p ~/mail && cd ~/mail

# Docker Compose Datei erstellen
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  cypht-db:
    image: mariadb:10
    restart: unless-stopped
    container_name: cypht-mariadb
    environment:
      - MYSQL_ROOT_PASSWORD=admin
      - MYSQL_DATABASE=cypht
      - MYSQL_USER=admin
      - MYSQL_PASSWORD=admin
    volumes:
      - ./db-data:/var/lib/mysql
    ports:
      - "3308:3306"
    networks:
      - cypht-network

  cypht:
    image: sailfrog/cypht-docker:latest
    restart: unless-stopped
    container_name: cypht-webmail
    depends_on:
      - cypht-db
    ports:
      - "8100:80"
    environment:
      - CYPHT_DB_HOST=cypht-db
      - CYPHT_DB_PORT=3306
      - CYPHT_DB_NAME=cypht
      - CYPHT_DB_USER=admin
      - CYPHT_DB_PASS=admin
      - CYPHT_DB_DRIVER=mysql
      - CYPHT_AUTH_TYPE=DB
      - CYPHT_ADMIN_USERS=admin
      - CYPHT_DEFAULT_LANGUAGE=en
      - CYPHT_TIMEZONE=Europe/Berlin
    volumes:
      - ./cypht-data:/var/lib/cypht
      - ./cypht-config:/etc/cypht
    networks:
      - cypht-network

networks:
  cypht-network:
    driver: bridge
EOF

# Container starten
docker-compose up -d

# Admin-User erstellen (nach ~45 Sekunden)
sleep 45
docker exec -it cypht-webmail php /usr/local/share/cypht/scripts/create_account.php admin admin
```

## 🏗️ Projektstruktur

```
~/mail/
├── docker-compose.yml          # Container-Konfiguration
├── setup.sh                    # Automatisches Setup-Script
├── db-data/                    # MariaDB-Daten (persistent)
├── cypht-data/                 # Cypht-Daten (persistent)
├── cypht-config/               # Cypht-Konfiguration
├── README.md                   # Diese Anleitung
└── netcup-setup.md            # Detaillierte Netcup-Anweisungen
```

## 🔨 Verwaltung

### Container-Befehle
```bash
cd ~/mail

# Status prüfen
docker-compose ps

# Logs anzeigen
docker-compose logs
docker-compose logs cypht      # Nur Cypht-Logs
docker-compose logs cypht-db   # Nur DB-Logs

# Container stoppen
docker-compose down

# Container neu starten
docker-compose up -d

# Updates durchführen
docker-compose pull
docker-compose up -d
```

### Backup & Restore
```bash
# Backup erstellen
cd ~/mail
tar -czf cypht-backup-$(date +%Y%m%d).tar.gz db-data/ cypht-data/ cypht-config/

# Restore
cd ~/mail
docker-compose down
tar -xzf cypht-backup-YYYYMMDD.tar.gz
docker-compose up -d
```

## 🐛 Troubleshooting

### Login-Probleme

**Symptom:** "Invalid username or password"

```bash
# Admin-User neu erstellen
cd ~/mail
docker exec -it cypht-mariadb mysql -u root -padmin cypht -e "DELETE FROM hm_user WHERE username='admin';"
docker exec -it cypht-webmail php /usr/local/share/cypht/scripts/create_account.php admin admin

# User-Status prüfen
docker exec -it cypht-mariadb mysql -u root -padmin cypht -e "SELECT * FROM hm_user;"
```

### Container-Probleme

**Symptom:** Container starten nicht

```bash
# Port-Konflikte prüfen
netstat -tuln | grep -E ':(8100|3308) '

# Logs prüfen
docker-compose logs

# Kompletter Reset
docker-compose down
sudo rm -rf db-data/* cypht-data/*
docker-compose up -d
```

### E-Mail-Verbindungsprobleme

**Symptom:** "Can't connect to mail server"

1. **Server-Einstellungen prüfen:**
   - IMAP: mx2f8c.netcup.net:993 (SSL)
   - SMTP: mx2f8c.netcup.net:465 (SSL)

2. **Netcup-Zugangsdaten verifizieren**
3. **Firewall-Einstellungen prüfen**

### Datenbank-Probleme

**Symptom:** "Can't read dir of './cypht/'"

```bash
# Berechtigungen reparieren
cd ~/mail
docker-compose down
sudo chown -R $USER:$USER db-data/
docker-compose up -d
```

## 📊 Multi-Account Workflow

### 1. Ersten Account einrichten
1. Login bei http://localhost:8100 (admin/admin)
2. **Settings** → **Email** → **IMAP Servers** → **Add Server**
3. Netcup-Einstellungen eingeben
4. **Settings** → **Email** → **SMTP Servers** → **Add Server**
5. Netcup-SMTP-Einstellungen eingeben

### 2. Weitere Accounts hinzufügen
- Schritte 2-5 für jeden weiteren Account wiederholen
- Jeder Account erhält eigene IMAP/SMTP-Konfiguration

### 3. Multi-Account Features nutzen
- **Unified Inbox:** Alle E-Mails in einer Ansicht
- **Account-Wechsel:** Über linkes Menü
- **Übergreifende Suche:** Durchsucht alle Accounts
- **Account-spezifische Ordner:** Separate Ansichten verfügbar

## 🔒 Sicherheit

### Standard-Sicherheitsmaßnahmen
- **Argon2id-Passwort-Hashing** (moderner Standard)
- **Verschlüsselte E-Mail-Verbindungen** (SSL/TLS)
- **Container-Isolation** (Docker-Security)
- **Lokale Datenbank** (keine Cloud-Abhängigkeit)

### Empfohlene Härtung
```bash
# Admin-Passwort ändern
docker exec -it cypht-webmail php /usr/local/share/cypht/scripts/create_account.php admin neues-sicheres-passwort

# Reverse Proxy mit SSL einrichten (optional)
# Firewall konfigurieren (ufw)
# Regelmäßige Backups automatisieren
```

## 🆚 Vergleich mit anderen E-Mail-Clients

| Feature | Cypht | Roundcube | SnappyMail | Thunderbird |
|---------|-------|-----------|------------|-------------|
| Multi-Account | ✅ Nativ | ⚠️ Identitäten | ⚠️ Eingeschränkt | ✅ Nativ |
| Ressourcenverbrauch | ✅ ~30MB | ✅ ~50MB | ✅ ~25MB | ❌ ~200MB+ |
| Webbasiert | ✅ | ✅ | ✅ | ❌ |
| Unified Inbox | ✅ | ❌ | ⚠️ | ✅ |
| Feed-Reader | ✅ | ❌ | ❌ | ✅ |
| Mobile-optimiert | ✅ | ⚠️ | ✅ | ❌ |
| Setup-Komplexität | ✅ Einfach | ⚠️ Mittel | ⚠️ Mittel | ✅ Einfach |

## 📈 Performance

### Raspberry Pi 5 Benchmarks
- **RAM-Verbrauch:** ~30MB (Cypht) + ~100MB (MariaDB)
- **CPU-Last:** <5% im Idle, <15% bei aktiver Nutzung
- **Speicherplatz:** ~200MB für Installation + E-Mail-Cache
- **Boot-Zeit:** ~45 Sekunden bis vollständig einsatzbereit

## 🤝 Support & Community

### Hilfe erhalten
- **GitHub Issues:** Für projektspezifische Probleme
- **Cypht Documentation:** https://cypht.org/doc.html
- **Docker Hub:** https://hub.docker.com/r/sailfrog/cypht-docker

### Beitragen
1. Fork das Repository
2. Feature-Branch erstellen (`git checkout -b feature/amazing-feature`)
3. Changes committen (`git commit -m 'Add amazing feature'`)
4. Branch pushen (`git push origin feature/amazing-feature`)
5. Pull Request erstellen

## 📝 Changelog

### v1.0.0 (2025-07-02)
- Initiale Version mit Cypht Multi-Account Setup
- Netcup-optimierte Konfiguration
- Automatisches Setup-Script
- Docker Compose Integration
- Argon2id-Authentifizierung

## 📄 Lizenz

Dieses Projekt steht unter der MIT-Lizenz. 

## Autor

- **HalloWelt42** - Initialer Entwurf und Dokumentation

## 🙏 Danksagungen

- **Cypht-Team** für den exzellenten E-Mail-Client
- **sailfrog** für das Docker-Image
