#!/bin/bash

# Configuration
DOMAIN="nexoplus.in"
DEPLOY_PATH="/var/www/nexoplus"
NGINX_CONF="/etc/nginx/sites-available/nexoplus"
EMAIL="info@nexoplus.com"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting Nexoplus deployment...${NC}"

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
sudo apt install -y nginx certbot python3-certbot-nginx git

# Create web directory if it doesn't exist
echo -e "${YELLOW}Setting up web directory...${NC}"
sudo mkdir -p $DEPLOY_PATH
sudo chown -R www-data:www-data $DEPLOY_PATH

# Pull latest code
echo -e "${YELLOW}Pulling latest code...${NC}"
cd $DEPLOY_PATH
git pull origin main

# Configure Nginx
echo -e "${YELLOW}Configuring Nginx...${NC}"
sudo cat > $NGINX_CONF << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    root $DEPLOY_PATH;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    # Enable GZIP compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
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

# Install SSL certificate
echo -e "${YELLOW}Setting up SSL certificate...${NC}"
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect

# Set permissions
echo -e "${YELLOW}Setting proper permissions...${NC}"
sudo chown -R www-data:www-data $DEPLOY_PATH
sudo find $DEPLOY_PATH -type f -exec chmod 644 {} \;
sudo find $DEPLOY_PATH -type d -exec chmod 755 {} \;

# Setup auto-renewal for SSL
echo -e "${YELLOW}Setting up SSL auto-renewal...${NC}"
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}Website is now live at https://$DOMAIN${NC}"

# Print useful information
echo -e "\n${YELLOW}Useful Commands:${NC}"
echo "- Check Nginx status: sudo systemctl status nginx"
echo "- View Nginx error logs: sudo tail -f /var/log/nginx/error.log"
echo "- View SSL certificate status: sudo certbot certificates"
echo "- Force SSL renewal: sudo certbot renew --force-renewal" 