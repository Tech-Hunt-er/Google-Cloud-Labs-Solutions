# [Getting Started with Cloud Data Fusion](https://www.cloudskillsboost.google/focuses/12358?parent=catalog)

## 🔑 Solution [here]()

### ⚙️ Execute the Following Commands in Cloud Shell

```
curl -LO raw.githubusercontent.com/Orbit-of-Ops/Google-Cloud-Labs-Solutions/refs/heads/main/Getting%20Started%20with%20Cloud%20Data%20Fusion/shell.sh

sudo chmod +x *.sh

./*.sh
```
```
bq query --use_legacy_sql=false \
"SELECT * FROM \`${DEVSHELL_PROJECT_ID}.GCPQuickStart.top_rated_inexpensive\` LIMIT 10"
```

# 🎉 Woohoo! You Did It! 🎉  

Your hard work and determination paid off! 💻  
You've successfully completed the lab. **Way to go!** 🚀

# <img src="../logo.png" alt="Orbit of Ops Logo" width="45" align="center"> Orbit of Ops