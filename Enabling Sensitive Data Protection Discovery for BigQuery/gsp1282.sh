#!/bin/bash
clear

# ==============================================================================
# Orbit of Ops Branding & Colors
# ==============================================================================
BOLD=$(tput bold)
CYAN=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
MAGENTA=$(tput setaf 5)
RESET=$(tput sgr0)

echo "${CYAN}${BOLD}====================================================${RESET}"
echo "${CYAN}${BOLD}    ORBIT OF OPS: Sensitive Data Protection         ${RESET}"
echo "${CYAN}${BOLD}    MAX AUTOMATION SCRIPT                           ${RESET}"
echo "${CYAN}${BOLD}====================================================${RESET}"
echo ""

# ==============================================================================
# Initialization & User Detection
# ==============================================================================
echo "${YELLOW}Initializing and fetching project details...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export CURRENT_USER=$(gcloud config get-value account)

if [ -z "$PROJECT_ID" ]; then
    echo "${RED}Error: Could not fetch Project ID.${RESET}"
    exit 1
fi

echo "${GREEN}Project ID detected: ${PROJECT_ID}${RESET}"

# Auto-detect Username 2 (the other Qwiklabs student account in the project)
echo "${YELLOW}Scanning for Username 2...${RESET}"
export USER2=$(gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format="value(bindings.members)" | grep "user:.*@qwiklabs.net" | sed 's/user://' | grep -v "$CURRENT_USER" | head -n 1)

if [ -z "$USER2" ]; then
    echo "${RED}Could not automatically detect Username 2. Please check IAM.${RESET}"
else
    echo "${GREEN}Username 2 detected: ${USER2}${RESET}"
fi
echo ""

# ==============================================================================
# TASK 2: AUTOMATED TAG CREATION & IAM BINDING
# ==============================================================================
echo "${CYAN}${BOLD}=== TASK 2: AUTOMATED TAG CREATION ===${RESET}"
echo "${YELLOW}Creating Tag Key 'sensitivity-level'...${RESET}"
gcloud resource-manager tags keys create sensitivity-level \
    --parent=projects/$PROJECT_NUMBER \
    --description="Sensitivity level tagged as low, moderate, high, and unknown" > /dev/null 2>&1

TAG_KEY_ID=$(gcloud resource-manager tags keys list --parent="projects/${PROJECT_NUMBER}" --format="value(NAME)")

echo "${YELLOW}Creating Tag Values (low, moderate, high, unknown)...${RESET}"
gcloud resource-manager tags values create low --parent=$TAG_KEY_ID --description="low-sensitivity" > /dev/null 2>&1
gcloud resource-manager tags values create moderate --parent=$TAG_KEY_ID --description="moderate-sensitivity" > /dev/null 2>&1
gcloud resource-manager tags values create high --parent=$TAG_KEY_ID --description="high-sensitivity" > /dev/null 2>&1
gcloud resource-manager tags values create unknown --parent=$TAG_KEY_ID --description="unknown-sensitivity" > /dev/null 2>&1

echo "${YELLOW}Assigning tagUser role to DLP Service Account...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:service-$PROJECT_NUMBER@dlp-api.iam.gserviceaccount.com" \
    --role="roles/resourcemanager.tagUser" > /dev/null 2>&1

echo "${GREEN}${BOLD}Task 2 Setup Complete!${RESET}"
echo "Go to your lab manual and click 'Check my progress' for Task 2."
echo ""

