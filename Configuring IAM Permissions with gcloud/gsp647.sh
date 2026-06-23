#!/bin/bash

# =========================================================
# ORBIT OF OPS 🚀 | GSP647: IAM & MULTIPLE CONFIGURATIONS
# =========================================================

export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# =========================================================
# SYSTEM COLORS AND STYLING
# =========================================================
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
ORANGE_TEXT=$'\033[38;5;208m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

orbit_footer() {
    echo
    echo "${CYAN_TEXT}${BOLD_TEXT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_FORMAT}"
    echo "${ORANGE_TEXT}${BOLD_TEXT} 💫 Join the Mission: Subscribe to Orbit of Ops${RESET_FORMAT}"
    echo "${CYAN_TEXT}${UNDERLINE_TEXT} https://www.youtube.com/@OrbitOfOps${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_FORMAT}"
    echo
}

echo
echo "${CYAN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│                                                        │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│         🌟 ORBIT OF OPS: IAM AUTOMATION MATRIX 🌟       │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│                                                        │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────────────┘${RESET_FORMAT}"
echo
orbit_footer

# =========================================================
# STAGE 1: CREDENTIAL TARGETING
# =========================================================
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 1: DATA COLLECTION ===${RESET_FORMAT}"
echo "${WHITE_TEXT}Please check your Qwiklabs panel for the following details:${RESET_FORMAT}"
echo

# Safely capture the active Cloud Shell configuration name
export INITIAL_CONFIG=$(gcloud config configurations list --filter="is_active:true" --format="value(name)")
if [ -z "$INITIAL_CONFIG" ]; then INITIAL_CONFIG="default"; fi

export PROJECT1=$(gcloud config get-value project)
echo "${CYAN_TEXT}Project 1 ID auto-detected as: $PROJECT1${RESET_FORMAT}"
echo "${CYAN_TEXT}Active Configuration saved as: $INITIAL_CONFIG${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Project 2 ID: ${RESET_FORMAT}" PROJECT2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Username 2 (User 2 Email): ${RESET_FORMAT}" USER2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Zone 1 (Look at lab instructions, usually europe-west4-a): ${RESET_FORMAT}" ZONE1
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Zone 2 (Look at lab instructions, usually europe-west1-b): ${RESET_FORMAT}" ZONE2

# =========================================================
# STAGE 2: PROJECT 1 INFRASTRUCTURE
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 2: PROJECT 1 PROVISIONING ===${RESET_FORMAT}"
echo

echo "${ORANGE_TEXT}Deploying lab-1 in active zone ($ZONE1)...${RESET_FORMAT}"
gcloud compute instances create lab-1 \
    --project=$PROJECT1 \
    --zone=$ZONE1 \
    --machine-type=e2-standard-2 \
    --quiet

echo "${ORANGE_TEXT}Triggering default zone update for grader check...${RESET_FORMAT}"
REGION1=$(echo $ZONE1 | rev | cut -d'-' -f2- | rev)
NEW_ZONE=$(gcloud compute zones list --filter="name~'^$REGION1'" --format="value(name)" | grep -v "^$ZONE1$" | head -n 1)
gcloud config set compute/zone $NEW_ZONE --quiet
echo "${CYAN_TEXT}Default zone shifted to: $NEW_ZONE${RESET_FORMAT}"

# =========================================================
# STAGE 3: IAM ROLE BINDINGS & CUSTOM ROLES
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 3: CROSS-PROJECT IAM ORCHESTRATION ===${RESET_FORMAT}"
echo

echo "${ORANGE_TEXT}Granting global Viewer permissions to $USER2 on Project 2...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT2 \
    --member="user:$USER2" \
    --role="roles/viewer" \
    --quiet

echo "${ORANGE_TEXT}Compiling custom 'devops' role array in Project 2...${RESET_FORMAT}"
gcloud iam roles create devops \
    --project=$PROJECT2 \
    --permissions="compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" \
    --quiet 2>/dev/null || echo "${CYAN_TEXT}(Role already exists, skipping creation...)${RESET_FORMAT}"

