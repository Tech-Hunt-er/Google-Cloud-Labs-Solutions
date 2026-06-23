#!/bin/bash

# =========================================================
# ORBIT OF OPS 🚀 | FULLY AUTOMATED GOOGLE CLOUD SOLUTION
# =========================================================

# Disable all interactive prompts automatically
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# =========================================================
# VISUAL STYLING ENGINE (COLORS & FORMATS)
# =========================================================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
ORANGE_TEXT=$'\033[38;5;208m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# =========================================================
# SYSTEM SERVICE BRANDING FUNCTIONS
# =========================================================
orbit_footer() {
    echo
    echo "${CYAN_TEXT}${BOLD_TEXT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_FORMAT}"
    echo "${ORANGE_TEXT}${BOLD_TEXT} 💫 Join the Mission: Subscribe to Orbit of Ops${RESET_FORMAT}"
    echo "${CYAN_TEXT}${UNDERLINE_TEXT} https://www.youtube.com/@OrbitOfOps${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_FORMAT}"
    echo
}

# =========================================================
# MISSION INITIALIZATION BANNER
# =========================================================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│                                                        │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│        🌟   ORBIT OF OPS: AUTOMATION PIPELINE   🌟      │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│                                                        │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────────────┘${RESET_FORMAT}"
echo

echo "${WHITE_TEXT}${BOLD_TEXT}📦 Pipeline Scope & Deliverables:${RESET_FORMAT}"
echo "${WHITE_TEXT}   ➜ Secure BigQuery Integration via Compute Engine${RESET_FORMAT}"
echo "${WHITE_TEXT}   ➜ Least-Privilege IAM Service Accounts Configuration${RESET_FORMAT}"
echo "${WHITE_TEXT}   ➜ Remote Python Client Library Orchestration${RESET_FORMAT}"
echo

orbit_footer

# =========================================================
# GROUND CONTROL CONFIGURATION
# =========================================================
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 1: PARSING PLATFORM META-DATA ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Auditing active Google Cloud identities...${RESET_FORMAT}"
gcloud auth list

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🛰️ Resolving spatial regional telemetry...${RESET_FORMAT}"

export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Sync local parameters to active workspace environment
gcloud config set compute/zone $ZONE --quiet
gcloud config set compute/region $REGION --quiet

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🛸 Targeted Project: ${RESET_FORMAT}${CYAN_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🛸 Active Region:   ${RESET_FORMAT}${CYAN_TEXT}$REGION${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🛸 Target Zone:     ${RESET_FORMAT}${CYAN_TEXT}$ZONE${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚡ Ground Control environment initialized successfully.${RESET_FORMAT}"

orbit_footer

# =========================================================
# SERVICE ACCOUNT SETUP
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 2: IDENTITY & ACCESS CONFIGURATION ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}👤 Generating platform service account: my-sa-123...${RESET_FORMAT}"
gcloud iam service-accounts create my-sa-123 \
    --display-name="My Service Account" \
    --quiet

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Attaching structural Editor IAM bindings...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:my-sa-123@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor" \
    --quiet

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}👤 Generating dedicated data gateway: bigquery-qwiklab...${RESET_FORMAT}"
gcloud iam service-accounts create bigquery-qwiklab \
    --display-name="bigquery-qwiklab" \
    --quiet

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Attaching fine-grained BigQuery scope bindings...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/bigquery.dataViewer" \
    --quiet

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/bigquery.user" \
    --quiet

orbit_footer

# =========================================================
# COMPUTE INSTANCE DEPLOYMENT
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 3: INFRASTRUCTURE DEPLOYMENT ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}💻 Building secure runtime node (bigquery-instance)...${RESET_FORMAT}"
gcloud compute instances create bigquery-instance \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --service-account=bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --quiet

orbit_footer

# =========================================================
# METRIC SYNCHRONIZATION RUNTIME SPINNER
# =========================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Syncing node telemetry & waiting for network stack...${RESET_FORMAT}"

spinner="/-\|"
messages=(
"Validating host configurations..."
"Structuring underlying guest OS requirements..."
"Catch the next launch: Subscribe to Orbit of Ops 💫"
"Mounting remote BigQuery engine modules..."
)

for i in {1..20}; do
    msg=${messages[$((i % ${#messages[@]}))]}
    printf "\r${CYAN_TEXT}${BOLD_TEXT}[${spinner:i%4:1}] $msg${RESET_FORMAT}"
    sleep 1
done

printf "\n"

# =========================================================
# GENERATING AUTOMATED WORKLOAD COMPILATION
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 4: WORKLOAD DELIVERY MATRIX ===${RESET_FORMAT}"
echo

cat > cp_disk.sh << 'EOF'
#!/bin/bash

echo "Refreshing regional mirror lists..."
sudo apt-get update -y

echo "Compiling execution language binaries & framework dependencies..."
sudo apt-get install -y python3 python3-pip python3-venv git

echo "Isolating workspace context via secure Python virtual sandbox..."
python3 -m venv myvenv
source myvenv/bin/activate

echo "Upgrading base package delivery tools..."
pip install --upgrade pip

echo "Mounting structural BigQuery analytical frameworks..."
pip install google-cloud-bigquery pyarrow pandas db-dtypes

echo
echo "💫 Powered by Orbit of Ops Automation Frameworks"
echo "👉 Join the platform: https://www.youtube.com/@OrbitOfOps"
echo

echo "Writing structural analytics interface file (query.py)..."

cat > query.py << 'PYEOF'
from google.auth import compute_engine
from google.cloud import bigquery

credentials = compute_engine.Credentials(
    service_account_email='YOUR_SERVICE_ACCOUNT'
)

query = '''
SELECT
  year,
  COUNT(1) AS num_babies
FROM
  publicdata.samples.natality
WHERE
  year > 2000
GROUP BY
  year
ORDER BY
  year
'''

client = bigquery.Client(
    project='PROJECT_ID',
    credentials=credentials
)

print("\n💫 Orbit of Ops: Remote Workflow Output Engine")
print("👉 Channel Resource: https://www.youtube.com/@OrbitOfOps\n")

print("Executing analytical lookup on target data fields...\n")

df = client.query(query).to_dataframe()
print(df.to_string(index=False))
PYEOF

# Dynamic internal workspace adjustments
sed -i "s/PROJECT_ID/$(gcloud config get-value project)/g" query.py
sed -i "s/YOUR_SERVICE_ACCOUNT/bigquery-qwiklab@$(gcloud config get-value project).iam.gserviceaccount.com/g" query.py

echo "Processing remote query matrix..."
echo

python3 query.py
EOF

# =========================================================
# STAGE PIPELINE TRANSFERS
# =========================================================
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📤 Injecting compiled execution matrices to remote instance...${RESET_FORMAT}"

orbit_footer

gcloud compute scp cp_disk.sh bigquery-instance:/tmp \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet

# =========================================================
# INTERACTIVE NODE ORCHESTRATION
# =========================================================
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 Executing orchestration runtime parameters on target node...${RESET_FORMAT}"

orbit_footer

gcloud compute ssh bigquery-instance \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet \
    --command="chmod +x /tmp/cp_disk.sh && /tmp/cp_disk.sh"

# =========================================================
# MISSION ACCOMPLISHED DISPLAY TERMINAL
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}│             PIPELINE EXECUTED SUCCESSFULLY             │${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────────────┘${RESET_FORMAT}"
echo

orbit_footer
