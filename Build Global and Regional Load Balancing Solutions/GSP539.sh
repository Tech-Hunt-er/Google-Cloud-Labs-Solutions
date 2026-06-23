#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
ORANGE_TEXT=$'\033[38;5;208m'     

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# Orbit of Ops Welcome message 
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              WELCOME TO THE ORBIT OF OPS GUIDE                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}           GSP539: Global and Regional Load Balancing             ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Variable Collection
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION_A (e.g., us-central1): ${RESET_FORMAT}" REGION_A
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION_B (e.g., us-east4): ${RESET_FORMAT}" REGION_B

echo "export REGION_A=$REGION_A" >> ~/.bashrc
echo "export REGION_B=$REGION_B" >> ~/.bashrc
source ~/.bashrc

PROJECT_ID=$(gcloud config get-value project)

echo -e "\n${CYAN_TEXT}=======================================================${RESET_FORMAT}"
echo -e "${CYAN_TEXT} TASK 1: REGIONAL INTERNAL PROXY NLB                   ${RESET_FORMAT}"
echo -e "${CYAN_TEXT}=======================================================${RESET_FORMAT}"

echo "${ORANGE_TEXT}Creating Regional MIG for Internal Proxy...${RESET_FORMAT}"
gcloud compute instance-groups managed create mig-proxy-internal \
    --region=$REGION_B \
    --template=projects/$PROJECT_ID/regions/$REGION_B/instanceTemplates/template-proxy-internal \
    --size=1

gcloud compute instance-groups managed set-named-ports mig-proxy-internal \
    --region=$REGION_B \
    --named-ports=tcp80:80

echo "${ORANGE_TEXT}Creating Firewall Rules...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-allow-hc-proxy-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80

gcloud compute firewall-rules create fw-allow-proxy-subnet-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=10.129.0.0/23 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80

echo "${ORANGE_TEXT}Creating Health Check...${RESET_FORMAT}"
gcloud compute health-checks create tcp hc-internal-proxy \
    --region=$REGION_B \
    --port=80

echo "${ORANGE_TEXT}Reserving Internal Static IP...${RESET_FORMAT}"
gcloud compute addresses create ip-internal-proxy \
    --region=$REGION_B \
    --subnet=lb-backend-subnet-region-b \
    --purpose=SHARED_LOADBALANCER_VIP

echo "${ORANGE_TEXT}Creating Backend Service...${RESET_FORMAT}"
gcloud compute backend-services create internal-proxy-backend \
    --load-balancing-scheme=INTERNAL_MANAGED \
    --protocol=TCP \
    --region=$REGION_B \
    --health-checks=hc-internal-proxy \
    --health-checks-region=$REGION_B

echo "${ORANGE_TEXT}Attaching MIG to Backend Service...${RESET_FORMAT}"
gcloud compute backend-services add-backend internal-proxy-backend \
    --instance-group=mig-proxy-internal \
    --instance-group-region=$REGION_B \
    --region=$REGION_B

echo "${ORANGE_TEXT}Configuring Internal Frontend (Target Proxy & Forwarding Rule)...${RESET_FORMAT}"
gcloud compute target-tcp-proxies create target-proxy-internal \
    --region=$REGION_B \
    --backend-service=internal-proxy-backend

gcloud compute forwarding-rules create rule-internal-proxy \
    --region=$REGION_B \
    --load-balancing-scheme=INTERNAL_MANAGED \
    --network=lb-network \
    --subnet=lb-backend-subnet-region-b \
    --address=ip-internal-proxy \
    --target-tcp-proxy=target-proxy-internal \
    --target-tcp-proxy-region=$REGION_B \
    --ports=110

echo "${ORANGE_TEXT}Creating Client VM for testing (Zone C to avoid resource exhaustion)...${RESET_FORMAT}"
gcloud compute instances create vm-client-internal \
   --zone=${REGION_B}-c \
   --machine-type=e2-micro \
   --network=lb-network \
   --subnet=lb-backend-subnet-region-b \
   --tags=allow-ssh


echo -e "\n${CYAN_TEXT}=======================================================${RESET_FORMAT}"
echo -e "${CYAN_TEXT} TASK 2: GLOBAL EXTERNAL APPLICATION LOAD BALANCER     ${RESET_FORMAT}"
echo -e "${CYAN_TEXT}=======================================================${RESET_FORMAT}"

echo -e "${ORANGE_TEXT}Creating MIG A...${RESET_FORMAT}"
gcloud compute instance-groups managed create mig-alb-api-a \
    --template=template-alb-api \
    --size=1 \
    --region=$REGION_A

gcloud compute instance-groups managed set-named-ports mig-alb-api-a \
    --named-ports=http80:80 \
    --region=$REGION_A

