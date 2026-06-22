# ─── TASK 5: CLIENT VM ───────────────────────────────────────────────
# Orbit of Ops: client VM must be inside lb-network to reach internal LB VIP
echo "${ORANGE_TEXT}${BOLD_TEXT}[TASK 5] Creating client VM in ${ZONE_C}... | Orbit of Ops${RESET_FORMAT}"

gcloud compute instances create client-vm \
  --zone=${ZONE_C} \
  --machine-type=e2-micro \
  --network=lb-network \
  --subnet=backend-subnet \
  --tags=allow-ssh \
  --description="Orbit of Ops - internal client VM to test GSP636 NLB" \
  --quiet

echo "${GREEN_TEXT}  ✔ client-vm created in ${ZONE_C} (using e2-micro to avoid resource exhaustion)${RESET_FORMAT}"
echo ""
