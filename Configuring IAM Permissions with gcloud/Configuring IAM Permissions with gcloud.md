# Configuring IAM Permissions with gcloud || [GSP647](https://www.cloudskillsboost.google/focuses/7678?parent=catalog) ||

## 🔑 Solution [here](https://youtu.be/e5uGvyCrFTw)

### ⚙️ Execute the Following Commands in Cloud Shell

```
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

gcloud compute ssh centos-clean --zone=$ZONE --quiet
```
```
curl -LO raw.githubusercontent.com/Cloud-Wala-Banda/Labs-Solutions/main/Configuring%20IAM%20Permissions%20with%20gcloud/gsp647.sh
sudo chmod +x gsp647.sh

sudo chmod +x *.sh

./*.sh
```

# 🎉 Woohoo! You Did It! 🎉

Your hard work and determination paid off! 💻
You've successfully completed the lab. **Way to go!** 🚀

# <img src="../logo.png" alt="Tech Hunter Logo" width="45" align="center"> Tech Hunter
