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