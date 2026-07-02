#!/bin/bash

# ==============================================================================
# Script:  Cloud Storage Lifecycle Management
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
log_info()    { echo -e "${CYAN}${BOLD}[ORBIT-OPS]${RESET} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[WAITING]${RESET} $1"; }

# --- Execution ---
clear
echo "--------------------------------------------------------"
echo "${BOLD}     🚀 Orbit of Ops | Storage Lifecycle Lab${RESET}"
echo "--------------------------------------------------------"

log_info "Initializing project configuration..."
export BUCKET=$(gcloud config get-value project)

log_info "Creating bucket: ${YELLOW}${BUCKET}${RESET}"
gsutil mb "gs://$BUCKET"

log_warn "Applying retention policies (10s)..."
sleep 5
gsutil retention set 10s "gs://$BUCKET"
gsutil retention get "gs://$BUCKET"

log_info "Uploading dummy transactions..."
gsutil cp gs://spls/gsp297/dummy_transactions "gs://$BUCKET/"
gsutil ls -L "gs://$BUCKET/dummy_transactions"

log_warn "Securing bucket with retention lock..."
sleep 5
gsutil retention lock "gs://$BUCKET/"

log_info "Testing temporary holds..."
gsutil retention temp set "gs://$BUCKET/dummy_transactions"
gsutil rm "gs://$BUCKET/dummy_transactions"
gsutil retention temp release "gs://$BUCKET/dummy_transactions"

log_info "Configuring event-based holds..."
gsutil retention event-default set "gs://$BUCKET/"
gsutil cp gs://spls/gsp297/dummy_loan "gs://$BUCKET/"
gsutil ls -L "gs://$BUCKET/dummy_loan"

log_info "Releasing event lock..."
gsutil retention event release "gs://$BUCKET/dummy_loan"
gsutil ls -L "gs://$BUCKET/dummy_loan"

echo "--------------------------------------------------------"
log_success "${BOLD}Lab Completed Successfully! - Orbit of Ops${RESET}"
echo "--------------------------------------------------------"
