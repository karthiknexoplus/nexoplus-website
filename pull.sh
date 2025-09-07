#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DEPLOY_PATH="/var/www/nexoplus"

echo -e "${YELLOW}Starting website update...${NC}"

# Ensure we're in the right directory
cd $DEPLOY_PATH || {
    echo -e "${RED}Failed to change to $DEPLOY_PATH${NC}"
    exit 1
}

# Configure Git safety
echo -e "${YELLOW}Configuring Git permissions...${NC}"
sudo git config --system --add safe.directory $DEPLOY_PATH 2>/dev/null

# Pull latest changes
echo -e "${YELLOW}Pulling latest changes...${NC}"
sudo -u www-data git pull

# Fix permissions
echo -e "${YELLOW}Updating permissions...${NC}"
sudo chown -R www-data:www-data $DEPLOY_PATH

echo -e "${GREEN}Update completed!${NC}" 