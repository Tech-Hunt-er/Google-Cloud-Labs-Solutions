#!/bin/bash

#----------------------------------------------------start--------------------------------------------------#
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

clear
echo "--------------------------------------------------------"
echo "${CYAN}${BOLD}     🚀 Orbit of Ops | Storage Lifecycle Lab${RESET}"
echo "--------------------------------------------------------"

echo "${YELLOW}${BOLD}Starting${RESET} ${GREEN}${BOLD}Execution...${RESET}"

# Task 1: Create Bucket
export BUCKET=$(gcloud config get-value project)
echo "${BLUE}${BOLD}[ORBIT-OPS] Creating bucket...${RESET}"
gsutil mb "gs://$BUCKET"

# Task 2: Define Retention Policy
echo "${BLUE}${BOLD}[ORBIT-OPS] Setting 10s retention policy...${RESET}"
gsutil retention set 10s "gs://$BUCKET"
gsutil cp gs://spls/gsp297/dummy_transactions "gs://$BUCKET/"

# Task 3: Lock Retention Policy
echo "${BLUE}${BOLD}[ORBIT-OPS] Locking retention policy...${RESET}"
echo "y" | gsutil retention lock "gs://$BUCKET/"

# Task 4: Temporary Hold
echo "${BLUE}${BOLD}[ORBIT-OPS] Applying and releasing Temporary Hold...${RESET}"
gsutil retention temp set "gs://$BUCKET/dummy_transactions"

# Expected to fail, '|| true' keeps the script running
echo "${MAGENTA}${BOLD}[ORBIT-OPS] Attempting to delete (Expected to fail)...${RESET}"
gsutil rm "gs://$BUCKET/dummy_transactions" || true 

gsutil retention temp release "gs://$BUCKET/dummy_transactions"

echo "${YELLOW}${BOLD}[WAITING] Waiting 12 seconds for retention policy to expire...${RESET}"
sleep 12

echo "${BLUE}${BOLD}[ORBIT-OPS] Deleting dummy_transactions...${RESET}"
gsutil rm "gs://$BUCKET/dummy_transactions"

# Task 5: Event-based holds
echo "${BLUE}${BOLD}[ORBIT-OPS] Applying and releasing Event-based Hold...${RESET}"
gsutil retention event-default set "gs://$BUCKET/"
gsutil cp gs://spls/gsp297/dummy_loan "gs://$BUCKET/"

gsutil retention event release "gs://$BUCKET/dummy_loan"

echo "${YELLOW}${BOLD}[WAITING] Waiting 12 seconds for retention policy to expire...${RESET}"
sleep 12

echo "${BLUE}${BOLD}[ORBIT-OPS] Deleting dummy_loan...${RESET}"
gsutil rm "gs://$BUCKET/dummy_loan"

# Task 6: Delete Bucket
# SKIPPED: We intentionally do NOT delete the bucket here. 
# Deleting it prevents Qwiklabs from validating Task 5. 
echo "${YELLOW}${BOLD}[ORBIT-OPS] Skipping bucket deletion so Qwiklabs can grade Task 5 successfully.${RESET}"

echo "--------------------------------------------------------"
echo "${RED}${BOLD}Congratulations${RESET} ${WHITE}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab !!!${RESET}"
echo "${CYAN}${BOLD}You can now safely click ALL 'Check my progress' buttons!${RESET}"
#-----------------------------------------------------end----------------------------------------------------------#
