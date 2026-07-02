#!/bin/bash
clear

# Orbit of Ops Branding
BOLD=$(tput bold)
CYAN=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

echo "${CYAN}${BOLD}====================================================${RESET}"
echo "${CYAN}${BOLD}      ORBIT OF OPS: Sensitive Data Protection       ${RESET}"
echo "${CYAN}${BOLD}====================================================${RESET}"
echo ""

# Auto-fetch variables
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export TOKEN=$(gcloud auth print-access-token)

echo "${GREEN}Orbit of Ops: Project ID detected: ${PROJECT_ID}${RESET}"
echo ""

# Task 1 Instructions
echo "${YELLOW}${BOLD}=== ORBIT OF OPS: TASK 1 INSTRUCTIONS ===${RESET}"
echo "1. Navigate to: ${CYAN}https://console.cloud.google.com/security/dlp/discovery?project=${PROJECT_ID}${RESET}"
echo "2. Click ${BOLD}Enable${RESET} under Cloud Storage."
echo "3. Follow the UI prompts:"
echo "   - Scope: Scan selected project"
echo "   - Inspection template: Create new template"
echo "   - Actions: Enable 'Publish to Security Command Center' & 'Save to BigQuery'"
echo "   - BQ Dataset: ${CYAN}cloudstorage_discovery${RESET}, Table: ${CYAN}data_profiles${RESET}"
echo "4. Click ${BOLD}Create${RESET} and wait for the scan to start."
echo "5. Click 'Check my progress' in the lab panel until you get 20/20."
echo "${YELLOW}===========================================${RESET}"
echo ""

read -p "${BOLD}Press [ENTER] only AFTER Task 1 is marked 20/20 in the lab...${RESET}"

# Task 2: Automation
echo "${CYAN}Orbit of Ops: Initializing Phase 2 (Template Management)...${RESET}"

# Patch Inspection Template
TEMPLATE_ID=$(curl -s -H "Authorization: Bearer $TOKEN" "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/global/inspectTemplates" | jq -r '.inspectTemplates[0].name')

cat <<EOF > patch.json
{
  "inspectTemplate": {
    "inspectConfig": {
      "infoTypes": [ { "name": "US_SOCIAL_SECURITY_NUMBER" } ],
      "minLikelihood": "UNLIKELY"
    }
  }
}
EOF
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @patch.json "https://dlp.googleapis.com/v2/$TEMPLATE_ID?updateMask=inspectConfig.infoTypes,inspectConfig.minLikelihood" > /dev/null

# Create De-identify Template
cat <<EOF > deid.json
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "recordTransformations": {
        "fieldTransformations": [
          { "fields": [{"name": "ssn"}, {"name": "email"}], "primitiveTransformation": {"replaceConfig": {"newValue": {"stringValue": "[redacted]"}}} },
          { "fields": [{"name": "message"}], "infoTypeTransformations": {"transformations": [{"primitiveTransformation": {"replaceWithInfoTypeConfig": {}}}]} }
        ]
      }
    },
    "displayName": "De-identification Template"
  },
  "templateId": "us_ssn_deidentify"
}
EOF
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @deid.json "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/global/deidentifyTemplates" > /dev/null

echo "${GREEN}Orbit of Ops: Phase 2 complete. Templates configured.${RESET}"
rm patch.json deid.json

echo ""
echo "${CYAN}${BOLD}ORBIT OF OPS: Ready for Task 4 & 5 (Inspection/De-identify).${RESET}"
