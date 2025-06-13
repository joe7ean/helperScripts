#!/bin/bash

# Nextcloud SMTP Konfiguration Script für YunoHost
# Führe das Script als root aus: sudo ./configure_nextcloud_smtp.sh

set -e  # Bei Fehlern stoppen

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Nextcloud SMTP Konfiguration ===${NC}"
echo

# Prüfen ob als root ausgeführt
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Dieses Script muss als root ausgeführt werden${NC}"
   echo "Verwende: sudo $0"
   exit 1
fi

# Prüfen ob YunoHost installiert ist
if ! command -v yunohost &> /dev/null; then
    echo -e "${RED}YunoHost ist nicht installiert oder nicht im PATH${NC}"
    exit 1
fi

# Prüfen ob Nextcloud App installiert ist
if ! yunohost app list | grep -q "nextcloud"; then
    echo -e "${RED}Nextcloud App ist nicht installiert${NC}"
    exit 1
fi

# Eingabe der SMTP-Daten
echo -e "${YELLOW}Bitte gib deine SMTP-Konfiguration ein:${NC}"
echo

read -p "SMTP Server (z.B. smtp.gmail.com): " SMTP_HOST
read -p "SMTP Port (z.B. 587 für TLS, 465 für SSL): " SMTP_PORT
read -p "SMTP Sicherheit (tls/ssl): " SMTP_SECURITY
read -p "SMTP Benutzername/E-Mail: " SMTP_USER
read -s -p "SMTP Passwort: " SMTP_PASSWORD
echo
read -p "Absender E-Mail (z.B. nextcloud@domain.tld): " FROM_EMAIL
read -p "Absender Name (z.B. Nextcloud Server): " FROM_NAME
echo

# Validierung
if [[ -z "$SMTP_HOST" || -z "$SMTP_PORT" || -z "$SMTP_USER" || -z "$SMTP_PASSWORD" ]]; then
    echo -e "${RED}Fehler: Pflichtfelder dürfen nicht leer sein${NC}"
    exit 1
fi

# Backup der aktuellen Konfiguration
echo -e "${BLUE}Erstelle Backup der aktuellen Konfiguration...${NC}"
BACKUP_FILE="/var/www/nextcloud/config/config.php.backup.$(date +%Y%m%d_%H%M%S)"
cp /var/www/nextcloud/config/config.php "$BACKUP_FILE"
echo -e "${GREEN}Backup erstellt: $BACKUP_FILE${NC}"
echo

# SMTP Konfiguration setzen
echo -e "${BLUE}Setze SMTP Konfiguration...${NC}"

yunohost app shell nextcloud << EOF
php occ config:system:set mail_smtpmode --value="smtp"
php occ config:system:set mail_smtphost --value="$SMTP_HOST"
php occ config:system:set mail_smtpport --value="$SMTP_PORT" --type=integer
php occ config:system:set mail_smtpauth --value="1" --type=boolean
php occ config:system:set mail_smtpname --value="$SMTP_USER"
php occ config:system:set mail_smtppassword --value="$SMTP_PASSWORD"
php occ config:system:set mail_smtpsecure --value="$SMTP_SECURITY"
php occ config:system:set mail_from_address --value="$FROM_EMAIL"
php occ config:system:set mail_domain --value="$(echo $FROM_EMAIL | cut -d'@' -f2)"
EOF

# Zusätzliche Mail-Einstellungen (optional)
if [[ -n "$FROM_NAME" ]]; then
    yunohost app shell nextcloud << EOF
php occ config:system:set mail_from_name --value="$FROM_NAME"
EOF
fi

echo -e "${GREEN}SMTP Konfiguration erfolgreich gesetzt!${NC}"
echo

# Test-Mail senden (optional)
echo -e "${YELLOW}Möchtest du eine Test-Mail senden? (j/n)${NC}"
read -p "Antwort: " TEST_MAIL

if [[ "$TEST_MAIL" == "j" || "$TEST_MAIL" == "J" ]]; then
    read -p "Test-Mail senden an: " TEST_RECIPIENT
    if [[ -n "$TEST_RECIPIENT" ]]; then
        echo -e "${BLUE}Sende Test-Mail...${NC}"
        yunohost app shell nextcloud << EOF
php occ config:system:set mail_smtpmode --value="smtp"
php -r "
require_once('/var/www/nextcloud/lib/base.php');
\$mailer = \OC::getMailer();
\$message = \$mailer->createMessage();
\$message->setSubject('Nextcloud SMTP Test');
\$message->setFrom(['$FROM_EMAIL' => '$FROM_NAME']);
\$message->setTo(['$TEST_RECIPIENT']);
\$message->setPlainBody('Dies ist eine Test-Mail von deinem Nextcloud Server. SMTP funktioniert!');
try {
    \$mailer->send(\$message);
    echo 'Test-Mail erfolgreich gesendet!' . PHP_EOL;
} catch (Exception \$e) {
    echo 'Fehler beim Senden: ' . \$e->getMessage() . PHP_EOL;
}
"
EOF
    fi
fi

echo
echo -e "${GREEN}=== Konfiguration abgeschlossen ===${NC}"
echo -e "${BLUE}Aktuelle Mail-Konfiguration:${NC}"

# Aktuelle Konfiguration anzeigen (ohne Passwort)
yunohost app shell nextcloud << 'EOF'
echo "SMTP Host: $(php occ config:system:get mail_smtphost)"
echo "SMTP Port: $(php occ config:system:get mail_smtpport)"
echo "SMTP Sicherheit: $(php occ config:system:get mail_smtpsecure)"
echo "SMTP Benutzer: $(php occ config:system:get mail_smtpname)"
echo "Absender E-Mail: $(php occ config:system:get mail_from_address)"
echo "Absender Name: $(php occ config:system:get mail_from_name)"
EOF

echo
echo -e "${YELLOW}Backup der vorherigen Konfiguration: $BACKUP_FILE${NC}"
echo -e "${YELLOW}Bei Problemen kannst du die alte Konfiguration wiederherstellen mit:${NC}"
echo -e "${BLUE}sudo cp $BACKUP_FILE /var/www/nextcloud/config/config.php${NC}"

# Script zum Wiederherstellen der Konfiguration erstellen
cat > /tmp/restore_nextcloud_smtp.sh << 'RESTORE_EOF'
#!/bin/bash
# Nextcloud SMTP Konfiguration wiederherstellen

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

BACKUP_FILE="$1"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Backup-Datei nicht gefunden: $BACKUP_FILE"
    exit 1
fi

echo "Stelle Nextcloud Konfiguration wieder her..."
cp "$BACKUP_FILE" /var/www/nextcloud/config/config.php
chown www-data:www-data /var/www/nextcloud/config/config.php
echo "Konfiguration wiederhergestellt!"
RESTORE_EOF

chmod +x /tmp/restore_nextcloud_smtp.sh
echo -e "${BLUE}Restore-Script erstellt: /tmp/restore_nextcloud_smtp.sh${NC}"
echo
echo -e "${GREEN}Fertig! Deine Nextcloud SMTP-Konfiguration ist jetzt gesetzt.${NC}"