echo -e "${ORANGE_TEXT}Creating MIG B...${RESET_FORMAT}"
gcloud compute instance-groups managed create mig-alb-api-b \
    --template=template-alb-api \
    --size=1 \
    --region=$REGION_B

gcloud compute instance-groups managed set-named-ports mig-alb-api-b \
    --named-ports=http80:80 \
    --region=$REGION_B

echo -e "${ORANGE_TEXT}Creating Global Firewall Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-allow-health-check-and-proxy \
    --network=default \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=tag-alb-api

echo -e "${ORANGE_TEXT}Creating Global Health Check...${RESET_FORMAT}"
gcloud compute health-checks create http http-check-alb \
    --global \
    --port=80

echo -e "${ORANGE_TEXT}Creating Global Backend Service...${RESET_FORMAT}"
gcloud compute backend-services create service-alb-global \
    --global \
    --protocol=HTTP \
    --health-checks=http-check-alb \
    --port-name=http80

echo -e "${ORANGE_TEXT}Adding Backends with Rate Limiting...${RESET_FORMAT}"
gcloud compute backend-services add-backend service-alb-global \
    --global \
    --instance-group=mig-alb-api-a \
    --instance-group-region=$REGION_A \
    --balancing-mode=RATE \
    --max-rate-per-instance=1

gcloud compute backend-services add-backend service-alb-global \
    --global \
    --instance-group=mig-alb-api-b \
    --instance-group-region=$REGION_B \
    --balancing-mode=RATE \
    --max-rate-per-instance=1

echo -e "${ORANGE_TEXT}Generating Self-Signed SSL Certificate...${RESET_FORMAT}"
openssl genrsa -out key.pem 2048

openssl req -new -x509 \
    -key key.pem \
    -out cert.pem \
    -days 1 \
    -subj "/CN=example.com"

gcloud compute ssl-certificates create cert-self-signed \
    --certificate=cert.pem \
    --private-key=key.pem \
    --global

echo -e "${ORANGE_TEXT}Reserving Global External IP...${RESET_FORMAT}"
gcloud compute addresses create ip-alb-global \
    --global

echo -e "${ORANGE_TEXT}Configuring Global Frontend (URL Map, Proxy, Forwarding Rule)...${RESET_FORMAT}"
gcloud compute url-maps create url-map-alb \
    --default-service=service-alb-global

gcloud compute target-https-proxies create https-proxy-alb \
    --url-map=url-map-alb \
    --ssl-certificates=cert-self-signed

gcloud compute forwarding-rules create https-forwarding-rule \
    --global \
    --target-https-proxy=https-proxy-alb \
    --ports=443 \
    --address=ip-alb-global


echo -e "\n${CYAN_TEXT}=======================================================${RESET_FORMAT}"
echo -e "${CYAN_TEXT} TASK 3: TESTING & VALIDATION                          ${RESET_FORMAT}"
echo -e "${CYAN_TEXT}=======================================================${RESET_FORMAT}"

echo -e "${MAGENTA_TEXT}Waiting 90 seconds for health checks and backends to initialize...${RESET_FORMAT}"
sleep 90

# Output Internal Load Balancer IP for reference
LB_IP_INTERNAL=$(gcloud compute addresses describe ip-internal-proxy \
    --region=$REGION_B \
    --format="value(address)")
echo "${GREEN_TEXT}Internal Load Balancer IP is ready: $LB_IP_INTERNAL${RESET_FORMAT}"

echo -e "${MAGENTA_TEXT}Initiating Failover Test...${RESET_FORMAT}"

# Create SSH key automatically if needed
mkdir -p ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/google_compute_engine -N "" -q <<< y >/dev/null 2>&1 || true

LB_IP_GLOBAL=$(gcloud compute addresses describe ip-alb-global \
  --global \
   --quiet \
  --format="get(address)")

# Native Multi-Variable Assignment via gcloud mapping engine
read -r INSTANCE ZONE <<< $(gcloud compute instances list \
    --filter="name:mig-alb-api-a" \
    --format="value(name,zone.basename())" | head -n 1)

(
  sleep 10
  gcloud compute ssh "$INSTANCE" \
    --zone="$ZONE" \
    --quiet \
    --command="sudo systemctl stop nginx"

  echo ""
  echo "===== Nginx stopped on $INSTANCE in $ZONE to simulate failure ====="
) &

timeout 40 bash -c '
while true; do
  curl -k -s https://'"$LB_IP_GLOBAL"' | grep "Hello from"
  sleep 0.5
done
'

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@OrbitOfOps${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Please subscribe to Orbit of Ops for more cloud automation guides!${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe!${RESET_FORMAT}"
echo