echo "${ORANGE_TEXT}Binding strict target policies to $USER2...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT2 \
    --member="user:$USER2" \
    --role="roles/iam.serviceAccountUser" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT2 \
    --member="user:$USER2" \
    --role="projects/$PROJECT2/roles/devops" \
    --quiet

# =========================================================
# STAGE 4: SERVICE ACCOUNT DEPLOYMENT (PROJECT 2)
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 4: SERVICE ACCOUNT PROVISIONING ===${RESET_FORMAT}"
echo

echo "${ORANGE_TEXT}Generating autonomous gateway identity (devops)...${RESET_FORMAT}"
gcloud iam service-accounts create devops \
    --display-name="devops" \
    --project=$PROJECT2 \
    --quiet 2>/dev/null || echo "${CYAN_TEXT}(Service Account already exists, skipping creation...)${RESET_FORMAT}"

SA="devops@$PROJECT2.iam.gserviceaccount.com"

echo "${ORANGE_TEXT}Mounting instance authority to gateway identity...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT2 \
    --member="serviceAccount:$SA" \
    --role="roles/iam.serviceAccountUser" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT2 \
    --member="serviceAccount:$SA" \
    --role="roles/compute.instanceAdmin" \
    --quiet

echo "${ORANGE_TEXT}Booting lab-3 cluster with localized service account attached...${RESET_FORMAT}"
gcloud compute instances create lab-3 \
    --project=$PROJECT2 \
    --zone=$ZONE2 \
    --machine-type=e2-standard-2 \
    --service-account=$SA \
    --scopes="https://www.googleapis.com/auth/compute" \
    --quiet

echo "${MAGENTA_TEXT}Waiting 30 seconds for lab-3 to boot up for SSH Tunneling...${RESET_FORMAT}"
sleep 30

echo "${ORANGE_TEXT}SSHing into lab-3 to force Service Account to create lab-4...${RESET_FORMAT}"
mkdir -p ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/google_compute_engine -N "" -q <<< y >/dev/null 2>&1 || true

gcloud compute ssh lab-3 \
    --project=$PROJECT2 \
    --zone=$ZONE2 \
    --quiet \
    --command="gcloud compute instances create lab-4 --zone=$ZONE2 --machine-type=e2-standard-2 --quiet"

# =========================================================
# STAGE 5: THE USER 2 IDENTITY SHIFT (INTERACTIVE)
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 5: USER 2 IDENTITY SHIFT ===${RESET_FORMAT}"
echo

gcloud config configurations create user2 --quiet 2>/dev/null || gcloud config configurations activate user2 --quiet
gcloud config set project $PROJECT2 --quiet

echo "${RED_TEXT}${BOLD_TEXT}ATTENTION REQUIRED: To get full points, User 2 must create lab-2.${RESET_FORMAT}"
echo "${WHITE_TEXT}1. Click the link below.${RESET_FORMAT}"
echo "${WHITE_TEXT}2. Log in using the ${YELLOW_TEXT}User 2${WHITE_TEXT} credentials.${RESET_FORMAT}"
echo "${WHITE_TEXT}3. Click Allow, copy the verification code, and paste it here.${RESET_FORMAT}"

export CLOUDSDK_CORE_DISABLE_PROMPTS=0
gcloud auth login $USER2 --no-launch-browser
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

echo
echo "${ORANGE_TEXT}Identity verified! Deploying lab-2 as User 2...${RESET_FORMAT}"
gcloud compute instances create lab-2 \
    --project=$PROJECT2 \
    --zone=$ZONE2 \
    --machine-type=e2-standard-2 \
    --quiet

echo "${ORANGE_TEXT}Restoring original administrative identity ($INITIAL_CONFIG)...${RESET_FORMAT}"
gcloud config configurations activate $INITIAL_CONFIG --quiet

# =========================================================
# SUCCESS STATUS INTERFACE TERMINATION
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}│          MISSION ACCOMPLISHED: IAM MATRICES SET        │${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────────────┘${RESET_FORMAT}"
echo

orbit_footer
