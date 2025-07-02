#!/bin/bash

# Cypht E-Mail Client Setup Script
# Native Multi-Account E-Mail Client für Netcup auf Raspberry Pi 5

set -e  # Exit bei Fehlern

echo "🚀 Starte Cypht E-Mail Client Setup..."

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funktionen
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNUNG]${NC} $1"
}

print_error() {
    echo -e "${RED}[FEHLER]${NC} $1"
}

# Prüfe ob Docker läuft
if ! docker info > /dev/null 2>&1; then
    print_error "Docker ist nicht verfügbar oder läuft nicht!"
    exit 1
fi

# Erstelle Verzeichnisstruktur
MAIL_DIR="$HOME/mail"
print_status "Erstelle Verzeichnisstruktur in $MAIL_DIR..."

mkdir -p "$MAIL_DIR"
cd "$MAIL_DIR"

# Erstelle notwendige Unterverzeichnisse
mkdir -p cypht-data
mkdir -p cypht-config
mkdir -p db-data

print_status "Verzeichnisse erstellt."

# Erstelle docker-compose.yml
print_status "Erstelle Docker Compose Konfiguration..."

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

print_status "Docker Compose Datei erstellt."

# Erstelle Cypht Konfigurationsdatei
print_status "Erstelle Cypht-Konfiguration..."

cat > cypht-config/hm3.ini << 'EOF'
; Cypht Konfiguration für Netcup Multi-Account Setup

[app]
default_timezone = "Europe/Berlin"
default_language = "en"
encrypt_ajax_requests = true
encrypt_local_storage = true

[database]
type = "mysql"
host = "cypht-db"
port = 3306
name = "cypht"
user = "admin"
pass = "admin"

[authentication]
type = "DB"
default_user = "admin"
default_pass = "admin"

[modules]
allowed_pages = "home,compose,contacts,calendar,feeds,profiles,settings"
disable_origin_check = false

[imap]
default_server_host = "mx2f8c.netcup.net"
default_server_port = 993
default_server_tls = true
auth_type = "login"

[smtp]
default_server_host = "mx2f8c.netcup.net"
default_server_port = 465
default_server_tls = true
auth_type = "login"

[ui]
language = "en"
timezone = "Europe/Berlin"
list_style = "email_style"
no_password_save = false
start_page = "message_list"
EOF

# Erstelle Netcup Setup-Anleitung
cat > netcup-setup.md << 'EOF'
# Cypht Multi-Account Setup für Netcup

## Erster Login

**URL:** http://localhost:8100
**Standard-Login:**
- Benutzername: `admin`
- Passwort: `admin`

## E-Mail-Accounts hinzufügen

### 1. **Ersten Netcup-Account hinzufügen:**
1. Nach Login: **"Settings"** → **"Email"** → **"IMAP Servers"**
2. **"Add IMAP Server"** klicken
3. **Server-Einstellungen:**
   - **Server:** mx2f8c.netcup.net
   - **Port:** 993
   - **Security:** SSL/TLS
   - **Username:** deine-email@domain.de
   - **Password:** dein-netcup-passwort

### 2. **SMTP für Postausgang hinzufügen:**
1. **"Settings"** → **"Email"** → **"SMTP Servers"**
2. **"Add SMTP Server"** klicken
3. **Server-Einstellungen:**
   - **Server:** mx2f8c.netcup.net
   - **Port:** 465
   - **Security:** SSL/TLS
   - **Username:** deine-email@domain.de
   - **Password:** dein-netcup-passwort

### 3. **Weitere Accounts hinzufügen:**
- Wiederhole Schritte 1-2 für jede weitere E-Mail-Adresse
- Jeder Account bekommt eigene IMAP/SMTP-Einstellungen
- Alle Accounts erscheinen im linken Menü

## Multi-Account Features

- **Unified Inbox:** Alle E-Mails in einer Ansicht
- **Account-spezifische Ordner:** Separate Ansicht pro Account
- **Übergreifende Suche:** Durchsucht alle Accounts
- **Schneller Account-Wechsel:** Über linkes Menü
- **Compose von jedem Account:** Absender-Auswahl beim Schreiben

## Vorteile von Cypht

✅ **Native Multi-Account-Unterstützung**
✅ **Keine Domain-Konfiguration nötig**
✅ **Moderne, modulare Oberfläche**
✅ **Feeds/RSS-Reader integriert**
✅ **Kontakte-Verwaltung**
✅ **Sehr leichtgewichtig**
EOF

