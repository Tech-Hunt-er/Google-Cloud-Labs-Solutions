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

export PROJECT_ID=$DEVSHELL_PROJECT_ID
export TOKEN=$(gcloud auth print-access-token 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo "${RED}Error: Could not authenticate. Run 'gcloud auth login' and try again.${RESET}"
    exit 1
fi

echo "${GREEN}Orbit of Ops: Project ID detected: ${PROJECT_ID}${RESET}"
echo ""

# ---------------------------------------------------------------------------
# TASK 1: MANUAL INSTRUCTIONS
# ---------------------------------------------------------------------------
echo "${YELLOW}${BOLD}=== ORBIT OF OPS: TASK 1 MANUAL SETUP ===${RESET}"
echo "To ensure you get full points, complete Task 1 in the UI:"
echo ""
echo "1. Hold CTRL (or CMD) and click this link to open a new tab:"
echo "   ${CYAN}https://console.cloud.google.com/security/sensitive-data-protection${RESET}"
echo "2. Make sure your Qwiklabs project ($PROJECT_ID) is selected at the top."
echo "3. Click the ${BOLD}'Discovery'${RESET} tab."
echo "4. Under 'Cloud Storage', click ${BOLD}'Enable'${RESET}."
echo "5. Leave 'Cloud Storage' selected and click Continue."
echo "6. Leave 'Scan selected project' selected and click Continue."
echo "7. Leave default schedules and click Continue."
echo "8. Leave 'Create a new inspection template' selected and click Continue."
echo "9. Under 'Add actions':"
echo "   - Check the box for ${BOLD}'Publish to Security Command Center'${RESET}"
echo "   - Check the box for ${BOLD}'Save data profile copies to BigQuery'${RESET}"
echo "   - Set Project ID: ${BOLD}$PROJECT_ID${RESET}"
echo "   - Set Dataset ID: ${BOLD}cloudstorage_discovery${RESET}"
echo "   - Set Table ID: ${BOLD}data_profiles${RESET}"
echo "10. Click Continue on fallback locations and regions."
echo "11. Set Display Name to: ${BOLD}Cloud Storage Discovery${RESET}"
echo "12. Click Create, then Create Configuration."
echo ""
echo "Now go to your Qwiklabs manual and click 'Check my progress' for Task 1."
echo "${YELLOW}=====================================================${RESET}"
echo ""

read -p "${BOLD}Press [ENTER] only AFTER you get the 20/20 green check for Task 1...${RESET}"

# ---------------------------------------------------------------------------
# TASK 2: Fetch Manual Template and Patch It
# ---------------------------------------------------------------------------
echo ""
echo "${CYAN}Orbit of Ops: Fetching your manual Task 1 Inspection Template...${RESET}"
export TEMPLATE_NAME=$(curl -s -H "Authorization: Bearer $TOKEN" "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/global/inspectTemplates" | jq -r '.inspectTemplates[0].name')

if [ -z "$TEMPLATE_NAME" ] || [ "$TEMPLATE_NAME" == "null" ]; then
    echo "${RED}Error: Could not find the Inspection Template. Please verify Task 1 was completed.${RESET}"
    exit 1
fi
echo "${GREEN}Found Template: $TEMPLATE_NAME${RESET}"

echo "${CYAN}Orbit of Ops: Patching Inspection Template for US SSN (Task 2)...${RESET}"
cat <<EOF > task2_template.json
{
  "inspectTemplate": {
    "displayName": "Inspection Template for US SSN",
    "description": "This template was created as part of a Sensitive Data Protection profiler configuration and was modified for deeper inspection for US Social Security numbers.",
    "inspectConfig": {
      "infoTypes": [ { "name": "US_SOCIAL_SECURITY_NUMBER" } ],
      "minLikelihood": "UNLIKELY"
    }
  }
}
EOF

curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @task2_template.json \
  "https://dlp.googleapis.com/v2/$TEMPLATE_NAME?updateMask=displayName,description,inspectConfig.infoTypes,inspectConfig.minLikelihood" > /dev/null

echo "${GREEN}Inspection Template patched successfully.${RESET}"

# ---------------------------------------------------------------------------
# TASK 2: Create De-identify Template
# ---------------------------------------------------------------------------
echo "${CYAN}Orbit of Ops: Creating De-identification Template (Task 2)...${RESET}"
cat <<EOF > deidentify_template.json
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "recordTransformations": {
        "fieldTransformations": [
          {
            "fields": [ { "name": "ssn" }, { "name": "email" } ],
            "primitiveTransformation": { "replaceConfig": { "newValue": { "stringValue": "[redacted]" } } }
          },
          {
            "fields": [ { "name": "message" } ],
            "infoTypeTransformations": { "transformations": [ { "primitiveTransformation": { "replaceWithInfoTypeConfig": {} } } ] }
          }
        ]
      }
    },
    "displayName": "De-identification Template for US SSN"
  },
  "templateId": "us_ssn_deidentify"
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @deidentify_template.json \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/global/deidentifyTemplates" > /dev/null

