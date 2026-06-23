#!/usr/bin/env bash
set -Eeuo pipefail
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# =========================================================
# ORBIT OF OPS 🚀 | ARC132 SPEECH + TRANSLATION AUTOPILOT
# =========================================================
# Run this inside the ARC132 lab VM SSH terminal.
# It resolves lab variables from:
#   1) existing shell env vars
#   2) VM/project metadata attributes
#   3) safe defaults for filenames
#   4) prompt fallback for required sentences
# =========================================================

# ---------- Colors ----------
RED=$'\033[0;91m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
MAGENTA=$'\033[0;95m'
CYAN=$'\033[0;96m'
WHITE=$'\033[0;97m'
ORANGE=$'\033[38;5;208m'
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RESET=$'\033[0m'

# ---------- Branding ----------
orbit_footer() {
  echo
  echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo "${ORANGE}${BOLD} 💫 Join the Mission: Subscribe to Orbit of Ops${RESET}"
  echo "${CYAN}${UNDERLINE} https://www.youtube.com/@OrbitOfOps${RESET}"
  echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo
}

stage() {
  echo
  echo "${GREEN}${BOLD}=== $1 ===${RESET}"
  echo
}

info() { echo "${BLUE}${BOLD}➜${RESET} $*"; }
ok() { echo "${GREEN}${BOLD}✅${RESET} $*"; }
warn() { echo "${YELLOW}${BOLD}⚠️${RESET} $*"; }
fail() { echo "${RED}${BOLD}❌ $*${RESET}"; exit 1; }

trap 'fail "Mission aborted near line ${LINENO}. Check the message above and rerun after fixing it."' ERR

clear || true
echo "${CYAN}${BOLD}┌──────────────────────────────────────────────────────────────┐${RESET}"
echo "${CYAN}${BOLD}│        🌟 ORBIT OF OPS: ARC132 AUTOMATION MATRIX 🌟          │${RESET}"
echo "${CYAN}${BOLD}│     Text-to-Speech | Speech-to-Text | Translation API        │${RESET}"
echo "${CYAN}${BOLD}└──────────────────────────────────────────────────────────────┘${RESET}"
orbit_footer

# ---------- Metadata + variable helpers ----------
metadata_value() {
  local path="$1"
  curl -fs -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/${path}" 2>/dev/null || true
}

clean_value() {
  printf "%s" "${1:-}" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

resolve_var() {
  local name="$1"
  local fallback="${2:-}"
  local value=""

  # 1) Shell environment
  value="$(clean_value "${!name:-}")"

  # 2) Instance metadata attribute
  if [[ -z "$value" ]]; then
    value="$(clean_value "$(metadata_value "instance/attributes/${name}")")"
  fi

  # 3) Project metadata attribute
  if [[ -z "$value" ]]; then
    value="$(clean_value "$(metadata_value "project/attributes/${name}")")"
  fi

  # 4) Default fallback
  if [[ -z "$value" ]]; then
    value="$fallback"
  fi

  printf "%s" "$value"
}

ask_required() {
  local var_name="$1"
  local label="$2"
  local current_value="${!var_name:-}"

  if [[ -z "$current_value" ]]; then
    echo
    warn "$label was not found in shell env or metadata."
    read -r -p "Paste ${label} from your lab panel: " current_value
    current_value="$(clean_value "$current_value")"
    [[ -z "$current_value" ]] && fail "$label is required."
    printf -v "$var_name" "%s" "$current_value"
  fi
}

json_check_key() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PY'
import json, sys
path, key = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
if key not in data:
    print(json.dumps(data, indent=2)[:1200])
    raise SystemExit(f"Missing expected key: {key}")
PY
}

# ---------- Stage 1: Resolve project and lab values ----------
stage "STAGE 1: WORKSPACE + LAB VARIABLE RESOLUTION"

PROJECT_ID="$(clean_value "$(gcloud config get-value project 2>/dev/null || true)")"
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
  PROJECT_ID="$(clean_value "$(metadata_value "project/project-id")")"
fi
[[ -z "$PROJECT_ID" ]] && fail "Project ID not detected. Open the correct lab VM/Cloud Shell."
export PROJECT_ID
ok "Project detected: ${PROJECT_ID}"

INSTANCE_NAME="$(clean_value "$(metadata_value "instance/name")")"
ZONE_FULL="$(clean_value "$(metadata_value "instance/zone")")"
ZONE="${ZONE_FULL##*/}"
[[ -n "$INSTANCE_NAME" ]] && ok "VM detected: ${INSTANCE_NAME}"
[[ -n "$ZONE" ]] && ok "Zone detected: ${ZONE}"