# Erstelle README
cat > README.md << 'EOF'
# Cypht E-Mail Client - Native Multi-Account Support

## Schnellstart

1. **Container starten:**
   ```bash
   docker-compose up -d
   ```

2. **Webinterface öffnen:**
   - URL: http://localhost:8100
   - Login: admin / admin

3. **E-Mail-Accounts einrichten:**
   - Settings → Email → IMAP Servers → Add Server
   - Settings → Email → SMTP Servers → Add Server
   - Für jeden Netcup-Account wiederholen

## Netcup Server-Einstellungen

**IMAP (Posteingang):**
- Server: mx2f8c.netcup.net
- Port: 993
- Security: SSL/TLS

**SMTP (Postausgang):**
- Server: mx2f8c.netcup.net
- Port: 465
- Security: SSL/TLS

## Multi-Account Workflow

1. **Admin-Login:** admin/admin
2. **Jeden Netcup-Account einzeln hinzufügen**
3. **Alle Accounts im linken Menü verfügbar**
4. **Unified Inbox oder account-spezifische Ansichten**

## Verwaltung

- **Status:** `docker-compose ps`
- **Logs:** `docker-compose logs`
- **Stoppen:** `docker-compose down`
- **Updates:** `docker-compose pull && docker-compose up -d`

## Datenbank-Zugriff

- **Host:** localhost:3308
- **User:** admin
- **Password:** admin
- **Database:** cypht

## Persistierte Daten

- **E-Mails:** Auf Netcup (IMAP)
- **Einstellungen:** ./cypht-data/
- **Konfiguration:** ./cypht-config/
- **Datenbank:** ./db-data/

## Cypht vs andere Clients

✅ **Echte Multi-Account-Unterstützung** (nicht nur Identitäten)
✅ **Keine Domain-Vorkonfiguration nötig**
✅ **Modularer Aufbau** (E-Mail + Feeds + Kontakte)
✅ **Sehr ressourcenschonend**
✅ **Moderne Oberfläche**
✅ **Account-übergreifende Features**
EOF

# Setze Berechtigungen
print_status "Setze Dateiberechtigungen..."
chmod 755 "$MAIL_DIR"
chmod 777 cypht-data
chmod 755 cypht-config
chmod 777 db-data

# Prüfe verfügbare Ports
print_status "Prüfe Port-Verfügbarkeit..."

if netstat -tuln 2>/dev/null | grep -q ":8100 "; then
    print_warning "Port 8100 ist bereits belegt!"
    print_warning "Ändere den Port in docker-compose.yml oder stoppe den anderen Service."
fi

if netstat -tuln 2>/dev/null | grep -q ":3308 "; then
    print_warning "Port 3308 ist bereits belegt!"
    print_warning "Ändere den Port in docker-compose.yml oder stoppe den anderen Service."
fi

# Starte Container
print_status "Starte Cypht Container..."
docker-compose up -d

# Warte auf Container-Start und DB-Initialisierung
print_status "Warte auf Container-Initialisierung..."
sleep 30

# DB-Berechtigungen für spätere Operationen setzen
print_status "Setze Datenbank-Berechtigungen..."
sudo chown -R $USER:$USER db-data/ 2>/dev/null || print_warning "Berechtigungen konnten nicht gesetzt werden"

# Prüfe DB-Verbindung und warte auf vollständige Initialisierung
print_status "Prüfe Datenbank-Verbindung..."
DB_READY=false
for i in {1..15}; do
    if docker-compose exec -T cypht-db mysql -u root -padmin -e "SHOW DATABASES;" >/dev/null 2>&1; then
        # Prüfe ob cypht-DB und hm_user Tabelle existieren
        if docker-compose exec -T cypht-db mysql -u root -padmin cypht -e "SHOW TABLES;" >/dev/null 2>&1; then
            if docker-compose exec -T cypht-db mysql -u root -padmin cypht -e "DESCRIBE hm_user;" >/dev/null 2>&1; then
                DB_READY=true
                break
            fi
        fi
    fi
    echo "Warte auf DB-Initialisierung... ($i/15)"
    sleep 3
done

if [ "$DB_READY" = false ]; then
    print_error "Datenbank ist nicht vollständig initialisiert!"
    print_error "Versuche manuell: docker-compose logs cypht-db"
    exit 1
fi

print_status "Datenbank erfolgreich initialisiert"

# Admin-User erstellen
print_status "Erstelle Admin-User..."
USER_CREATED=false

