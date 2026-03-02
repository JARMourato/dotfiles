#!/bin/bash

# Smart backup script using arr apps' built-in backup APIs
echo "Creating API-based backups of arr services..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create backup directory
BACKUP_DIR="api-backups"
mkdir -p "$BACKUP_DIR"

# Function to trigger and download backup
backup_arr_service() {
    local SERVICE_NAME="$1"
    local PORT="$2"
    local API_KEY="$3"
    
    echo -e "\n${YELLOW}Backing up $SERVICE_NAME...${NC}"
    
    # Trigger backup
    echo "  Triggering backup..."
    RESPONSE=$(curl -s -X POST "http://localhost:${PORT}/api/v3/command" \
        -H "X-Api-Key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"name": "Backup"}')
    
    COMMAND_ID=$(echo "$RESPONSE" | jq -r '.id')
    
    if [ "$COMMAND_ID" == "null" ]; then
        echo -e "  ${RED}✗ Failed to trigger backup${NC}"
        return 1
    fi
    
    # Wait for backup to complete
    echo "  Waiting for backup to complete..."
    for i in {1..30}; do
        STATUS=$(curl -s "http://localhost:${PORT}/api/v3/command/${COMMAND_ID}" \
            -H "X-Api-Key: ${API_KEY}" | jq -r '.status')
        
        if [ "$STATUS" == "completed" ]; then
            break
        fi
        sleep 1
    done
    
    # Get latest backup
    LATEST_BACKUP=$(curl -s "http://localhost:${PORT}/api/v3/system/backup" \
        -H "X-Api-Key: ${API_KEY}" | jq -r '.[0]')
    
    if [ "$LATEST_BACKUP" != "null" ]; then
        BACKUP_NAME=$(echo "$LATEST_BACKUP" | jq -r '.name')
        
        # Copy backup to our directory
        CONTAINER_NAME=$(echo "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]')
        # Try different possible backup locations
        BACKUP_COPIED=0
        for BACKUP_PATH in "/config/Backups/manual/${BACKUP_NAME}" "/config/Backups/scheduled/${BACKUP_NAME}"; do
            docker cp "${CONTAINER_NAME}:${BACKUP_PATH}" "${BACKUP_DIR}/${BACKUP_NAME}" 2>/dev/null
            if [ $? -eq 0 ]; then
                BACKUP_COPIED=1
                break
            fi
        done
        
        # For Prowlarr, also check the scheduled subdirectory
        if [ $BACKUP_COPIED -eq 0 ] && [ "$SERVICE_NAME" == "Prowlarr" ]; then
            mkdir -p "${BACKUP_DIR}/scheduled"
            docker cp "${CONTAINER_NAME}:/config/Backups/scheduled/${BACKUP_NAME}" "${BACKUP_DIR}/scheduled/${BACKUP_NAME}" 2>/dev/null
            if [ $? -eq 0 ]; then
                BACKUP_COPIED=1
                BACKUP_NAME="scheduled/${BACKUP_NAME}"
            fi
        fi
        
        if [ $BACKUP_COPIED -eq 1 ]; then
            echo -e "  ${GREEN}✓ Backup saved: ${BACKUP_NAME}${NC}"
            return 0
        fi
    fi
    
    echo -e "  ${RED}✗ Failed to retrieve backup${NC}"
    return 1
}

# Backup each service
backup_arr_service "Sonarr" "8989" "dbb6c3960f324002b095db1c628a2056"
backup_arr_service "Radarr" "7878" "7b2a06f2dbfb4bc8ac2f9ed23339a92f"
backup_arr_service "Prowlarr" "9696" "${PROWLARR_API_KEY:-3c57df672ee04a30a4e893cc96f46a75}"
# Note: Bazarr doesn't support the same API backup structure as *arr services

# Backup other configuration files
echo -e "\n${YELLOW}Backing up configuration files...${NC}"
tar -czf "${BACKUP_DIR}/config-files.tar.gz" \
    docker-compose.yml \
    .env \
    backup*.sh \
    restore*.sh \
    README.md \
    2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Configuration files backed up${NC}"
fi

# Create a manifest
echo -e "\n${YELLOW}Creating backup manifest...${NC}"
cat > "${BACKUP_DIR}/manifest.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "services": [
    "sonarr",
    "radarr",
    "prowlarr"
  ],
  "files": $(ls -1 "$BACKUP_DIR" | jq -R . | jq -s .)
}
EOF

# Show backup summary
echo -e "\n${GREEN}=== Backup Summary ===${NC}"
echo "Location: $BACKUP_DIR/"
echo "Contents:"
ls -lh "$BACKUP_DIR/"
echo ""
echo "Total size: $(du -sh "$BACKUP_DIR" | cut -f1)"

# Git operations
echo -e "\n${YELLOW}Uploading to GitHub...${NC}"
git add "$BACKUP_DIR"
git commit -m "API Backup: $(date +%Y-%m-%d' '%H:%M:%S)"
git push

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Backup uploaded to GitHub successfully!${NC}"
else
    echo -e "\n${YELLOW}⚠️  Backup created but failed to push to GitHub${NC}"
    echo "Run 'git push' manually when connection is available"
fi