# Lab task variables. These names match your current script.
TASK_2_FILE="$(resolve_var task_2_file_name "synthesize-text.txt")"
TASK_3_REQUEST_FILE="$(resolve_var task_3_request_file "speech-request.json")"
TASK_3_RESPONSE_FILE="$(resolve_var task_3_response_file "speech-response.txt")"
TASK_4_FILE="$(resolve_var task_4_file "translation-response.txt")"
TASK_5_FILE="$(resolve_var task_5_file "language-detection-response.txt")"
TASK_4_SENTENCE="$(resolve_var task_4_sentence "")"
TASK_5_SENTENCE="$(resolve_var task_5_sentence "")"

# Sentences are lab-specific; do not guess them if the lab has not exposed them.
ask_required TASK_4_SENTENCE "Task 4 sentence"
ask_required TASK_5_SENTENCE "Task 5 sentence"

cat > orbit_arc132_resolved_lab_env.txt <<EOF
PROJECT_ID=${PROJECT_ID}
INSTANCE_NAME=${INSTANCE_NAME}
ZONE=${ZONE}
task_2_file_name=${TASK_2_FILE}
task_3_request_file=${TASK_3_REQUEST_FILE}
task_3_response_file=${TASK_3_RESPONSE_FILE}
task_4_file=${TASK_4_FILE}
task_5_file=${TASK_5_FILE}
task_4_sentence=${TASK_4_SENTENCE}
task_5_sentence=${TASK_5_SENTENCE}
EOF

ok "Resolved lab values saved to orbit_arc132_resolved_lab_env.txt"
orbit_footer

# ---------- Stage 2: Prepare venv ----------
stage "STAGE 2: PYTHON VIRTUAL ENVIRONMENT ACTIVATION"

if [[ -f "venv/bin/activate" ]]; then
  # As required by the lab instruction.
  source venv/bin/activate
  ok "Activated existing venv."
else
  warn "venv not found. Creating one so the decode step can run."
  python3 -m venv venv
  source venv/bin/activate
  ok "Created and activated venv."
fi

# ---------- Stage 3: Enable APIs + API key ----------
stage "STAGE 3: API ENABLEMENT + API KEY CREATION"

info "Enabling required Google Cloud APIs..."
gcloud services enable \
  apikeys.googleapis.com \
  texttospeech.googleapis.com \
  speech.googleapis.com \
  translate.googleapis.com \
  --project="${PROJECT_ID}" \
  --quiet >/dev/null
ok "Required APIs enabled."

API_KEY="$(resolve_var API_KEY "")"

if [[ -z "$API_KEY" ]]; then
  KEY_DISPLAY_NAME="orbit-arc132-api-key"
  info "Looking for existing API key: ${KEY_DISPLAY_NAME}"

  KEY_RESOURCE="$(gcloud services api-keys list \
    --project="${PROJECT_ID}" \
    --filter="displayName=${KEY_DISPLAY_NAME}" \
    --format="value(name)" \
    --limit=1 2>/dev/null || true)"

  if [[ -z "$KEY_RESOURCE" ]]; then
    info "Creating API key for ARC132..."
    gcloud services api-keys create \
      --project="${PROJECT_ID}" \
      --display-name="${KEY_DISPLAY_NAME}" \
      --quiet >/dev/null

    # API key creation can take a few seconds to appear in list/get calls.
    sleep 8

    KEY_RESOURCE="$(gcloud services api-keys list \
      --project="${PROJECT_ID}" \
      --filter="displayName=${KEY_DISPLAY_NAME}" \
      --format="value(name)" \
      --limit=1)"
  fi

  [[ -z "$KEY_RESOURCE" ]] && fail "API key resource could not be created or found."

  API_KEY="$(gcloud services api-keys get-key-string "${KEY_RESOURCE}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --format="value(keyString)" 2>/dev/null || true)"

  if [[ -z "$API_KEY" ]]; then
    KEY_ID="${KEY_RESOURCE##*/}"
    API_KEY="$(gcloud services api-keys get-key-string "${KEY_ID}" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --format="value(keyString)" 2>/dev/null || true)"
  fi
fi

[[ -z "$API_KEY" ]] && fail "API_KEY not detected and automatic creation failed."
export API_KEY
ok "API key ready."
orbit_footer

# ---------- Stage 4: Text-to-Speech ----------
stage "STAGE 4: SYNTHETIC SPEECH GENERATION"

