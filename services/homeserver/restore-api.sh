#!/bin/bash

# Restore script for API-based backups
echo "Restoring from API-based backups..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BACKUP_DIR="api-backups"

if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}❌ Backup directory not found: $BACKUP_DIR${NC}"
    echo "Please ensure you've cloned the repository with backups"
    exit 1
fi

# Function to restore arr service
restore_arr_service() {
    local SERVICE_NAME="$1"
    local CONTAINER_NAME=$(echo "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]')
    
    echo -e "\n${YELLOW}Restoring $SERVICE_NAME...${NC}"
    
    # Find backup file (get the most recent one by sorting, check both main and scheduled folders)
    BACKUP_FILE=$(find "$BACKUP_DIR" -maxdepth 2 -name "${CONTAINER_NAME}_backup_*.zip" -type f | xargs -I {} basename {} | sort -r | head -1)
    
    # Find the full path of the backup file
    if [ -n "$BACKUP_FILE" ]; then
        FULL_PATH=$(find "$BACKUP_DIR" -maxdepth 2 -name "$BACKUP_FILE" -type f | head -1)
    fi
    
    if [ -z "$BACKUP_FILE" ]; then
        echo -e "  ${RED}✗ No backup found for $SERVICE_NAME${NC}"
        return 1
    fi
    
    echo "  Found backup: $BACKUP_FILE"
    
    # Copy backup to container and place in proper location
    docker cp "${FULL_PATH}" "${CONTAINER_NAME}:/tmp/${BACKUP_FILE}"
    
    if [ $? -eq 0 ]; then
        # Also copy to the proper backup directory for arr apps
        docker exec "${CONTAINER_NAME}" mkdir -p /config/Backups/manual 2>/dev/null
        docker exec "${CONTAINER_NAME}" cp "/tmp/${BACKUP_FILE}" /config/Backups/manual/ 2>/dev/null
        docker exec "${CONTAINER_NAME}" chown -R abc:users /config/Backups 2>/dev/null
        
        echo -e "  ${GREEN}✓ Backup copied to container${NC}"
        echo -e "  ${YELLOW}Note: To restore in $SERVICE_NAME:${NC}"
        echo "    1. Go to System > Backup in the web UI"
        echo "    2. Click 'Restore' next to the uploaded backup"
        echo "    3. Restart the container after restoration"
        return 0
    else
        echo -e "  ${RED}✗ Failed to copy backup${NC}"
        return 1
    fi
}

# Restore configuration files
if [ -f "${BACKUP_DIR}/config-files.tar.gz" ]; then
    echo -e "\n${YELLOW}Restoring configuration files...${NC}"
    tar -xzf "${BACKUP_DIR}/config-files.tar.gz"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Configuration files restored${NC}"
    fi
fi

# Start services if not running
echo -e "\n${YELLOW}Starting services...${NC}"
docker compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Restore each service
restore_arr_service "Sonarr"
restore_arr_service "Radarr"
restore_arr_service "Prowlarr"

echo -e "\n${GREEN}=== Restore Summary ===${NC}"
echo "Backup files have been uploaded to the containers."
echo ""
echo "${YELLOW}Important: Manual steps required:${NC}"
echo "1. Access each service's web UI:"
echo "   - Sonarr: http://localhost:8989"
echo "   - Radarr: http://localhost:7878"
echo "   - Prowlarr: http://localhost:9696"
echo "2. Go to System > Backup"
echo "3. Click 'Restore' on the uploaded backup"
echo "4. Restart containers after restoration:"
echo "   docker compose restart"
echo ""
echo "${YELLOW}Note:${NC} The arr apps require manual restoration through their UI"
echo "for security reasons. This ensures data integrity."