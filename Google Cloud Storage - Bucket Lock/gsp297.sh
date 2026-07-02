#!/bin/bash

# ==============================================================================
# Script:  Cloud Storage Lifecycle Management (GSP297) - Interactive Fix
# Branding: Orbit of Ops | Infrastructure Automation
# ==============================================================================

# --- Color/Style Definitions ---
BOLD=$(tput bold)
RESET=$(tput sgr0)
CYAN=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)

# --- Helper Functions ---
log_info()    { echo -e "\n${CYAN}${BOLD}[ORBIT-OPS]${RESET} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[WAITING]${RESET} $1"; }

# --- Execution ---
clear
echo "--------------------------------------------------------"
echo "${BOLD}     🚀 Orbit of Ops | Storage Lifecycle Lab${RESET}"
echo "--------------------------------------------------------"

log_info "Task 1 & 2: Creating bucket, setting 10s retention, uploading file..."
export BUCKET=$(gcloud config get-value project)
gsutil mb "gs://$BUCKET"
gsutil retention set 10s "gs://$BUCKET"
gsutil cp gs://spls/gsp297/dummy_transactions "gs://$BUCKET/"

log_info "Task 3: Securing bucket with retention lock..."
echo "y" | gsutil retention lock "gs://$BUCKET/"

log_info "Task 4: Setting Temporary Hold on dummy_transactions..."
gsutil retention temp set "gs://$BUCKET/dummy_transactions"

echo "--------------------------------------------------------"
echo -e "${RED}${BOLD}🛑 PAUSED: ACTION REQUIRED!${RESET}"
echo -e "Go to the Qwiklabs page and click ${BOLD}'Check my progress'${RESET} for:"
echo -e "1. Create a storage bucket"
echo -e "2. Set up Retention Policy"
echo -e "3. Lock the Retention Policy"
echo -e "4. Set up Temporary Hold"
read -p "${YELLOW}👉 Press [ENTER] only AFTER you get the points for Temp Hold...${RESET}"

log_info "Releasing Temporary Hold & cleaning up..."
gsutil retention temp release "gs://$BUCKET/dummy_transactions"
log_warn "Waiting 12 seconds for the 10s retention policy to expire..."
sleep 12
gsutil rm "gs://$BUCKET/dummy_transactions"

log_info "Task 5: Configuring Event-based holds..."
gsutil retention event-default set "gs://$BUCKET/"
gsutil cp gs://spls/gsp297/dummy_loan "gs://$BUCKET/"

echo "--------------------------------------------------------"
echo -e "${RED}${BOLD}🛑 PAUSED: ACTION REQUIRED!${RESET}"
echo -e "Go to the Qwiklabs page and click ${BOLD}'Check my progress'${RESET} for:"
echo -e "5. Create Event-based holds"
read -p "${YELLOW}👉 Press [ENTER] only AFTER you get the points for Event Hold...${RESET}"

log_info "Releasing Event lock & cleaning up..."
gsutil retention event release "gs://$BUCKET/dummy_loan"
log_warn "Waiting 12 seconds for the new retention period to expire..."
sleep 12
gsutil rm "gs://$BUCKET/dummy_loan"

log_info "Task 6: Cleaning up and deleting empty bucket..."
gsutil rb "gs://$BUCKET/"

echo "--------------------------------------------------------"
log_success "${BOLD}Lab Completed Successfully! (100/100) - Orbit of Ops${RESET}"
echo "--------------------------------------------------------"