cat > synthesize-text.json <<'JSON'
{
  "input": {
    "text": "Cloud Text-to-Speech API allows developers to include natural-sounding, synthetic human speech as playable audio in their applications. The Text-to-Speech API converts text or Speech Synthesis Markup Language (SSML) input into audio data like MP3 or LINEAR16, the encoding used in WAV files."
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
JSON

info "Calling Text-to-Speech API and saving response to: ${TASK_2_FILE}"
curl -sS -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  --data-binary @synthesize-text.json \
  "https://texttospeech.googleapis.com/v1/text:synthesize?key=${API_KEY}" \
  -o "${TASK_2_FILE}"

json_check_key "${TASK_2_FILE}" "audioContent"
ok "Text-to-Speech response created: ${TASK_2_FILE}"

cat > tts_decode.py <<'PY'
import argparse
from base64 import decodebytes
import json

def decode_tts_output(input_file, output_file):
    with open(input_file, "r", encoding="utf-8") as input_handle:
        response = json.load(input_handle)
        audio_data = response["audioContent"]

    with open(output_file, "wb") as new_file:
        new_file.write(decodebytes(audio_data.encode("utf-8")))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Decode output from Cloud Text-to-Speech")
    parser.add_argument("--input", required=True, help="The response from the Text-to-Speech API.")
    parser.add_argument("--output", required=True, help="The name of the audio file to create.")
    args = parser.parse_args()
    decode_tts_output(args.input, args.output)
PY

python3 tts_decode.py --input "${TASK_2_FILE}" --output "synthesize-text-audio.mp3"
ok "Audio file generated: synthesize-text-audio.mp3"
orbit_footer

# ---------- Stage 5: Speech-to-Text ----------
stage "STAGE 5: SPEECH-TO-TEXT TRANSCRIPTION"

AUDIO_URI="gs://cloud-samples-data/speech/corbeau_renard.flac"

cat > "${TASK_3_REQUEST_FILE}" <<JSON
{
  "config": {
    "encoding": "FLAC",
    "sampleRateHertz": 44100,
    "languageCode": "fr-FR"
  },
  "audio": {
    "uri": "${AUDIO_URI}"
  }
}
JSON

info "Speech request file created: ${TASK_3_REQUEST_FILE}"
info "Calling Speech-to-Text API and saving response to: ${TASK_3_RESPONSE_FILE}"

curl -sS -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  --data-binary @"${TASK_3_REQUEST_FILE}" \
  "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
  -o "${TASK_3_RESPONSE_FILE}"

json_check_key "${TASK_3_RESPONSE_FILE}" "results"
ok "Speech transcription response created: ${TASK_3_RESPONSE_FILE}"
orbit_footer

# ---------- Stage 6: Translate Text ----------
stage "STAGE 6: CLOUD TRANSLATION TO ENGLISH"

python3 - "${TASK_4_SENTENCE}" > translate-request.json <<'PY'
import json, sys
print(json.dumps({
    "q": sys.argv[1],
    "target": "en",
    "format": "text"
}, ensure_ascii=False))
PY

info "Calling Translation API and saving response to: ${TASK_4_FILE}"

curl -sS -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  --data-binary @translate-request.json \
  "https://translation.googleapis.com/language/translate/v2?key=${API_KEY}" \
  -o "${TASK_4_FILE}"

json_check_key "${TASK_4_FILE}" "data"
ok "Translation response created: ${TASK_4_FILE}"
orbit_footer

# ---------- Stage 7: Detect Language ----------
stage "STAGE 7: LANGUAGE DETECTION"

python3 - "${TASK_5_SENTENCE}" > detect-request.json <<'PY'
import json, sys
print(json.dumps({
    "q": [sys.argv[1]]
}, ensure_ascii=False))
PY

info "Calling language detection API and saving response to: ${TASK_5_FILE}"

curl -sS -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  --data-binary @detect-request.json \
  "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
  -o "${TASK_5_FILE}"

json_check_key "${TASK_5_FILE}" "data"
ok "Language detection response created: ${TASK_5_FILE}"
orbit_footer

# ---------- Final ----------
echo "${GREEN}${BOLD}┌──────────────────────────────────────────────────────────────┐${RESET}"
echo "${GREEN}${BOLD}│              MISSION ACCOMPLISHED: ARC132 DONE              │${RESET}"
echo "${GREEN}${BOLD}└──────────────────────────────────────────────────────────────┘${RESET}"
echo
echo "${WHITE}${BOLD}Generated files:${RESET}"
printf "  • %s\n" \
  "synthesize-text.json" \
  "${TASK_2_FILE}" \
  "tts_decode.py" \
  "synthesize-text-audio.mp3" \
  "${TASK_3_REQUEST_FILE}" \
  "${TASK_3_RESPONSE_FILE}" \
  "${TASK_4_FILE}" \
  "${TASK_5_FILE}" \
  "orbit_arc132_resolved_lab_env.txt"
orbit_footer
