#!/bin/bash

# Check if running as root (needed for Apache operations)
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo or as root"
    exit 1
fi

# Get user input
read -p "Enter the hostname (e.g., axiomverify): " hostname
read -p "Enter the IP address (e.g., 192.168.1.68): " ip_address

# Validate input
if [ -z "$hostname" ] || [ -z "$ip_address" ]; then
    echo "Error: Hostname and IP address cannot be empty"
    exit 1
fi

# Set config file path
config_file="/etc/apache2/sites-available/${hostname}.com.conf"

# Check if file already exists
if [ -f "$config_file" ]; then
    echo "Error: Config file ${config_file} already exists"
    exit 1
fi

# Create the config file with the template
cat > "$config_file" << EOF
<VirtualHost *:80>
    ServerName ${hostname}.com
    ServerAlias www.${hostname}.com

    ProxyPreserveHost on
    ProxyPass / http://$ip_address/
    ProxyPassReverse / http://$ip_address/

    ErrorLog \${APACHE_LOG_DIR}/${hostname}.com-error.log
    CustomLog \${APACHE_LOG_DIR}/${hostname}.com-access.log combined
</VirtualHost>
EOF

# Check if file was created successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to create config file"
    exit 1
fi

# Enable the site
a2ensite "${hostname}.com.conf"

# Check if site was enabled successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to enable site"
    rm "$config_file"  # Clean up the created file
    exit 1
fi

# Restart Apache
systemctl restart apache2

# Check if Apache restarted successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to restart Apache"
    exit 1
fi

echo "Success! Site ${hostname}.com has been configured and enabled"
echo "Config file created at: ${config_file}"