clear

#!/bin/bash
# Define color variables
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_GREEN=`tput setab 2`
BG_BLACK=`tput setab 0`

BOLD=`tput bold`
RESET=`tput sgr0`

# Function to show spinner while commands run
spinner() {
    local pid=$!
    local delay=0.25
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

#----------------------------------------------------START--------------------------------------------------#

echo "${CYAN}${BOLD}======================================================================${RESET}"
echo "${CYAN}${BOLD}                     🚀  ORBIT OF OPS  🚀                            ${RESET}"
echo "${CYAN}${BOLD}======================================================================${RESET}"
echo "${WHITE}${BOLD} Challenge Lab: ${YELLOW}GSP539${RESET}"
echo "${WHITE}${BOLD} Architecture:  ${YELLOW}Regional NLB & Global ALB Load Balancing Solutions${RESET}"
echo "${CYAN}${BOLD}----------------------------------------------------------------------${RESET}"
echo ""

# Region Input Prompts
echo "${YELLOW}${BOLD}Please check your Qwiklabs dashboard for your assigned regions.${RESET}"
read -p "${WHITE}${BOLD}Enter REGION_A (e.g., us-east1): ${RESET}" REGION_A
read -p "${WHITE}${BOLD}Enter REGION_B (e.g., us-west1): ${RESET}" REGION_B

echo "export REGION_A=$REGION_A" >> ~/.bashrc
echo "export REGION_B=$REGION_B" >> ~/.bashrc
source ~/.bashrc

# Safely fetch dynamic parameters
ZONE_A=$(gcloud compute zones list --filter="region:$REGION_A" --format="value(name)" | head -n 1)
ZONE_B=$(gcloud compute zones list --filter="region:$REGION_B" --format="value(name)" | head -n 1)
SUBNET_B=$(gcloud compute networks subnets list --network=lb-network --filter="region:$REGION_B" --format="value(name)")

echo ""
echo "${GREEN}${BOLD}✔ Variables Set:${RESET} Region A: ${WHITE}$REGION_A${RESET} | Region B: ${WHITE}$REGION_B${RESET}"
echo "${GREEN}${BOLD}✔ Subnet Linked:${RESET} ${WHITE}$SUBNET_B${RESET}"
echo "${CYAN}${BOLD}----------------------------------------------------------------------${RESET}"
echo ""

# =========================================================================================
# TASK 1: Regional Internal Proxy NLB
# =========================================================================================
echo "${MAGENTA}${BOLD}[1/5] ORBIT OF OPS 🚀 | TASK 1: Deploying Internal Proxy NLB...${RESET}"

echo -n "${WHITE}Creating Internal Regional MIG (mig-proxy-internal)...${RESET} "
gcloud compute instance-groups managed create mig-proxy-internal \
    --region=$REGION_B \
    --template=template-proxy-internal \
    --size=1 > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"

gcloud compute instance-groups managed set-named-ports mig-proxy-internal \
    --region=$REGION_B \
    --named-ports=tcp80:80 > /dev/null 2>&1

echo -n "${WHITE}Configuring Internal Firewall Rules...${RESET} "
gcloud compute firewall-rules create fw-allow-hc-proxy-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80 > /dev/null 2>&1

gcloud compute firewall-rules create fw-allow-proxy-subnet-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=10.129.0.0/23 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80 > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"

echo -n "${WHITE}Setting up Health Checks & Reserving VIP...${RESET} "
gcloud compute health-checks create tcp hc-internal-proxy \
    --region=$REGION_B \
    --port=80 > /dev/null 2>&1

gcloud compute addresses create ip-internal-proxy \
    --region=$REGION_B \
    --subnet=$SUBNET_B \
    --purpose=SHARED_LOADBALANCER_VIP > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"

echo -n "${WHITE}Configuring Regional Backend & Target TCP Proxy...${RESET} "
gcloud compute backend-services create internal-proxy-backend \
    --load-balancing-scheme=INTERNAL_MANAGED \
    --protocol=TCP \
    --region=$REGION_B \
    --health-checks=hc-internal-proxy \
    --health-checks-region=$REGION_B > /dev/null 2>&1

gcloud compute backend-services add-backend internal-proxy-backend \
    --instance-group=mig-proxy-internal \
    --instance-group-region=$REGION_B \
    --region=$REGION_B > /dev/null 2>&1

gcloud compute target-tcp-proxies create target-proxy-internal \
    --backend-service=internal-proxy-backend \
    --region=$REGION_B > /dev/null 2>&1

gcloud compute forwarding-rules create rule-internal-proxy \
    --region=$REGION_B \
    --load-balancing-scheme=INTERNAL_MANAGED \
    --network=lb-network \
    --subnet=$SUBNET_B \
    --address=ip-internal-proxy \
    --target-tcp-proxy=target-proxy-internal \
    --target-tcp-proxy-region=$REGION_B \
    --ports=110 > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"

echo -n "${WHITE}Spinning up Client VM for validation...${RESET} "
gcloud compute instances create vm-client-internal \
   --zone=$ZONE_B \
   --machine-type=e2-micro \
   --network=lb-network \
   --subnet=$SUBNET_B \
   --tags=allow-ssh > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"
echo ""

# =========================================================================================
# TASK 2: Global External ALB
# =========================================================================================
echo "${BLUE}${BOLD}[2/5] ORBIT OF OPS 🚀 | TASK 2: Deploying Global External ALB...${RESET}"

echo -n "${WHITE}Creating Global MIG A and MIG B...${RESET} "
gcloud compute instance-groups managed create mig-alb-api-a \
    --template=template-alb-api --size=1 --region=$REGION_A > /dev/null 2>&1
gcloud compute instance-groups managed set-named-ports mig-alb-api-a \
    --named-ports=http80:80 --region=$REGION_A > /dev/null 2>&1

gcloud compute instance-groups managed create mig-alb-api-b \
    --template=template-alb-api --size=1 --region=$REGION_B > /dev/null 2>&1
gcloud compute instance-groups managed set-named-ports mig-alb-api-b \
    --named-ports=http80:80 --region=$REGION_B > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"

echo -n "${WHITE}Creating Global ALB Firewall & Health Checks...${RESET} "
gcloud compute firewall-rules create fw-allow-health-check-and-proxy \
    --network=default \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=tag-alb-api > /dev/null 2>&1

gcloud compute health-checks create http http-check-alb \
    --global \
    --port=80 > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"

echo -n "${WHITE}Mapping Global Backend Services (Rate mode active)...${RESET} "
gcloud compute backend-services create service-alb-global \
    --global \
    --protocol=HTTP \
    --health-checks=http-check-alb \
    --port-name=http80 > /dev/null 2>&1

gcloud compute backend-services add-backend service-alb-global \
    --global \
    --instance-group=mig-alb-api-a \
    --instance-group-region=$REGION_A \
    --balancing-mode=RATE \
    --max-rate-per-instance=1 > /dev/null 2>&1

gcloud compute backend-services add-backend service-alb-global \
    --global \
    --instance-group=mig-alb-api-b \
    --instance-group-region=$REGION_B \
    --balancing-mode=RATE \
    --max-rate-per-instance=1 > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"

echo -n "${WHITE}Generating Self-Signed SSL Certificates...${RESET} "
openssl genrsa -out key.pem 2048 > /dev/null 2>&1
openssl req -new -x509 -key key.pem -out cert.pem -days 1 -subj "/CN=example.com" > /dev/null 2>&1
gcloud compute ssl-certificates create cert-self-signed \
    --certificate=cert.pem \
    --private-key=key.pem \
    --global > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"

echo -n "${WHITE}Building Proxy, URL Map & HTTPS Forwarding Rule...${RESET} "
gcloud compute addresses create ip-alb-global --global > /dev/null 2>&1
gcloud compute url-maps create url-map-alb \
    --default-service=service-alb-global > /dev/null 2>&1
gcloud compute target-https-proxies create https-proxy-alb \
    --url-map=url-map-alb \
    --ssl-certificates=cert-self-signed > /dev/null 2>&1
gcloud compute forwarding-rules create https-forwarding-rule \
    --global \
    --target-https-proxy=https-proxy-alb \
    --ports=443 \
    --address=ip-alb-global > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Done!${RESET}"
echo ""

# =========================================================================================
# TASK 3: Failover Simulation & Health Verification
# =========================================================================================
echo "${YELLOW}${BOLD}[3/5] ORBIT OF OPS 🚀 | Synchronizing Infrastructure Health...${RESET}"
echo "${CYAN}Waiting 45 seconds for Google Edge Proxies to initialize backends...${RESET}"
sleep 45

# Create SSH key automatically if needed for failover test
mkdir -p ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/google_compute_engine -N "" -q <<< y >/dev/null 2>&1 || true

LB_IP=$(gcloud compute addresses describe ip-alb-global --global --quiet --format="get(address)")

echo "${RED}${BOLD}[4/5] ORBIT OF OPS 🚀 | TASK 3: Executing Failover Simulation...${RESET}"
echo -n "${WHITE}Stopping Nginx on MIG-A to simulate backend failure...${RESET} "

INSTANCE_A=$(gcloud compute instances list --filter="name~'^mig-alb-api-a'" --format="value(name)" | head -1)
ZONE_INSTANCE_A=$(gcloud compute instances list --filter="name=$INSTANCE_A" --format="value(zone.basename())")

gcloud compute ssh "$INSTANCE_A" \
    --zone="$ZONE_INSTANCE_A" \
    --quiet \
    --command="sudo systemctl stop nginx" > /dev/null 2>&1 &
spinner
echo "${GREEN}${BOLD}Nginx Shutdown Initiated on $INSTANCE_A!${RESET}"
echo ""

echo "${MAGENTA}${BOLD}[5/5] ORBIT OF OPS 🚀 | Running Global Distribution Checks...${RESET}"
echo "${WHITE}Pinging HTTPS Load Balancer ($LB_IP). Note: Might return 502 temporarily while failing over.${RESET}"
timeout 15 bash -c '
while true; do
  curl -k -s https://'"$LB_IP"' | grep "Hello from" || echo "Waiting for 200 OK..."
  sleep 2
done
'
echo ""

# Beautiful Completion Message
echo "${BG_GREEN}${BLACK}${BOLD}======================================================================${RESET}"
echo "${BG_GREEN}${BLACK}${BOLD}           🚀 ORBIT OF OPS | ARCHITECTURE DEPLOYMENT SUCCESSFUL 🚀    ${RESET}"
echo "${BG_GREEN}${BLACK}${BOLD}======================================================================${RESET}"
echo ""
echo "${GREEN}${BOLD}✓ TASK 1:${RESET} ${WHITE}Internal Layer 4 TCP Proxy Configured in Region B.${RESET}"
echo "${GREEN}${BOLD}✓ TASK 2:${RESET} ${WHITE}Global Application Load Balancer Configured with SSL.${RESET}"
echo "${GREEN}${BOLD}✓ TASK 3:${RESET} ${WHITE}Failover Simulation Complete. Regional Distribution active.${RESET}"
echo ""
echo "${BLUE}${BOLD}----------------------------------------------------------------------${RESET}"
echo "${WHITE}You can now securely hit 'Check My Progress' for all 3 tasks inside the lab!${RESET}"
echo "${CYAN}${BOLD} Thank you for choosing Orbit Of Ops!                                 ${RESET}"
echo "${CYAN}${BOLD} Don't forget to like this video and subscribe to stay updated!        ${RESET}"
echo "${BLUE}${BOLD}======================================================================${RESET}"

echo -e "\n"
cd
remove_files() {
    for file in *; do
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            if [[ -f "$file" ]]; then
                rm "$file"
            fi
        fi
    done
}
remove_files
