# 🚀 WebIDE Setup für Raspberry Pi 5

![screenshot](./media/Bildschirmfoto%202025-06-30%20um%2019.03.09.png)

Eine vollständige Anleitung zum Einrichten einer professionellen Web-Entwicklungsumgebung mit Docker auf dem Raspberry Pi 5.

## 📋 Was du bekommst

- **Code-Server** (VS Code im Browser)
- **Vorinstallierte Sprachen**: Python 3.11, Node.js 20, PHP 8.2, Go 1.21, Rust
- **Persistente Daten** nach Neustart
- **Korrekte Dateiberechtigungen** 
- **Zugriff von allen Geräten** im Netzwerk

---

## 🛠️ Voraussetzungen

- Raspberry Pi 5 mit Raspberry Pi OS
- SSH-Zugang oder direkter Zugriff
- Internetverbindung

---

## 📁 1. Projektverzeichnis erstellen

```bash
# Erstelle und wechsle ins Projektverzeichnis
mkdir ~/webide
cd ~/webide
```

---

## 📥 2. Dateien erstellen

### 2.1 docker-compose.yml

Erstelle die Datei:
```bash
nano docker-compose.yml
```

Inhalt einfügen:
```yaml
services:
  code-server:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: webide-pi5
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
      - PASSWORD=dein_sicheres_passwort
      - SUDO_PASSWORD=admin123
      - DEFAULT_WORKSPACE=/config/workspace
    volumes:
      - ./config:/config
      - ./workspace:/config/workspace
      - ./projects:/config/projects
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "8087:8080"
    restart: unless-stopped
    user: "1000:1000"
    networks:
      - webide-network

networks:
  webide-network:
    driver: bridge
```

Speichern: `Ctrl+X`, dann `Y`, dann `Enter`

### 2.2 Dockerfile

Erstelle die Datei:
```bash
nano Dockerfile
```

Inhalt einfügen:
```dockerfile
# Base Image für ARM64 (Raspberry Pi 5)
FROM codercom/code-server:latest

# Als root für Installation
USER root

# System Update und Tools Installation
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    nano \
    vim \
    htop \
    tree \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# Python 3.11 + pip
RUN apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential

# Node.js 20 LTS (aktuell für ARM64)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# PHP 8.2 mit wichtigen Modulen
RUN apt-get install -y \
    php8.2 \
    php8.2-cli \
    php8.2-common \
    php8.2-curl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    php8.2-mysql \
    php8.2-sqlite3 \
    composer

# Go 1.21 für ARM64
RUN wget https://go.dev/dl/go1.21.6.linux-arm64.tar.gz && \
    tar -C /usr/local -xzf go1.21.6.linux-arm64.tar.gz && \
    rm go1.21.6.linux-arm64.tar.gz

# Rust (aktuell)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Docker CLI (für Docker-in-Docker wenn gewünscht)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# User Setup (wichtig für Berechtigungen)
RUN usermod -aG sudo coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Environment Variables
ENV PATH="/usr/local/go/bin:/home/coder/.cargo/bin:$PATH"
ENV GOPATH="/home/coder/go"
ENV GOBIN="/home/coder/go/bin"

# Wechsel zu coder user
USER coder

# Code-Server Extensions (beliebte für Webentwicklung)
RUN code-server --install-extension ms-python.python && \
    code-server --install-extension bradlc.vscode-tailwindcss && \
    code-server --install-extension esbenp.prettier-vscode && \
    code-server --install-extension ms-vscode.vscode-typescript-next && \
    code-server --install-extension golang.go && \
    code-server --install-extension rust-lang.rust-analyzer

# Arbeitsverzeichnis
WORKDIR /config/workspace

# Default command
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password"]
```

Speichern: `Ctrl+X`, dann `Y`, dann `Enter`

### 2.3 Setup-Script (Optional)

Erstelle die Datei:
```bash
nano setup_netcup.sh
```

Inhalt einfügen:
```bash
#!/bin/bash

echo "🚀 WebIDE Setup für Raspberry Pi 5"
echo "======================================"

# Prüfe ob Docker installiert ist
if ! command -v docker &> /dev/null; then
    echo "❌ Docker ist nicht installiert. Installiere Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installiert. Bitte neu einloggen oder 'newgrp docker' ausführen"
    exit 1
fi

# Prüfe ob Docker Compose installiert ist
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose ist nicht installiert. Installiere..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
fi

# Erstelle Verzeichnisstruktur mit korrekten Berechtigungen
echo "📁 Erstelle Verzeichnisstruktur..."
mkdir -p config workspace projects

# Setze korrekte Besitzer (wichtig!)
sudo chown -R 1000:1000 config workspace projects
sudo chmod -R 755 config workspace projects

# Erstelle .env Datei falls nicht vorhanden
if [ ! -f .env ]; then
    echo "📝 Erstelle .env Datei..."
    cat > .env << EOF
PUID=1000
PGID=1000
TZ=Europe/Berlin
PASSWORD=dein_sicheres_passwort
SUDO_PASSWORD=admin123
EOF
fi

echo "🔧 Baue Container..."
docker-compose build

echo "🚀 Starte WebIDE..."
docker-compose up -d

echo ""
echo "✅ Setup abgeschlossen!"
echo ""
echo "📋 Wichtige Informationen:"
echo "========================="
echo "🌐 WebIDE URL: http://$(hostname -I | awk '{print $1}'):8087"
echo "🔑 Passwort: dein_sicheres_passwort"
echo ""
echo "📁 Verzeichnisstruktur:"
echo "  ./config    - Code-Server Konfiguration"
echo "  ./workspace - Dein Arbeitsbereich"
echo "  ./projects  - Deine Projekte"
echo ""
echo "🔧 Nützliche Befehle:"
echo "  docker-compose logs -f    - Logs anzeigen"
echo "  docker-compose restart    - Neustart"
echo "  docker-compose down       - Stoppen"
echo ""
echo "💡 Installierte Sprachen:"
echo "  - Python 3.11 + pip"
echo "  - Node.js 20 + npm"
echo "  - PHP 8.2 + Composer"
echo "  - Go 1.21"
echo "  - Rust (latest)"
echo ""
```

