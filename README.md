# Nextcloud SMTP Configuration Helper Scripts

> ⚠️ **WARNING: ALPHA VERSION** ⚠️
> 
> This project is currently in alpha stage and work in progress. Use at your own risk.
> Some features might not work as expected and the configuration might need manual adjustments.

This repository contains helper scripts for configuring SMTP settings in Nextcloud instances.

## Available Scripts

### `configure_nextcloud_smtp.sh`
A shell script to configure SMTP settings for Nextcloud. This script helps automate the process of setting up email notifications in your Nextcloud instance.

### `konfiguriere_nextcloud_smtp.sh`
German version of the SMTP configuration script.

## Usage

To use the configuration script:

1. Make the script executable:
   ```bash
   chmod +x configure_nextcloud_smtp.sh
   ```

2. Run the script:
   ```bash
   ./configure_nextcloud_smtp.sh
   ```

## Requirements

- A running Nextcloud instance
- Shell access to the server
- Appropriate permissions to modify Nextcloud configuration

## Known Issues

- Boolean configuration values might need manual adjustment
- Test mail functionality might not work in all environments
- Some Nextcloud versions might require additional configuration

## License

This project is open source and available under the MIT License.

## Contributing

Feel free to submit issues and enhancement requests! Since this is a work in progress, your feedback and contributions are especially valuable. 