#!/bin/bash

# =========================================================
# ORBIT OF OPS 🚀 | GSP647 IAM & MULTIPLE CONFIGS AUTOMATION
# =========================================================

# Enforce zero-prompt automated control
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# =========================================================
# SYSTEM COLORS AND STYLING
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
echo "${CYAN_TEXT}${BOLD_TEXT}│         🌟 ORBIT OF OPS: IAM AUTOMATION MATRIX 🌟       │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}│                                                        │${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────────────┘${RESET_FORMAT}"
echo
orbit_footer

# =========================================================
# INTERACTIVE DATA COLLECTION
# =========================================================
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 1: TARGET RESOLUTION ===${RESET_FORMAT}"
echo
echo "${WHITE_TEXT}Please check your Qwiklabs panel to find the credentials for Project 2 and User 2.${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Project ID 2 (PROJECTID2): ${RESET_FORMAT}" PROJECTID2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Username 2 (USERID2): ${RESET_FORMAT}" USERID2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Zone 2 (e.g., us-east1-b): ${RESET_FORMAT}" ZONE2

echo
echo "${CYAN_TEXT}Detecting local parameters for Project 1...${RESET_FORMAT}"
export PROJECTID1=$(gcloud config get-value project)
export ZONE1=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION1=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# =========================================================
# TASK 1: CREATE LAB-1 & UPDATE DEFAULT ZONE
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 2: PROJECT 1 INFRASTRUCTURE ===${RESET_FORMAT}"
echo

echo "${ORANGE_TEXT}Deploying lab-1 in active zone ($ZONE1)...${RESET_FORMAT}"
gcloud compute instances create lab-1 \
    --zone=$ZONE1 \
    --machine-type=e2-standard-2 \
    --quiet

echo "${ORANGE_TEXT}Updating default config to secondary zone...${RESET_FORMAT}"
NEW_ZONE=$(gcloud compute zones list --filter="name~'^$REGION1'" --format="value(name)" | grep -v "^$ZONE1$" | head -n 1)
gcloud config set compute/zone $NEW_ZONE --quiet
echo "${CYAN_TEXT}Default zone shifted to: $NEW_ZONE${RESET_FORMAT}"

# =========================================================
# TASK 3 & 4: IAM ROLE BINDINGS & CUSTOM ROLES FOR USER 2
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 3: MULTI-PROJECT IAM ORCHESTRATION ===${RESET_FORMAT}"
echo

echo "${ORANGE_TEXT}Granting global Viewer permissions to $USERID2...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member="user:$USERID2" \
    --role="roles/viewer" \
    --quiet

echo "${ORANGE_TEXT}Compiling custom 'devops' role array in Project 2...${RESET_FORMAT}"
gcloud iam roles create devops \
    --project=$PROJECTID2 \
    --permissions="compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" \
    --quiet

echo "${ORANGE_TEXT}Binding strict target policies to $USERID2...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member="user:$USERID2" \
    --role="roles/iam.serviceAccountUser" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member="user:$USERID2" \
    --role="projects/$PROJECTID2/roles/devops" \
    --quiet

echo "${ORANGE_TEXT}Deploying lab-2 in Project 2 via administrative bypass...${RESET_FORMAT}"
gcloud compute instances create lab-2 \
    --project=$PROJECTID2 \
    --zone=$ZONE2 \
    --machine-type=e2-standard-2 \
    --quiet

# =========================================================
# TASK 5 & 6: SERVICE ACCOUNT PROVISIONING
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=== STAGE 4: SERVICE ACCOUNT DEPLOYMENT ===${RESET_FORMAT}"
echo

echo "${ORANGE_TEXT}Generating autonomous gateway identity (devops)...${RESET_FORMAT}"
gcloud iam service-accounts create devops \
    --display-name="devops" \
    --project=$PROJECTID2 \
    --quiet

SA="devops@$PROJECTID2.iam.gserviceaccount.com"

echo "${ORANGE_TEXT}Mounting instance authority to gateway identity...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member="serviceAccount:$SA" \
    --role="roles/iam.serviceAccountUser" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member="serviceAccount:$SA" \
    --role="roles/compute.instanceAdmin" \
    --quiet

echo "${ORANGE_TEXT}Booting lab-3 cluster with localized service account...${RESET_FORMAT}"
gcloud compute instances create lab-3 \
    --project=$PROJECTID2 \
    --zone=$ZONE2 \
    --machine-type=e2-standard-2 \
    --service-account=$SA \
    --scopes="https://www.googleapis.com/auth/compute" \
    --quiet

echo "${ORANGE_TEXT}Booting lab-4 verification node...${RESET_FORMAT}"
gcloud compute instances create lab-4 \
    --project=$PROJECTID2 \
    --zone=$ZONE2 \
    --machine-type=e2-standard-2 \
    --quiet

# =========================================================
# SUCCESS STATUS INTERFACE TERMINATION
# =========================================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}│          MISSION ACCOMPLISHED: IAM MATRICES SET        │${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────────────┘${RESET_FORMAT}"
echo

orbit_footer
