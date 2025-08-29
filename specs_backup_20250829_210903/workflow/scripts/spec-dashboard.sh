#!/bin/bash
# Persistent Spec Dashboard - Runs in separate terminal
# This allows you to keep working with Claude while monitoring progress

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to count specs
count_completed() {
    find specs -name "*.context.md" -exec grep -l "Status**: completed" {} \; 2>/dev/null | wc -l
}

count_in_progress() {
    find specs -name "*.context.md" -exec grep -l "Status**: in_progress" {} \; 2>/dev/null | wc -l
}

count_total_specs() {
    find specs -name "*.md" -not -name "*.context.md" -not -name "index.md" -not -name "README.md" | wc -l
}

# Function to show progress bar
show_progress_bar() {
    local current=$1
    local total=$2
    local width=20
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    
    printf "["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=filled; i<width; i++)); do printf "░"; done
    printf "] %d%%" "$percentage"
}

# Main dashboard loop
while true; do
    clear
    
    # Header
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║             📊 JTS SPEC DASHBOARD - LIVE VIEW 📊             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Get current stats
    COMPLETED=$(count_completed)
    IN_PROGRESS=$(count_in_progress)
    TOTAL=$(count_total_specs)
    
    # Key Metrics
    echo -e "${BOLD}📈 KEY METRICS${NC}"
    echo -e "├─ Total Specs: ${BLUE}$TOTAL${NC}"
    echo -e "├─ Completed: ${GREEN}$COMPLETED${NC} ✅"
    echo -e "├─ In Progress: ${YELLOW}$IN_PROGRESS${NC} 🚧"
    echo -e "├─ Overall Progress: $(show_progress_bar $COMPLETED $TOTAL)"
    echo -e "└─ Last Update: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Recent Context Files (shows actual work)
    echo -e "${BOLD}📅 RECENT ACTIVITY${NC}"
    find specs -name "*.context.md" -type f -exec ls -lt {} \; 2>/dev/null | \
        head -5 | while read -r line; do
        file=$(echo "$line" | awk '{print $NF}')
        basename "$file" | sed 's/.context.md//' | while read spec_id; do
            echo "├─ $spec_id"
        done
    done
    echo ""
    
    # Show recently modified specs
    echo -e "${BOLD}🔥 RECENTLY MODIFIED SPECS${NC}"
    find specs -name "*.md" -not -name "*.context.md" -not -name "index.md" \
        -type f -exec ls -lt {} \; 2>/dev/null | head -5 | \
        while read -r line; do
        file=$(echo "$line" | awk '{print $NF}')
        echo "├─ $(basename "$file")"
    done
    echo ""
    
    # Footer
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Auto-refreshing every 5 seconds... Press Ctrl+C to exit"
    echo -e "Run in separate terminal: ${GREEN}./scripts/spec-dashboard.sh${NC}"
    
    sleep 5
done