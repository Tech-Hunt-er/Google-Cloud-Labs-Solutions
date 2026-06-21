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

BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_MAGENTA=`tput setab 5`

BOLD=`tput bold`
RESET=`tput sgr0`

#----------------------------------------------------START--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution of Challenge Lab GSP313${RESET}"

# Deriving Region from Zone if not set explicitly
export REGION="${ZONE%-*}"

echo "${BLUE}${BOLD}Step 1: Setting up Task 1 (Multiple Web Servers)...${RESET}"

# 1. Create Firewall Rule for Network Load Balancer
gcloud compute firewall-rules create www-firewall-network-lb \
    --allow tcp:80 \
    --target-tags network-lb-tag \
    --network default

# 2. Create Three Web Server Instances (web1, web2, web3) with Apache
for i in 1 2 3; do
  gcloud compute instances create web$i \
    --zone=$ZONE \
    --machine-type=e2-small \
    --tags=network-lb-tag \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --metadata=startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo '<h3>Web Server: web'$i'</h3>' | tee /var/www/html/index.html"
done

echo "${RED}${BOLD}Task 1. ${RESET}""${WHITE}${BOLD}Create multiple web server instances${RESET}" "${GREEN}${BOLD}Completed${RESET}"

echo "${BLUE}${BOLD}Step 2: Setting up Task 2 (Network Load Balancing Service)...${RESET}"

# 1. Create a static external IP address
gcloud compute addresses create network-lb-ip-1 \
    --region=$REGION

# 2. Create a target pool
gcloud compute target-pools create www-pool \
    --region=$REGION \
    --instances=web1,web2,web3 \
    --instances-zone=$ZONE

# 3. Create a forwarding rule
gcloud compute forwarding-rules create network-lb-forwarding-rule \
    --region=$REGION \
    --address=network-lb-ip-1 \
    --ports=80 \
    --target-pool=www-pool

echo "${RED}${BOLD}Task 2. ${RESET}""${WHITE}${BOLD}Configure the load balancing service${RESET}" "${GREEN}${BOLD}Completed${RESET}"

echo "${BLUE}${BOLD}Step 3: Setting up Task 3 (HTTP Load Balancer)...${RESET}"

# 1. Create the health check firewall rule
gcloud compute firewall-rules create fw-allow-health-check \
    --network=default \
    --action=ALLOW \
    --direction=INGRESS \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=allow-health-check \
    --rules=tcp:80

# 2. Create an external IP address for the HTTP Load Balancer
gcloud compute addresses create lb-ipv4-1 \
    --global

# 3. Create the startup script for the instance template
cat << 'EOF' > lb-startup.sh
#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo "<h3>Web Server: $(hostname)</h3>" | tee /var/www/html/index.html
EOF

# 4. Create the instance template
gcloud compute instance-templates create lb-backend-template \
    --region=$REGION \
    --network=default \
    --subnet=default \
    --tags=allow-health-check \
    --machine-type=e2-medium \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --metadata-from-file=startup-script=lb-startup.sh

# 5. Create the Managed Instance Group (MIG)
gcloud compute instance-groups managed create lb-backend-group \
    --template=lb-backend-template \
    --size=2 \
    --zone=$ZONE

# 6. Set named ports for the instance group
gcloud compute instance-groups managed set-named-ports lb-backend-group \
    --named-ports=http:80 \
    --zone=$ZONE

# 7. Create the health check
gcloud compute health-checks create http http-basic-check \
    --port=80

# 8. Create a global backend service
gcloud compute backend-services create lb-backend-service \
    --protocol=HTTP \
    --port-name=http \
    --health-checks=http-basic-check \
    --global

# 9. Add the instance group as a backend to the backend service
gcloud compute backend-services add-backend lb-backend-service \
    --instance-group=lb-backend-group \
    --instance-group-zone=$ZONE \
    --global

# 10. Create the URL map
gcloud compute url-maps create web-map-http \
    --default-service=lb-backend-service

# 11. Create the target HTTP proxy
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map=web-map-http

# 12. Create the global forwarding rule
gcloud compute forwarding-rules create http-content-rule \
    --address=lb-ipv4-1 \
    --global \
    --target-http-proxy=http-lb-proxy \
    --ports=80

echo "${RED}${BOLD}Task 3. ${RESET}""${WHITE}${BOLD}Create an HTTP load balancer${RESET}" "${GREEN}${BOLD}Completed${RESET}"

echo "${YELLOW}${BOLD}Note:${RESET}""${CYAN}${BOLD} It may take 3 to 5 minutes for the HTTP Load Balancer to finish provisioning and health checks to pass.${RESET}"
echo "${BG_GREEN}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------END----------------------------------------------------------#