echo "${GREEN}De-identification Template created successfully.${RESET}"

echo ""
echo "${YELLOW}${BOLD}=== CHECKPOINT ===${RESET}"
read -p "Please click 'Check my progress' for Task 2. Press [ENTER] to continue to Tasks 4 and 5..."
echo ""

# ---------------------------------------------------------------------------
# TASK 4: Run Inspection Job
# ---------------------------------------------------------------------------
echo "${CYAN}Orbit of Ops: Submitting Inspection Job (Task 4)...${RESET}"
cat <<EOF > inspect_job.json
{
  "jobId": "us_ssn_inspection",
  "inspectJob": {
    "inspectTemplateName": "$TEMPLATE_NAME",
    "storageConfig": {
      "cloudStorageOptions": {
        "filesLimitPercent": 100,
        "fileTypes": [ "TEXT_FILE", "CSV" ],
        "fileSet": { "url": "gs://$PROJECT_ID-input/**" }
      }
    },
    "actions": [
      {
        "saveFindings": {
          "outputConfig": { "table": { "projectId": "$PROJECT_ID", "datasetId": "cloudstorage_inspection", "tableId": "us_ssn" } }
        }
      },
      { "publishSummaryToCscc": {} }
    ]
  }
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @inspect_job.json \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/us/dlpJobs" > /dev/null
echo "${GREEN}Inspection Job submitted. Waiting for completion...${RESET}"

# Adding a brief wait so the job fully initializes
sleep 5
echo "${GREEN}Inspection job is running in the background.${RESET}"

# ---------------------------------------------------------------------------
# TASK 5: Run De-identify Job
# ---------------------------------------------------------------------------
echo "${CYAN}Orbit of Ops: Submitting De-identification Job (Task 5)...${RESET}"
cat <<EOF > deidentify_job.json
{
  "jobId": "us_ssn_deidentify",
  "inspectJob": {
    "inspectConfig": {
      "infoTypes": [ { "name": "US_SOCIAL_SECURITY_NUMBER" } ],
      "minLikelihood": "POSSIBLE"
    },
    "storageConfig": {
      "cloudStorageOptions": {
        "filesLimitPercent": 100,
        "fileTypes": [ "TEXT_FILE", "CSV" ],
        "fileSet": {
          "regexFileSet": { "bucketName": "$PROJECT_ID-input", "includeRegex": [], "excludeRegex": [ "ignore" ] }
        }
      }
    },
    "actions": [
      {
        "deidentify": {
          "cloudStorageOutput": "gs://$PROJECT_ID-output",
          "transformationConfig": {
            "structuredDeidentifyTemplate": "projects/$PROJECT_ID/locations/global/deidentifyTemplates/us_ssn_deidentify"
          },
          "transformationDetailsStorageConfig": {
            "table": { "projectId": "$PROJECT_ID", "datasetId": "cloudstorage_transformations", "tableId": "deidentify_ssn_csv" }
          },
          "fileTypesToTransform": [ "TEXT_FILE", "CSV" ]
        }
      }
    ]
  }
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @deidentify_job.json \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/us/dlpJobs" > /dev/null

echo "${GREEN}De-identification Job submitted. Waiting for completion...${RESET}"
sleep 5
echo "${GREEN}De-identification job is running in the background.${RESET}"

# ---------------------------------------------------------------------------
# Cleanup and Finish
# ---------------------------------------------------------------------------
rm -f task2_template.json deidentify_template.json inspect_job.json deidentify_job.json

echo ""
echo "${GREEN}${BOLD}ORBIT OF OPS: Automation Complete.${RESET}"
echo "${YELLOW}The jobs take about 2 to 3 minutes to finish processing.${RESET}"
echo "${YELLOW}You can click 'Check my progress' for Task 4 and Task 5 shortly.${RESET}"
