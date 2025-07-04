#!/bin/bash

# Nextcloud SMTP Configuration Script for YunoHost
# Run the script as root: sudo ./configure_nextcloud_smtp.sh

set -e  # Stop on errors

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Nextcloud SMTP Configuration ===${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   echo "Use: sudo $0"
   exit 1
fi

# Check if YunoHost is installed
if ! command -v yunohost &> /dev/null; then
    echo -e "${RED}YunoHost is not installed or not in PATH${NC}"
    exit 1
fi

# Check if Nextcloud app is installed
if ! yunohost app list | grep -q "nextcloud"; then
    echo -e "${RED}Nextcloud app is not installed${NC}"
    exit 1
fi

# Get YunoHost domain
echo -e "${YELLOW}Please enter your YunoHost domain:${NC}"
read -p "Domain (e.g. domain.tld): " YUNOHOST_DOMAIN
if [[ -z "$YUNOHOST_DOMAIN" ]]; then
    echo -e "${RED}Error: Domain cannot be empty${NC}"
    exit 1
fi

# Extract domain without TLD for server name
DOMAIN_WITHOUT_TLD=$(echo "$YUNOHOST_DOMAIN" | cut -d'.' -f1)
SERVER_NAME="Nextcloud $DOMAIN_WITHOUT_TLD"

# Input SMTP data
echo -e "${YELLOW}Please enter your SMTP configuration:${NC}"
echo

# Default values
DEFAULT_SMTP_PORT="587"
DEFAULT_SMTP_SECURITY="tls"
DEFAULT_FROM_NAME="Nextcloud Server"
DEFAULT_SMTP_SERVER="localhost"
DEFAULT_FROM_EMAIL="nextcloud@$YUNOHOST_DOMAIN"

read -p "SMTP Server (e.g. smtp.gmail.com) [$DEFAULT_SMTP_SERVER]: " SMTP_HOST
SMTP_HOST=${SMTP_HOST:-$DEFAULT_SMTP_SERVER}

read -p "SMTP Port [$DEFAULT_SMTP_PORT]: " SMTP_PORT
SMTP_PORT=${SMTP_PORT:-$DEFAULT_SMTP_PORT}

read -p "SMTP Security (tls/ssl) [$DEFAULT_SMTP_SECURITY]: " SMTP_SECURITY
SMTP_SECURITY=${SMTP_SECURITY:-$DEFAULT_SMTP_SECURITY}

# Ask if authentication is required
read -p "Is SMTP authentication required? (y/N): " AUTH_REQUIRED
AUTH_REQUIRED=${AUTH_REQUIRED:-N}

if [[ "$AUTH_REQUIRED" == "y" || "$AUTH_REQUIRED" == "Y" ]]; then
    read -p "SMTP Username/Email: " SMTP_USER
    read -s -p "SMTP Password: " SMTP_PASSWORD
    echo
else
    SMTP_USER=""
    SMTP_PASSWORD=""
fi

read -p "Sender Email [$DEFAULT_FROM_EMAIL]: " FROM_EMAIL
FROM_EMAIL=${FROM_EMAIL:-$DEFAULT_FROM_EMAIL}

read -p "Sender Name [$DEFAULT_FROM_NAME]: " FROM_NAME
FROM_NAME=${FROM_NAME:-$DEFAULT_FROM_NAME}

# Extract domain from FROM_EMAIL
MAIL_DOMAIN=$(echo "$FROM_EMAIL" | cut -d'@' -f2)
echo

# Validation
if [[ -z "$SMTP_HOST" || -z "$SMTP_PORT" ]]; then
    echo -e "${RED}Error: SMTP host and port cannot be empty${NC}"
    exit 1
fi

if [[ "$AUTH_REQUIRED" == "y" || "$AUTH_REQUIRED" == "Y" ]]; then
    if [[ -z "$SMTP_USER" || -z "$SMTP_PASSWORD" ]]; then
        echo -e "${RED}Error: Username and password are required when authentication is enabled${NC}"
        exit 1
    fi
fi

# Backup current configuration
echo -e "${BLUE}Creating backup of current configuration...${NC}"
BACKUP_FILE="/var/www/nextcloud/config/config.php.backup.$(date +%Y%m%d_%H%M%S)"
cp /var/www/nextcloud/config/config.php "$BACKUP_FILE"
echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"
echo

# Set SMTP configuration
echo -e "${BLUE}Setting SMTP configuration...${NC}"

if [[ "$AUTH_REQUIRED" == "y" || "$AUTH_REQUIRED" == "Y" ]]; then
    yunohost app shell nextcloud << EOF
php occ config:system:set mail_smtpmode --value="smtp"
php occ config:system:set mail_smtphost --value="$SMTP_HOST"
php occ config:system:set mail_smtpport --value="$SMTP_PORT" --type=integer
php occ config:system:set mail_smtpauth --value=true --type=boolean
php occ config:system:set mail_smtpname --value="$SMTP_USER"
php occ config:system:set mail_smtppassword --value="$SMTP_PASSWORD"
php occ config:system:set mail_smtpsecure --value="$SMTP_SECURITY"
php occ config:system:set mail_from_address --value="$FROM_EMAIL"
php occ config:system:set mail_domain --value="$MAIL_DOMAIN"
php occ config:system:set mail_smtpauthtype --value="LOGIN"
php occ config:system:set mail_smtpdebug --value="false" --type=boolean
php occ config:system:set mail_smtptimeout --value="10" --type=integer
php occ config:system:set mail_smtphelo --value="$SMTP_HOST"
php occ config:system:set mail_from_name --value="$SERVER_NAME"
EOF
else
    yunohost app shell nextcloud << EOF
php occ config:system:set mail_smtpmode --value="smtp"
php occ config:system:set mail_smtphost --value="$SMTP_HOST"
php occ config:system:set mail_smtpport --value="$SMTP_PORT" --type=integer
php occ config:system:set mail_smtpauth --value=false --type=boolean
php occ config:system:set mail_smtpsecure --value="$SMTP_SECURITY"
php occ config:system:set mail_from_address --value="$FROM_EMAIL"
php occ config:system:set mail_domain --value="$MAIL_DOMAIN"
php occ config:system:set mail_smtpauthtype --value="LOGIN"
php occ config:system:set mail_smtpdebug --value="false" --type=boolean
php occ config:system:set mail_smtptimeout --value="10" --type=integer
php occ config:system:set mail_smtphelo --value="$SMTP_HOST"
php occ config:system:set mail_from_name --value="$SERVER_NAME"
EOF
fi

# Additional mail settings (optional)
if [[ -n "$FROM_NAME" ]]; then
    yunohost app shell nextcloud << EOF
php occ config:system:set mail_from_name --value="$FROM_NAME"
EOF
fi

echo -e "${GREEN}SMTP configuration successfully set!${NC}"
echo

# Send test mail (optional)
echo -e "${YELLOW}Do you want to verify the SMTP configuration? (Y/n)${NC}"
read -p "Answer: " TEST_MAIL
TEST_MAIL=${TEST_MAIL:-Y}

if [[ "$TEST_MAIL" == "y" || "$TEST_MAIL" == "Y" ]]; then
    echo -e "${BLUE}Checking SMTP configuration...${NC}"
    yunohost app shell nextcloud << EOF
php -r '
require_once("/var/www/nextcloud/lib/base.php");
require_once("/var/www/nextcloud/lib/private/Server.php");

try {
    \$server = new \OC\Server(\OC::$CONFIG);
    \$config = \$server->getConfig();
    
    echo "SMTP Configuration Status:\n";
    echo "-------------------------\n";
    echo "SMTP Mode: " . \$config->getSystemValue("mail_smtpmode", "not set") . "\n";
    echo "SMTP Host: " . \$config->getSystemValue("mail_smtphost", "not set") . "\n";
    echo "SMTP Port: " . \$config->getSystemValue("mail_smtpport", "not set") . "\n";
    echo "SMTP Security: " . \$config->getSystemValue("mail_smtpsecure", "not set") . "\n";
    echo "SMTP Auth: " . (\$config->getSystemValue("mail_smtpauth", false) ? "enabled" : "disabled") . "\n";
    echo "From Address: " . \$config->getSystemValue("mail_from_address", "not set") . "\n";
    echo "From Name: " . \$config->getSystemValue("mail_from_name", "not set") . "\n";
    echo "Domain: " . \$config->getSystemValue("mail_domain", "not set") . "\n";
    
    echo "\nTo test the mail functionality, you can:\n";
    echo "1. Go to your Nextcloud web interface\n";
    echo "2. Click on your profile picture in the top right\n";
    echo "3. Select 'Settings'\n";
    echo "4. Go to 'Sharing' or 'Notifications'\n";
    echo "5. Try to share a file or trigger a notification\n";
    echo "\nThis will help verify if the SMTP configuration is working correctly.\n";
} catch (Exception \$e) {
    echo "Error checking configuration: " . \$e->getMessage() . "\n";
}
'
EOF
fi

echo
echo -e "${GREEN}=== Configuration completed ===${NC}"
echo -e "${BLUE}Current mail configuration:${NC}"

# Show current configuration (without password)
yunohost app shell nextcloud << 'EOF'
echo "SMTP Host: $(php occ config:system:get mail_smtphost)"
echo "SMTP Port: $(php occ config:system:get mail_smtpport)"
echo "SMTP Security: $(php occ config:system:get mail_smtpsecure)"
echo "SMTP User: $(php occ config:system:get mail_smtpname)"
echo "Sender Email: $(php occ config:system:get mail_from_address)"
echo "Sender Name: $(php occ config:system:get mail_from_name)"
EOF

echo
echo -e "${YELLOW}Backup of previous configuration: $BACKUP_FILE${NC}"
echo -e "${YELLOW}In case of problems, you can restore the old configuration with:${NC}"
echo -e "${BLUE}sudo cp $BACKUP_FILE /var/www/nextcloud/config/config.php${NC}"

# Create restore script
cat > /tmp/restore_nextcloud_smtp.sh << 'RESTORE_EOF'
#!/bin/bash
# Restore Nextcloud SMTP Configuration

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

BACKUP_FILE="$1"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring Nextcloud configuration..."
cp "$BACKUP_FILE" /var/www/nextcloud/config/config.php
chown www-data:www-data /var/www/nextcloud/config/config.php
echo "Configuration restored!"
RESTORE_EOF

chmod +x /tmp/restore_nextcloud_smtp.sh
echo -e "${BLUE}Restore script created: /tmp/restore_nextcloud_smtp.sh${NC}"
echo
echo -e "${GREEN}Done! Your Nextcloud SMTP configuration is now set.${NC}"