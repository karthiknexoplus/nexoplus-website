#!/bin/bash

# Configuration
DOMAIN="nexoplus.in"
DEPLOY_PATH="/var/www/nexoplus"
NGINX_CONF="/etc/nginx/sites-available/nexoplus"
EMAIL="info@nexoplus.com"
SERVER_IP=$(curl -s ifconfig.me)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check DNS
check_dns() {
    echo -e "${YELLOW}Checking DNS configuration for $DOMAIN...${NC}"
    
    # Get the current IP that domain points to
    DOMAIN_IP=$(dig +short $DOMAIN)
    
    if [ -z "$DOMAIN_IP" ]; then
        echo -e "${RED}ERROR: Domain $DOMAIN is not configured in DNS${NC}"
        echo -e "Please configure your domain to point to this server's IP: ${GREEN}$SERVER_IP${NC}"
        echo -e "Required DNS Records:"
        echo -e "  A Record: $DOMAIN → $SERVER_IP"
        echo -e "  A Record: www.$DOMAIN → $SERVER_IP"
        echo -e "\nWould you like to continue without SSL? (y/n)"
        read -r response
        if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
            exit 1
        fi
        return 1
    elif [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
        echo -e "${RED}WARNING: Domain $DOMAIN points to $DOMAIN_IP, but your server IP is $SERVER_IP${NC}"
        echo -e "Please update your DNS records or wait for DNS propagation"
        echo -e "\nWould you like to continue without SSL? (y/n)"
        read -r response
        if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
            exit 1
        fi
        return 1
    else
        echo -e "${GREEN}DNS configuration is correct!${NC}"
        return 0
    fi
}

# Function to setup SSL
setup_ssl() {
    echo -e "${YELLOW}Setting up SSL certificate...${NC}"
    if sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect; then
        echo -e "${GREEN}SSL certificate installed successfully!${NC}"
        return 0
    else
        echo -e "${RED}SSL certificate installation failed${NC}"
        echo -e "Possible reasons:"
        echo -e "1. DNS is not properly configured"
        echo -e "2. DNS changes haven't propagated yet (can take up to 48 hours)"
        echo -e "3. Port 80/443 not accessible from internet"
        echo -e "\nYou can try again later using: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
        return 1
    fi
}

# Function to setup Git permissions
setup_git() {
    echo -e "${YELLOW}Setting up Git permissions...${NC}"
    
    # Add the directory to Git's safe directories
    sudo git config --system --add safe.directory $DEPLOY_PATH
    
    # Set proper ownership
    sudo chown -R www-data:www-data $DEPLOY_PATH
    
    # Make sure Git operations can be performed
    sudo -u www-data git config --global --add safe.directory $DEPLOY_PATH
    
    echo -e "${GREEN}Git permissions configured successfully!${NC}"
}

echo -e "${GREEN}Starting Nexoplus deployment...${NC}"

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
sudo apt install -y nginx certbot python3-certbot-nginx git dnsutils

# Create web directory if it doesn't exist
echo -e "${YELLOW}Setting up web directory...${NC}"
sudo mkdir -p $DEPLOY_PATH

# Setup Git permissions
setup_git

# Pull latest code
echo -e "${YELLOW}Pulling latest code...${NC}"
cd $DEPLOY_PATH
sudo -u www-data git pull

# Configure Nginx
echo -e "${YELLOW}Configuring Nginx...${NC}"
sudo cat > $NGINX_CONF << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    root $DEPLOY_PATH;
    index index.html;

    # Allow Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        allow all;
        root /var/www/html;
    }

    location / {
        try_files \$uri \$uri/ =404;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    # Enable GZIP compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Disable server tokens
    server_tokens off;
}
EOF

# Enable the site
echo -e "${YELLOW}Enabling Nginx site configuration...${NC}"
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
sudo nginx -t

# Restart Nginx
echo -e "${YELLOW}Restarting Nginx...${NC}"
sudo systemctl restart nginx

# Check DNS and setup SSL
check_dns
DNS_OK=$?
if [ $DNS_OK -eq 0 ]; then
    setup_ssl
fi

# Set permissions
echo -e "${YELLOW}Setting proper permissions...${NC}"
sudo chown -R www-data:www-data $DEPLOY_PATH
sudo find $DEPLOY_PATH -type f -exec chmod 644 {} \;
sudo find $DEPLOY_PATH -type d -exec chmod 755 {} \;

# Setup auto-renewal for SSL
if [ $DNS_OK -eq 0 ]; then
    echo -e "${YELLOW}Setting up SSL auto-renewal...${NC}"
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
fi

echo -e "${GREEN}Deployment completed!${NC}"
if [ $DNS_OK -eq 0 ]; then
    echo -e "${GREEN}Website is now live at https://$DOMAIN${NC}"
else
    echo -e "${YELLOW}Website is accessible at http://$SERVER_IP${NC}"
    echo -e "${YELLOW}Please configure your DNS and run this script again to setup SSL${NC}"
fi

# Print useful information
echo -e "\n${YELLOW}Useful Commands:${NC}"
echo "- Check Nginx status: sudo systemctl status nginx"
echo "- View Nginx error logs: sudo tail -f /var/log/nginx/error.log"
echo "- View SSL certificate status: sudo certbot certificates"
echo "- Force SSL renewal: sudo certbot renew --force-renewal"
echo "- Check DNS propagation: dig +short $DOMAIN"
echo "- Your server IP: $SERVER_IP"
echo "- Update website: cd $DEPLOY_PATH && sudo -u www-data git pull" 