FROM alpine:latest

# Mettre à jour les packages et installer les dépendances
RUN apk update && apk add --no-cache \
    go \
    git \
    bash \
    curl \
    jq \
    dcron \
    openssh-client \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Installer Plakar
RUN go install github.com/PlakarKorp/plakar@latest && \
    mv /root/go/bin/plakar /usr/local/bin/plakar && \
    rm -rf /root/go

# Créer les répertoires nécessaires
RUN mkdir -p /backup/source /backup/storage /backup/restore

# Copier le script de backup
COPY backup-script.sh /backup-script.sh
RUN chmod +x /backup-script.sh

# Configurer le timezone
RUN ln -snf /usr/share/zoneinfo/Europe/Paris /etc/localtime && \
    echo "Europe/Paris" > /etc/timezone

# Créer le répertoire de logs
RUN mkdir -p /var/log/backup

# Point d'entrée par défaut
CMD ["sh", "-c", "echo '0 2 * * * /backup-script.sh' | crontab - && crond -f"] 