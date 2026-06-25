#!/bin/bash
# Define color variables
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
ORANGE_TEXT=$'\033[38;5;208m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              🚀 WELCOME TO THE ORBIT OF OPS GUIDE 🚀             ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                   SCRIPT 3: TEST FAILOVER                        ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

LB_IP_GLOBAL=$(gcloud compute addresses describe ip-alb-global --global --format="value(address)")
echo -e "\n${YELLOW_TEXT}Checking if ALB is fully online (Waiting for HTTP 200 OK)...${RESET_FORMAT}"
while true; do
  HTTP_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "https://$LB_IP_GLOBAL" || true)
  if [ "$HTTP_STATUS" -eq 200 ]; then break; fi
  echo -n "."
  sleep 10
done

echo -e "\n\n${GREEN_TEXT}ALB is online! Initiating Failover sequence...${RESET_FORMAT}"
mkdir -p ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/google_compute_engine -N "" -q <<< y >/dev/null 2>&1 || true

read -r INSTANCE ZONE <<< $(gcloud compute instances list --filter="name~mig-alb-api-a" --format="value(name,zone.basename())" | head -n 1)

echo "${ORANGE_TEXT}Ensuring Nginx is running on Region A ($INSTANCE) to stabilize traffic...${RESET_FORMAT}"
gcloud compute ssh "$INSTANCE" --zone="$ZONE" --quiet --command="sudo systemctl start nginx"

echo "${YELLOW_TEXT}Waiting 30 seconds for traffic to balance...${RESET_FORMAT}"
sleep 30

echo "${RED_TEXT}Stopping Nginx to trigger failover!${RESET_FORMAT}"
gcloud compute ssh "$INSTANCE" --zone="$ZONE" --quiet --command="sudo systemctl stop nginx"

echo "${CYAN_TEXT}Failover triggered! Watching traffic route to Region B...${RESET_FORMAT}"
timeout 25 bash -c '
while true; do
  curl -k -s https://'"$LB_IP_GLOBAL"' | grep "Hello from"
  sleep 0.5
done
'

echo
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}   TASK 3 COMPLETE! Go click 'Check my progress' for 100/100!     ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@OrbitOfOps${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Please subscribe to Orbit of Ops for more cloud automation guides!${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe!${RESET_FORMAT}"
echo
