# Nextcloud SMTP Configuration Helper Scripts

> 🚧 **BETA VERSION** 🚧
> 
> This project is currently in beta stage. While the basic functionality is working,
> some features might need manual adjustments. Please report any issues you encounter.

This repository contains helper scripts for configuring SMTP settings in Nextcloud instances. The scripts are designed to work with YunoHost installations but might work with other Nextcloud setups as well.

## Purpose

This script was created to solve a common issue in YunoHost Nextcloud installations: While YunoHost provides a built-in SMTP server and configuration, Nextcloud's mail settings are not automatically synchronized with YunoHost's SMTP configuration. This can lead to:

- Nextcloud notifications not being sent
- Password reset emails not working
- Share notifications failing
- Other email-dependent features not functioning

The script bridges this gap by:
1. Configuring Nextcloud to use YunoHost's local SMTP server by default
2. Allowing easy configuration of external SMTP servers if needed
3. Providing a simple way to test and verify the mail configuration

This is particularly important because:
- Nextcloud's default mail settings don't work out of the box with YunoHost
- Manual configuration through the web interface can be error-prone
- Email functionality is crucial for many Nextcloud features
- YunoHost's built-in SMTP server is often the most reliable option for self-hosted instances

> **Note:** While these settings can also be configured using a series of `occ config:system:set` commands, this script provides a more user-friendly and less error-prone way to set up the SMTP configuration. It handles all the necessary commands, creates backups, and provides verification steps in a single, easy-to-use interface.

## Multiple Nextcloud Instances

When running multiple Nextcloud instances on YunoHost (e.g., cloud1.domain.xy, cloud2.domain.xy), there's a specific issue with email delivery:

- The default sender address for additional instances (e.g., cloud2.domain.xy) often causes delivery problems
- Major email providers (like Google) may reject these emails due to the subdomain in the sender address
- Despite YunoHost's proper SPF, DKIM, and other anti-spam configurations
- This configuration is typically reset during Nextcloud updates/upgrades

This script helps maintain the correct sender address configuration, ensuring that:
- Emails are sent from the main domain (domain.xy) instead of the subdomain
- The configuration persists across updates
- Email delivery to major providers remains reliable

## Features

- Simple SMTP configuration through command line
- Support for both authenticated and non-authenticated SMTP servers
- Default configuration for local SMTP servers
- Configuration backup and restore functionality
- Proper sender address configuration for multiple instances

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