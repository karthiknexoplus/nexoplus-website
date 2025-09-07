#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DEPLOY_PATH="/var/www/nexoplus"

echo -e "${YELLOW}Checking website deployment status...${NC}\n"

# Check directory exists
echo -e "1. Checking deployment directory..."
if [ -d "$DEPLOY_PATH" ]; then
    echo -e "${GREEN}✓ Directory exists: $DEPLOY_PATH${NC}"
else
    echo -e "${RED}✗ Directory missing: $DEPLOY_PATH${NC}"
fi

# Check index.html exists and is readable
echo -e "\n2. Checking index.html..."
if [ -f "$DEPLOY_PATH/index.html" ]; then
    echo -e "${GREEN}✓ index.html exists${NC}"
    if [ -r "$DEPLOY_PATH/index.html" ]; then
        echo -e "${GREEN}✓ index.html is readable${NC}"
        echo -e "${YELLOW}First few lines of index.html:${NC}"
        head -n 5 "$DEPLOY_PATH/index.html"
    else
        echo -e "${RED}✗ index.html is not readable${NC}"
    fi
else
    echo -e "${RED}✗ index.html is missing${NC}"
fi

# Check permissions
echo -e "\n3. Checking permissions..."
echo -e "Directory ownership:"
ls -ld "$DEPLOY_PATH"
echo -e "\nindex.html ownership:"
ls -l "$DEPLOY_PATH/index.html"

# Check Nginx configuration
echo -e "\n4. Checking Nginx configuration..."
if sudo nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓ Nginx configuration is valid${NC}"
else
    echo -e "${RED}✗ Nginx configuration has errors${NC}"
fi

# Check if Nginx is running
echo -e "\n5. Checking Nginx status..."
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx is running${NC}"
else
    echo -e "${RED}✗ Nginx is not running${NC}"
fi

# Check site configuration
echo -e "\n6. Checking site configuration..."
if [ -f "/etc/nginx/sites-available/nexoplus" ]; then
    echo -e "${GREEN}✓ Site configuration exists${NC}"
    echo -e "${YELLOW}Site configuration:${NC}"
    cat "/etc/nginx/sites-available/nexoplus"
else
    echo -e "${RED}✗ Site configuration is missing${NC}"
fi

# Check if site is enabled
echo -e "\n7. Checking if site is enabled..."
if [ -L "/etc/nginx/sites-enabled/nexoplus" ]; then
    echo -e "${GREEN}✓ Site is enabled${NC}"
else
    echo -e "${RED}✗ Site is not enabled${NC}"
fi

echo -e "\n${YELLOW}Recommended actions:${NC}"
echo "1. sudo -u www-data git pull"
echo "2. sudo chown -R www-data:www-data $DEPLOY_PATH"
echo "3. sudo chmod -R 755 $DEPLOY_PATH"
echo "4. sudo systemctl restart nginx" 