# Korrekter Cypht-Pfad: /usr/local/share/cypht/
CYPHT_PATH="/usr/local/share/cypht"

# Verwende IMMER das Cypht-Script (für Argon2id-Hashing)
if docker-compose exec -T cypht php "$CYPHT_PATH/scripts/create_account.php" admin admin >/dev/null 2>&1; then
    USER_CREATED=true
    print_status "Admin-User über Cypht-Script erstellt (Argon2id-Hash)"
else
    print_warning "Cypht-Script fehlgeschlagen, versuche direkten Aufruf..."
    # Fallback: Direkter Container-Aufruf
    if docker exec -it cypht-webmail php /usr/local/share/cypht/scripts/create_account.php admin admin >/dev/null 2>&1; then
        USER_CREATED=true
        print_status "Admin-User über direkten Script-Aufruf erstellt"
    fi
fi

# Prüfe ob User wirklich erstellt wurde
if docker-compose exec -T cypht-db mysql -u root -padmin cypht -e "SELECT username FROM hm_user WHERE username='admin';" 2>/dev/null | grep -q "admin"; then
    USER_CREATED=true
    print_status "Admin-User bestätigt in DB"
    # Zeige Hash-Typ für Debug-Zwecke
    HASH_TYPE=$(docker-compose exec -T cypht-db mysql -u root -padmin cypht -e "SELECT hash FROM hm_user WHERE username='admin';" 2>/dev/null | tail -1)
    if [[ $HASH_TYPE == *"argon2id"* ]]; then
        print_status "Korrekter Argon2id-Hash verwendet"
    fi
fi

if [ "$USER_CREATED" = false ]; then
    print_warning "Admin-User konnte nicht automatisch erstellt werden"
    print_warning "Erstelle ihn manuell mit:"
    echo "docker exec -it cypht-webmail php /usr/local/share/cypht/scripts/create_account.php admin admin"
    echo ""
    echo "WICHTIG: Verwende das Cypht-Script, nicht manuelle DB-Inserts!"
    echo "Cypht benötigt Argon2id-Hashing für die Authentifizierung."
fi

# Prüfe Container Status
if docker-compose ps | grep -q "Up"; then
    print_status "✅ Cypht wurde erfolgreich gestartet!"
    echo ""
    echo "📖 Detaillierte Anleitung: cat $MAIL_DIR/netcup-setup.md"
    echo "📖 Weitere Infos: cat $MAIL_DIR/README.md"
    echo "🌐 Webinterface: http://localhost:8100"
    echo "🗄️  Datenbank: localhost:3308 (admin/admin)"
    echo "📁 Verzeichnis: $MAIL_DIR"
    echo ""
    echo "🔑 Standard-Login:"
    echo "   - Benutzername: admin"
    echo "   - Passwort: admin"
    echo ""
    echo "🔧 E-Mail-Accounts einrichten:"
    echo "   1. Login mit admin/admin"
    echo "   2. Settings → Email → IMAP Servers → Add Server"
    echo "   3. mx2f8c.netcup.net:993 (SSL) + deine Netcup-Zugangsdaten"
    echo "   4. Settings → Email → SMTP Servers → Add Server"
    echo "   5. mx2f8c.netcup.net:465 (SSL) + deine Netcup-Zugangsdaten"
    echo "   6. Für weitere Accounts wiederholen"
    echo ""
    echo "📧 Multi-Account Features:"
    echo "   ✅ Unified Inbox (alle E-Mails zusammen)"
    echo "   ✅ Account-spezifische Ordner"
    echo "   ✅ Übergreifende Suche"
    echo "   ✅ Account-Wechsel über linkes Menü"
    echo "   ✅ Feeds/RSS-Reader integriert"
    echo ""
    echo "⚠️  Falls Login nicht funktioniert:"
    echo "   docker exec -it cypht-webmail php /usr/local/share/cypht/scripts/create_account.php admin admin"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   - DB-Zugriff: docker exec -it cypht-mariadb mysql -u root -padmin"
    echo "   - Logs anzeigen: docker-compose logs"
    echo "   - Neustart: docker-compose down && sudo rm -rf db-data/* && docker-compose up -d"
else
    print_error "❌ Container konnten nicht gestartet werden!"
    echo "Prüfe die Logs mit: cd $MAIL_DIR && docker-compose logs"
    exit 1
fi

print_status "Setup abgeschlossen! 🎉"
print_status "Cypht ist bereit für native Multi-Account-Verwaltung!"