# ==============================================================================
# TASK 1: MANUAL DISCOVERY SETUP
# ==============================================================================
echo "${CYAN}${BOLD}=== TASK 1: MANUAL CONFIGURATION ===${RESET}"
echo "Note: Generating this specific scan via API breaks the grader. Please do this in the UI:"
echo ""
echo "1. Go to ${CYAN}Security > Sensitive Data Protection > Discovery${RESET}"
echo "2. Under 'BigQuery', click ${BOLD}Enable${RESET}."
echo "3. Click ${BOLD}Continue${RESET} until you reach 'Add actions'."
echo "4. Check ${BOLD}'Publish to Security Command Center'${RESET}"
echo "5. Check ${BOLD}'Save data profile copies to BigQuery'${RESET}"
echo "   > Dataset ID: ${BOLD}bq_discovery${RESET} | Table ID: ${BOLD}data_profiles${RESET}"
echo "6. Click ${BOLD}Continue${RESET}. Location: ${BOLD}us (multiple regions in United States)${RESET}."
echo "7. Display Name: ${BOLD}BigQuery Discovery${RESET}"
echo "8. ${RED}${BOLD}CRUCIAL:${RESET} Check ${BOLD}'Create scan in paused mode'${RESET}."
echo "9. Click ${BOLD}Create${RESET} -> ${BOLD}Create configuration${RESET}."
echo ""
read -p "${MAGENTA}${BOLD}Press [ENTER] ONLY AFTER you get the green check for Task 1...${RESET}"
echo ""

# ==============================================================================
# TASK 3: UPDATE & RESUME SCAN
# ==============================================================================
echo "${CYAN}${BOLD}=== TASK 3: MAP TAGS AND RESUME ===${RESET}"
echo "1. On the Discovery page, click the 3 dots next to 'BigQuery Discovery' and select ${BOLD}Edit${RESET}."
echo "2. Check ${BOLD}'Tag resources'${RESET} and check all 4 sensitivity boxes."
echo "3. Copy/Paste these exact values:"
echo "   - High:     ${YELLOW}${PROJECT_ID}/sensitivity-level/high${RESET}"
echo "   - Moderate: ${YELLOW}${PROJECT_ID}/sensitivity-level/moderate${RESET}"
echo "   - Low:      ${YELLOW}${PROJECT_ID}/sensitivity-level/low${RESET}"
echo "   - Unknown:  ${YELLOW}${PROJECT_ID}/sensitivity-level/unknown${RESET}"
echo "4. Check the final two boxes (lower data risk & tag on first profile)."
echo "5. Click ${BOLD}Save -> Confirm edit -> Resume Scan${RESET}."
echo ""
read -p "${MAGENTA}${BOLD}Press [ENTER] ONLY AFTER you get the green check for Task 3...${RESET}"
echo ""

# ==============================================================================
# TASK 4: AUTOMATED IAM CONDITIONS & BQ TAGGING
# ==============================================================================
echo "${CYAN}${BOLD}=== TASK 4: AUTOMATING IAM & BIGQUERY TAGGING ===${RESET}"

if [ -n "$USER2" ]; then
    echo "${YELLOW}1. Removing Viewer role for Username 2...${RESET}"
    gcloud projects remove-iam-policy-binding $PROJECT_ID \
        --member="user:$USER2" --role="roles/viewer" > /dev/null 2>&1

    echo "${YELLOW}2. Adding Browser role for Username 2...${RESET}"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="user:$USER2" --role="roles/browser" > /dev/null 2>&1

    echo "${YELLOW}3. Adding Conditional BigQuery Data Viewer role...${RESET}"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="user:$USER2" \
        --role="roles/bigquery.dataViewer" \
        --condition="expression=resource.matchTag('$PROJECT_ID/sensitivity-level', 'low'),title=Low Sensitivity Data Access Only" > /dev/null 2>&1
else
    echo "${RED}Skipping IAM updates because Username 2 was not found.${RESET}"
fi

echo "${YELLOW}4. Binding 'Low' Tag to BigQuery Dataset (damaged_car_image_info)...${RESET}"
# Get the unique numerical Tag Value ID for 'low'
LOW_TAG_NAME=$(gcloud resource-manager tags values describe $PROJECT_ID/sensitivity-level/low --format="value(name)")

gcloud resource-manager tags bindings create \
    --tag-value=$LOW_TAG_NAME \
    --parent=//bigquery.googleapis.com/projects/$PROJECT_ID/datasets/damaged_car_image_info > /dev/null 2>&1

echo ""
echo "${GREEN}${BOLD}ORBIT OF OPS: Task 4 Automation Complete!${RESET}"
echo "${YELLOW}You can now click 'Check my progress' for Task 4 in your lab!${RESET}"
echo "${CYAN}${BOLD}====================================================${RESET}"
echo ""
