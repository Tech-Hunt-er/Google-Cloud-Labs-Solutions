#!/bin/bash

# ==============================================================================
# Orbit of Ops - Cloud Speech API Challenge Lab (ARC132)
# ==============================================================================

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
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome Banner
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}               ORBIT OF OPS - CLOUD SPEECH LAB           ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          Elevating your Cloud & DevOps Journey!         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

# ------------------------------------------------------------------------------
# INTERACTIVE VARIABLE COLLECTION
# ------------------------------------------------------------------------------
echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Please fetch the following variables from your lab instructions page:${RESET_FORMAT}"
echo

read -p "📄 Enter the result file name for Task 2 (e.g., synthesize-text.txt): " task_2_file_name
read -p "📄 Enter the request file name for Task 3 (e.g., speech-request.json): " task_3_request_file
read -p "📄 Enter the response file name for Task 3 (e.g., speech-response.json): " task_3_response_file
read -p "📝 Enter the Japanese sentence to translate for Task 4: " task_4_sentence
read -p "📄 Enter the response file name for Task 4 (e.g., translate-response.txt): " task_4_file
read -p "📝 Enter the unknown language sentence to detect for Task 5: " task_5_sentence
read -p "📄 Enter the response file name for Task 5 (e.g., detect-response.txt): " task_5_file

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 === INITIATING AUTOMATION SEQUENCE ===${RESET_FORMAT}"
echo

# ------------------------------------------------------------------------------
# ENVIRONMENT SETUP
# ------------------------------------------------------------------------------
audio_uri="gs://cloud-samples-data/speech/corbeau_renard.flac"
export PROJECT_ID=$(gcloud config get-value project)

echo "${BLUE_TEXT}--> Activating Python Virtual Environment...${RESET_FORMAT}"
source venv/bin/activate

# ------------------------------------------------------------------------------
# TASK 1: Create an API Key
# ------------------------------------------------------------------------------
echo "${BLUE_TEXT}--> [Task 1] Enabling API Keys service and generating API Key...${RESET_FORMAT}"

gcloud services enable apikeys.googleapis.com --quiet
export API_KEY=$(gcloud alpha services api-keys create --display-name="speech-lab-key" --format="value(keyString)")

echo "${GREEN_TEXT}--> ✅ API Key successfully generated: ${API_KEY}${RESET_FORMAT}"
sleep 5 # Giving the API key a moment to propagate in GCP

# ------------------------------------------------------------------------------
# TASK 2: Text-to-Speech
# ------------------------------------------------------------------------------
echo "${BLUE_TEXT}--> [Task 2] Generating synthetic speech JSON...${RESET_FORMAT}"

cat > synthesize-text.json <<EOF
{
    "input": {
        "text": "Cloud Text-to-Speech API allows developers to include natural-sounding, synthetic human speech as playable audio in their applications. The Text-to-Speech API converts text or Speech Synthesis Markup Language (SSML) input into audio data like MP3 or LINEAR16 (the encoding used in WAV files)."
    },
    "voice": {
        "languageCode": "en-gb",
        "name": "en-GB-Standard-A",
        "ssmlGender": "FEMALE"
    },
    "audioConfig": {
        "audioEncoding": "MP3"
    }
}
EOF

echo "${BLUE_TEXT}--> [Task 2] Calling Text-to-Speech API...${RESET_FORMAT}"
curl -s -X POST \
-H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
-H "Content-Type: application/json; charset=utf-8" \
-d @synthesize-text.json "https://texttospeech.googleapis.com/v1/text:synthesize" \
> "$task_2_file_name"

# ------------------------------------------------------------------------------
# TASK 3: Speech-to-Text Transcription
# ------------------------------------------------------------------------------
echo "${BLUE_TEXT}--> [Task 3] Generating Speech-to-Text request JSON...${RESET_FORMAT}"
cat > "$task_3_request_file" <<EOF
{
    "config": {
        "encoding": "FLAC",
        "sampleRateHertz": 44100,
        "languageCode": "fr-FR"
    },
    "audio": {
        "uri": "$audio_uri"
    }
}
EOF

echo "${BLUE_TEXT}--> [Task 3] Calling Speech-to-Text API...${RESET_FORMAT}"
curl -s -X POST -H "Content-Type: application/json" \
--data-binary @"$task_3_request_file" \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
-o "$task_3_response_file"

# ------------------------------------------------------------------------------
# TASK 4: Cloud Translation API (Translate)
# ------------------------------------------------------------------------------
echo "${BLUE_TEXT}--> [Task 4] Calling Translation API (Japanese to English)...${RESET_FORMAT}"
curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": \"$task_4_sentence\"}" \
"https://translation.googleapis.com/language/translate/v2?key=${API_KEY}&source=ja&target=en" \
> "$task_4_file"

# ------------------------------------------------------------------------------
# TASK 5: Cloud Translation API (Detect)
# ------------------------------------------------------------------------------
echo "${BLUE_TEXT}--> [Task 5] Calling Translation API (Language Detection)...${RESET_FORMAT}"
curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": [\"$task_5_sentence\"]}" \
"https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
> "$task_5_file"

# ------------------------------------------------------------------------------
# Completion Banner
# ------------------------------------------------------------------------------
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}             ALL TASKS COMPLETED SUCCESSFULLY!            ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Keep exploring the Orbit of Ops!${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@orbitofops${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Please Subscribe to the channel for more Cloud & DevOps videos!${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe!${RESET_FORMAT}"
echo
