# Nextcloud SMTP Configuration Helper Scripts

> 🚧 **BETA VERSION** 🚧
> 
> This project is currently in beta stage. While the basic functionality is working,
> some features might need manual adjustments. Please report any issues you encounter.

This repository contains helper scripts for configuring SMTP settings in Nextcloud instances. The scripts are designed to work with YunoHost installations but might work with other Nextcloud setups as well.

## Features

- Simple SMTP configuration through command line
- Support for both authenticated and non-authenticated SMTP servers
- Default configuration for local SMTP servers
- Configuration backup and restore functionality

## Available Script

### `configure_nextcloud_smtp.sh`
A shell script to configure SMTP settings for Nextcloud.

## Usage

1. Make the script executable:
   ```bash
   chmod +x configure_nextcloud_smtp.sh
   ```

2. Run the script as root:
   ```bash
   sudo ./configure_nextcloud_smtp.sh
   ```

3. Follow the interactive prompts to configure your SMTP settings.

## Default Values

- SMTP Server: localhost
- SMTP Port: 587
- SMTP Security: tls
- Authentication: disabled by default
- Sender Name: "Nextcloud Server"

## Requirements

- A running Nextcloud instance
- Shell access to the server
- Root privileges
- YunoHost (recommended)

## Known Limitations

- Test mail functionality is limited to configuration verification
- Some Nextcloud versions might require additional manual configuration
- Boolean configuration values might need manual adjustment in some cases

## Backup and Restore

The script automatically creates a backup of your Nextcloud configuration before making changes. You can restore the previous configuration using:

```bash
sudo cp /var/www/nextcloud/config/config.php.backup.[TIMESTAMP] /var/www/nextcloud/config/config.php
```

A restore script is also created at `/tmp/restore_nextcloud_smtp.sh`.

## License

This project is open source and available under the MIT License.

## Contributing

Your feedback and contributions are welcome! Please report any issues you encounter and feel free to submit pull requests for improvements. 