#!/bin/bash
clear

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

export PROJECT_ID=$DEVSHELL_PROJECT_ID
export TOKEN=$(gcloud auth print-access-token)

# Task 1 Instructions
echo "${YELLOW}${BOLD}=== ORBIT OF OPS: TASK 1 INSTRUCTIONS ===${RESET}"
echo "1. Navigate to: ${CYAN}https://console.cloud.google.com/security/dlp/discovery?project=${PROJECT_ID}${RESET}"
echo "2. Click ${BOLD}Enable${RESET} under Cloud Storage."
echo "3. Follow the UI prompts (Use dataset: cloudstorage_discovery, table: data_profiles)."
echo "4. Click 'Check my progress' until you get 20/20."
echo "${YELLOW}===========================================${RESET}"
read -p "${BOLD}Press [ENTER] only AFTER Task 1 is marked 20/20...${RESET}"

# Task 2: Patch Templates
echo "${CYAN}Orbit of Ops: Configuring Templates...${RESET}"
TEMPLATE_ID=$(curl -s -H "Authorization: Bearer $TOKEN" "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/global/inspectTemplates" | jq -r '.inspectTemplates[0].name')

cat <<EOF > patch.json
{ "inspectTemplate": { "inspectConfig": { "infoTypes": [ { "name": "US_SOCIAL_SECURITY_NUMBER" } ], "minLikelihood": "UNLIKELY" } } }
EOF
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @patch.json "https://dlp.googleapis.com/v2/$TEMPLATE_ID?updateMask=inspectConfig.infoTypes,inspectConfig.minLikelihood" > /dev/null

cat <<EOF > deid.json
{
  "deidentifyTemplate": {
    "deidentifyConfig": { "recordTransformations": { "fieldTransformations": [
      { "fields": [{"name": "ssn"}, {"name": "email"}], "primitiveTransformation": {"replaceConfig": {"newValue": {"stringValue": "[redacted]"}}} },
      { "fields": [{"name": "message"}], "infoTypeTransformations": {"transformations": [{"primitiveTransformation": {"replaceWithInfoTypeConfig": {}}}]} }
    ] } },
    "displayName": "De-identification Template",
    "templateId": "us_ssn_deidentify"
  }
}
EOF
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @deid.json "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/global/deidentifyTemplates" > /dev/null

# Task 4: Run Inspection Job
echo "${CYAN}Orbit of Ops: Running Inspection Job...${RESET}"
cat <<EOF > inspect_job.json
{
  "jobId": "us_ssn_inspection",
  "inspectJob": {
    "inspectTemplateName": "$TEMPLATE_ID",
    "storageConfig": { "cloudStorageOptions": { "fileSet": { "url": "gs://$PROJECT_ID-input/**" } } },
    "actions": [ { "saveFindings": { "outputConfig": { "table": { "projectId": "$PROJECT_ID", "datasetId": "cloudstorage_inspection", "tableId": "us_ssn" } } } } ]
  }
}
EOF
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @inspect_job.json "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/us/dlpJobs" > /dev/null
echo "${GREEN}Inspection job submitted!${RESET}"

# Task 5: Run De-identify Job
echo "${CYAN}Orbit of Ops: Running De-identify Job...${RESET}"
cat <<EOF > deid_job.json
{
  "jobId": "us_ssn_deidentify",
  "inspectJob": {
    "inspectConfig": { "infoTypes": [{"name": "US_SOCIAL_SECURITY_NUMBER"}], "minLikelihood": "POSSIBLE" },
    "storageConfig": { "cloudStorageOptions": { "fileSet": { "regexFileSet": { "bucketName": "$PROJECT_ID-input", "excludeRegex": ["ignore"] } } } },
    "actions": [ { "deidentify": { "cloudStorageOutput": "gs://$PROJECT_ID-output", "transformationConfig": { "structuredDeidentifyTemplate": "projects/$PROJECT_ID/locations/global/deidentifyTemplates/us_ssn_deidentify" }, "transformationDetailsStorageConfig": { "table": { "projectId": "$PROJECT_ID", "datasetId": "cloudstorage_transformations", "tableId": "deidentify_ssn_csv" } } } } ]
  }
}
EOF
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @deid_job.json "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/us/dlpJobs" > /dev/null

echo ""
echo "${CYAN}${BOLD}ORBIT OF OPS: Mission Complete. Jobs are running in the background.${RESET}"
rm patch.json deid.json inspect_job.json deid_job.json