Speichern und ausführbar machen:
```bash
chmod +x setup_netcup.sh
```

---

## 🚀 3. Installation

### Option A: Automatisch mit Setup-Script

```bash
./setup_netcup.sh
```

Das war's! Das Script macht alles automatisch.

### Option B: Manuell Schritt für Schritt

#### 3.1 Docker installieren (falls nicht vorhanden)

```bash
# Docker installieren
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Neu einloggen oder ausführen:
newgrp docker
```

#### 3.2 Docker Compose installieren

```bash
sudo apt-get update
sudo apt-get install -y docker-compose-plugin
```

#### 3.3 Verzeichnisse erstellen und Berechtigungen setzen

```bash
# Verzeichnisse erstellen
mkdir -p config workspace projects

# Korrekte Berechtigungen setzen (WICHTIG!)
sudo chown -R 1000:1000 config workspace projects
sudo chmod -R 755 config workspace projects
```

#### 3.4 Container bauen und starten

```bash
# Container bauen (kann 10-15 Minuten dauern)
docker-compose build --no-cache

# Container starten
docker-compose up -d
```

---

## 🎯 4. Zugriff auf die WebIDE

1. **Öffne deinen Browser** auf einem beliebigen Gerät im Netzwerk
2. **Gehe zu**: `http://RASPBERRY-PI-IP:8087`
   - Die IP findest du mit: `hostname -I`
   - Z.B.: `http://192.168.1.100:8087`
3. **Passwort eingeben**: `dein_sicheres_passwort`

---

## 📁 5. Verzeichnisstruktur

```
~/webide/
├── docker-compose.yml    # Container-Konfiguration
├── Dockerfile           # Container-Build-Anweisungen
├── setup.sh            # Automatisches Setup (optional)
├── config/             # Code-Server Einstellungen (persistent)
├── workspace/          # Hauptarbeitsbereich (persistent)
└── projects/           # Deine Projekte (persistent)
```

---

## 🔧 6. Nützliche Befehle

### Container verwalten
```bash
# Status anzeigen
docker-compose ps

# Logs anzeigen
docker-compose logs -f

# Container neustarten
docker-compose restart

# Container stoppen
docker-compose down

# Container stoppen und alles löschen
docker-compose down -v
```

### Bei Problemen
```bash
# Kompletter Neustart
docker-compose down
docker system prune -f
docker-compose build --no-cache
docker-compose up -d

# Build-Logs detailliert anzeigen
docker-compose build --no-cache --progress=plain
```

---

## 🎨 7. Passwort ändern

1. **Stoppe Container**: `docker-compose down`
2. **Ändere in docker-compose.yml**: 
   ```yaml
   - PASSWORD=dein_neues_passwort
   ```
3. **Starte neu**: `docker-compose up -d`

---

## 🔒 8. Sicherheit

### Empfohlene Einstellungen:
- **Starkes Passwort** verwenden
- **Firewall konfigurieren** (nur Port 8087 freigeben)
- **Reverse Proxy** mit HTTPS für externen Zugriff

### Beispiel UFW Firewall:
```bash
sudo ufw allow 8087
sudo ufw enable
```

---

## 🐛 9. Häufige Probleme & Lösungen

### Problem: Port bereits belegt
```bash
# Andere Ports finden
sudo netstat -tlnp | grep :80

# Port in docker-compose.yml ändern:
ports:
  - "8088:8080"  # Statt 8087
```

### Problem: Berechtigungsfehler
```bash
# Berechtigungen neu setzen
sudo chown -R 1000:1000 config workspace projects
sudo chmod -R 755 config workspace projects
```

### Problem: Container startet nicht
```bash
# Logs prüfen
docker-compose logs code-server

# Komplett neu bauen
docker-compose down
docker system prune -af
docker-compose build --no-cache
docker-compose up -d
```

---

## 📊 10. Systemanforderungen

- **RAM**: Mindestens 2GB (4GB empfohlen)
- **Speicher**: Mindestens 8GB frei
- **CPU**: Raspberry Pi 5 (ARM64)
- **Netzwerk**: Stabile Internetverbindung für Build

---

## 🎉 Fertig!

Du hast jetzt eine vollwertige Entwicklungsumgebung mit:
- ✅ VS Code im Browser
- ✅ Python, Node.js, PHP, Go, Rust
- ✅ Persistente Daten
- ✅ Zugriff von allen Geräten
- ✅ Automatische Backups durch Docker Volumes

**Viel Spaß beim Programmieren! 🚀**