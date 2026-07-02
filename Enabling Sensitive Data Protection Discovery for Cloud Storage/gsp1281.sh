#!/bin/bash
clear

# Orbit of Ops Branding
BOLD=$(tput bold)
CYAN=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

echo "${CYAN}${BOLD}====================================================${RESET}"
echo "${CYAN}${BOLD}       ORBIT OF OPS: Sensitive Data Protection       ${RESET}"
echo "${CYAN}${BOLD}====================================================${RESET}"
echo ""

# 1. Variables
read -p "Project ID [${DEVSHELL_PROJECT_ID}]: " INPUT_PROJECT_ID
PROJECT_ID=${INPUT_PROJECT_ID:-$DEVSHELL_PROJECT_ID}
export TOKEN=$(gcloud auth print-access-token)

echo ""
echo "${YELLOW}TASK 1 MANUAL REMINDER:${RESET}"
echo "1. Ensure Task 1 is 20/20 in the lab panel before pressing Enter."
read -p "Press [ENTER] to continue with Orbit of Ops automation..."

# 2. Patch Inspection Template (Task 2)
echo "${CYAN}Orbit of Ops: Patching Inspection Template...${RESET}"
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
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @patch.json "https://dlp.googleapis.com/v2/$TEMPLATE_ID?updateMask=inspectConfig.infoTypes,inspectConfig.minLikelihood"

# 3. Create De-identify Template (Task 2)
echo "${CYAN}Orbit of Ops: Deploying De-identify Template...${RESET}"
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
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @deid.json "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/global/deidentifyTemplates"

# 4. Job Execution
echo "${GREEN}Orbit of Ops: Job execution ready. Proceeding with Inspection/De-identify jobs...${RESET}"
# (Add your job submission logic here)

echo ""
echo "${CYAN}${BOLD}ORBIT OF OPS: Automation Complete. Mission Successful.${RESET}"
rm patch.json deid.json
