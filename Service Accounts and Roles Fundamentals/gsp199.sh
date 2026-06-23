#!/bin/bash

# =========================================================
# ORBIT OF OPS 🚀 | PIPELINE DEPLOYMENT MATRIX FOR GSP199
# =========================================================

# Enforce zero-prompt automated control
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# =========================================================
# SYSTEM COLORS AND LIGHT CONFIGS
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
# BRANDING FOOTER ENGINE
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
# PIPELINE WELCOME BANNER
# =========================================================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│                                                        │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│      🌟   ORBIT OF OPS: TELEMETRY AUTOMATION   🌟       │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│                                                        │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────────────┘${RESET_FORMAT}"
echo

echo "${WHITE_TEXT}${BOLD_TEXT}📦 Lab Architecture Delivery Scope:${RESET_FORMAT}"
echo "${WHITE_TEXT}   ➜ Create & bind isolated IAM Service Accounts${RESET_FORMAT}"
echo "${WHITE_TEXT}   ➜ Build a Compute Engine Instance attached to custom scopes${RESET_FORMAT}"
echo "${WHITE_TEXT}   ➜ Run automated queries against BigQuery Public Datasets${RESET_FORMAT}"
echo

orbit_footer

# =========================================================
# WORKSPACE METADATA RESOLUTION
# =========================================================
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 1: WORKSPACE RESOLUTION & IDENTITY AUDIT ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Auditing active environment identities...${RESET_FORMAT}"
gcloud auth list

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🛰️ Resolving default configuration maps...${RESET_FORMAT}"

export PROJECT_ID=$(gcloud config get-value project)

# Force-align the explicit lab requirement coordinates
export REGION="us-west3"
export ZONE="us-west3-c"

gcloud config set compute/region $REGION --quiet
gcloud config set compute/zone $ZONE --quiet

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🛸 Targeted Project ID: ${RESET_FORMAT}${CYAN_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🛸 Configured Region:   ${RESET_FORMAT}${CYAN_TEXT}$REGION${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🛸 Configured Zone:     ${RESET_FORMAT}${CYAN_TEXT}$ZONE${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚡ Environment initialized successfully.${RESET_FORMAT}"
orbit_footer

# =========================================================
# IAM SERVICE ACCOUNT ORCHESTRATION
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 2: IDENTITY & ACCESS POLICY IMPLEMENTATION ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}👤 Generating service account identity: my-sa-123...${RESET_FORMAT}"
gcloud iam service-accounts create my-sa-123 \
    --display-name="my service account" \
    --quiet

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Attaching comprehensive project Editor mapping...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:my-sa-123@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor" \
    --quiet

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}👤 Generating analytical gateway token: bigquery-qwiklab...${RESET_FORMAT}"
gcloud iam service-accounts create bigquery-qwiklab \
    --display-name="bigquery-qwiklab" \
    --quiet

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Assigning strict data viewer permissions...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/bigquery.dataViewer" \
    --quiet

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Assigning structural analytical execution scopes...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/bigquery.user" \
    --quiet

orbit_footer

# =========================================================
# CORE VIRTUAL NODE PROVISIONING
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 3: INFRASTRUCTURE CLUSTER BUILD ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}💻 Building analytical runtime host (bigquery-instance)...${RESET_FORMAT}"
gcloud compute instances create bigquery-instance \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --service-account=bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --metadata=serial-port-enable=TRUE \
    --quiet

orbit_footer

# =========================================================
# NETWORK AND KERNEL STACK SPINNER
# =========================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Syncing runtime architecture & waiting for network stack...${RESET_FORMAT}"

spinner="/-\|"
messages=(
"Configuring network routing interfaces..."
"Validating host instance availability matrix..."
"Catch the next space launch: Subscribe to Orbit of Ops 💫"
"Mounting downstream virtualization dependencies..."
)

for i in {1..20}; do
    msg=${messages[$((i % ${#messages[@]}))]}
    printf "\r${CYAN_TEXT}${BOLD_TEXT}[${spinner:i%4:1}] $msg${RESET_FORMAT}"
    sleep 1
done
printf "\n"

# =========================================================
# COMPILING LOGICAL WORKLOAD SCRIPT
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 4: COMPILING REMOTE TARGET TASK EXECUTION ===${RESET_FORMAT}"
echo

cat > cp_disk.sh << 'EOF'
#!/bin/bash

echo "Updating operating system mirror trees..."
sudo apt-get update -y

echo "Provisioning standard compiler layers and isolation components..."
sudo apt-get install -y python3 python3-pip python3-venv git

echo "Isolating processing memory context using native Virtualenv..."
python3 -m venv myvenv
source myvenv/bin/activate

echo "Upgrading pip execution packages..."
pip install --upgrade pip

echo "Mounting specialized BigQuery data analysis frameworks..."
pip install google-cloud-bigquery pyarrow pandas db-dtypes

echo
echo "💫 Powered by Orbit of Ops Automation Matrix"
echo "👉 Join the operations center: https://www.youtube.com/@OrbitOfOps"
echo

echo "Writing processing file: query.py..."
cat > query.py << 'PYEOF'
from google.auth import compute_engine
from google.cloud import bigquery

credentials = compute_engine.Credentials(
    service_account_email='YOUR_SERVICE_ACCOUNT'
)

query = '''
SELECT
  year,
  COUNT(1) as num_babies
FROM
  publicdata.samples.natality
WHERE
  year > 2000
GROUP BY
  year
'''

client = bigquery.Client(
    project='PROJECT_ID',
    credentials=credentials
)

print("\n💫 Orbit of Ops: Dynamic Data Output Engine")
print("👉 Platform Hub: https://www.youtube.com/@OrbitOfOps\n")
print("Requesting public record subsets from BigQuery...\n")

df = client.query(query).to_dataframe()
print(df.to_string(index=False))
PYEOF

# Dynamic internal variable substitution mapping
sed -i "s/PROJECT_ID/$(gcloud config get-value project)/g" query.py
sed -i "s/YOUR_SERVICE_ACCOUNT/bigquery-qwiklab@$(gcloud config get-value project).iam.gserviceaccount.com/g" query.py

echo "Launching targeted query execution stream..."
echo
python3 query.py
EOF

# =========================================================
# FILE INJECTION BLOCK
# =========================================================
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📤 Transmitting operational task code blocks to instance target...${RESET_FORMAT}"
orbit_footer

# Generate system keys quietly if they do not exist
mkdir -p ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/google_compute_engine -N "" -q <<< y >/dev/null 2>&1 || true

gcloud compute scp cp_disk.sh bigquery-instance:/tmp \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --quiet

# =========================================================
# INSTANCE SHELL ENVELOPE EXECUTION
# =========================================================
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 Awakening remote workspace terminal environments...${RESET_FORMAT}"
orbit_footer

gcloud compute ssh bigquery-instance \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --quiet \
    --command="chmod +x /tmp/cp_disk.sh && /tmp/cp_disk.sh"

# =========================================================
# SUCCESS STATUS INTERFACE TERMINATION
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}│          MISSION ACCOMPLISHED: MATRIX DISPATCHED       │${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────────────┘${RESET_FORMAT}"
echo

# System directory trace file sanitization block
cd
for file in *; do
    if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
        if [[ -f "$file" ]]; then
            rm "$file"
        fi
    fi
done

orbit_footer
