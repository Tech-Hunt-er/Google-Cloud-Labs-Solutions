#!/usr/bin/env bash
set -Eeuo pipefail
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# ==========================================================
# ORBIT OF OPS - ARC132 CLOUD SPEECH LAB MANUAL TEXT AUTOPILOT
# Fixes: API key --api-target error + empty API_KEY false success
# ==========================================================

RED=$'\033[0;91m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
CYAN=$'\033[0;96m'
WHITE=$'\033[0;97m'
ORANGE=$'\033[38;5;208m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

ok(){ echo "${GREEN}${BOLD}✅${RESET} $*"; }
info(){ echo "${BLUE}${BOLD}-->${RESET} $*"; }
warn(){ echo "${YELLOW}${BOLD}⚠️${RESET} $*"; }
fail(){ echo "${RED}${BOLD}❌ $*${RESET}"; exit 1; }

trap 'fail "Stopped near line ${LINENO}. The script did not complete successfully."' ERR

banner(){
  clear || true
  echo "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}${BOLD}║          ORBIT OF OPS - ARC132 CLOUD SPEECH LAB             ║${RESET}"
  echo "${CYAN}${BOLD}║        Elevating your Cloud & DevOps Journey! 🚀            ║${RESET}"
  echo "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo
}

footer(){
  echo
  echo "${ORANGE}${BOLD}🚀 Keep exploring the Orbit of Ops!${RESET}"
  echo "${CYAN}https://www.youtube.com/@orbitofops${RESET}"
  echo "${ORANGE}Please Subscribe to the channel for more Cloud & DevOps videos!${RESET}"
  echo
}

clean(){
  printf "%s" "${1:-}" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

metadata_value(){
  local path="$1"
  curl -fs -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/${path}" 2>/dev/null || true
}

resolve_var(){
  local name="$1"
  local fallback="${2:-}"
  local val=""
  val="$(clean "${!name:-}")"

  if [[ -z "$val" ]]; then
    val="$(clean "$(metadata_value "instance/attributes/${name}")")"
  fi
  if [[ -z "$val" ]]; then
    val="$(clean "$(metadata_value "project/attributes/${name}")")"
  fi
  if [[ -z "$val" ]]; then
    val="$fallback"
  fi

  printf "%s" "$val"
}

ask_with_default(){
  local var_name="$1"
  local label="$2"
  local default_value="$3"
  local current="${!var_name:-}"

  if [[ -z "$current" ]]; then
    read -r -p "${label} [${default_value}]: " current
    current="$(clean "$current")"
    [[ -z "$current" ]] && current="$default_value"
    printf -v "$var_name" "%s" "$current"
  fi
}

ask_required(){
  local var_name="$1"
  local label="$2"
  local current="${!var_name:-}"

  if [[ -z "$current" ]]; then
    read -r -p "${label}: " current
    current="$(clean "$current")"
    [[ -z "$current" ]] && fail "${label} is required."
    printf -v "$var_name" "%s" "$current"
  fi
}

json_has_key(){
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PY'
import json, sys
path, key = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
if key not in data:
    print(json.dumps(data, indent=2, ensure_ascii=False)[:2000])
    raise SystemExit(f"Missing expected key: {key}")
PY
}

run_gcloud_api_key_create(){
  local display_name="$1"

  if gcloud services api-keys create --help >/dev/null 2>&1; then
    gcloud services api-keys create \
      --project="${PROJECT_ID}" \
      --display-name="${display_name}" \
      --api-target=service=texttospeech.googleapis.com \
      --api-target=service=speech.googleapis.com \
      --api-target=service=translate.googleapis.com \
      --quiet
  else
    gcloud alpha services api-keys create \
      --project="${PROJECT_ID}" \
      --display-name="${display_name}" \
      --api-target=service=texttospeech.googleapis.com \
      --api-target=service=speech.googleapis.com \
      --api-target=service=translate.googleapis.com \
      --quiet
  fi
}

get_api_key_string(){
  local resource="$1"
  local out=""

  out="$(gcloud services api-keys get-key-string "${resource}" \
    --project="${PROJECT_ID}" \
    --location=global \
    --format='value(keyString)' 2>/dev/null || true)"

  if [[ -z "$out" ]]; then
    local key_id="${resource##*/}"
    out="$(gcloud services api-keys get-key-string "${key_id}" \
      --project="${PROJECT_ID}" \
      --location=global \
      --format='value(keyString)' 2>/dev/null || true)"
  fi

  printf "%s" "$out"
}

banner

PROJECT_ID="$(clean "$(gcloud config get-value project 2>/dev/null || true)")"
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
  PROJECT_ID="$(clean "$(metadata_value "project/project-id")")"
fi
[[ -z "$PROJECT_ID" ]] && fail "Project ID not found. Open the correct lab project/VM."
ok "Project detected: ${PROJECT_ID}"

INSTANCE_NAME="$(clean "$(metadata_value "instance/name")")"
if [[ -z "$INSTANCE_NAME" ]]; then
  warn "This does not look like the lab VM SSH session. Your lab says tasks 2-5 should be done inside the provisioned VM."
else
  ok "VM detected: ${INSTANCE_NAME}"
fi

info "Activating Python virtual environment..."
if [[ -f "venv/bin/activate" ]]; then
  source venv/bin/activate
else
  warn "venv not found; creating one."
  python3 -m venv venv
  source venv/bin/activate
fi
ok "venv active."

TASK_2_FILE_NAME="$(resolve_var task_2_file_name "synthesize-text.txt")"
TASK_3_REQUEST_FILE="$(resolve_var task_3_request_file "request.json")"
TASK_3_RESPONSE_FILE="$(resolve_var task_3_response_file "response.json")"
TASK_4_FILE="$(resolve_var task_4_file "translated_response.txt")"
TASK_5_FILE="$(resolve_var task_5_file "detected_response.txt")"

# Task 4 and Task 5 text values are intentionally NOT reused from env/metadata.
# They change from lab to lab, so the user must enter them manually every run.
TASK_4_SENTENCE=""
TASK_5_SENTENCE=""

show_current_values(){
  echo
  echo "${CYAN}${BOLD}╔════════════════ CURRENT DETECTED / DEFAULT LAB VALUES ════════════════╗${RESET}"
  printf "${WHITE}${BOLD}%-34s${RESET} %s\n" "Task 2 API response file:" "${TASK_2_FILE_NAME}"
  printf "${WHITE}${BOLD}%-34s${RESET} %s\n" "Task 3 request file:" "${TASK_3_REQUEST_FILE}"
  printf "${WHITE}${BOLD}%-34s${RESET} %s\n" "Task 3 response file:" "${TASK_3_RESPONSE_FILE}"
  printf "${WHITE}${BOLD}%-34s${RESET} %s\n" "Task 4 response file:" "${TASK_4_FILE}"
  printf "${WHITE}${BOLD}%-34s${RESET} %s\n" "Task 5 response file:" "${TASK_5_FILE}"
  printf "${YELLOW}${BOLD}%-34s${RESET} %s\n" "Task 4 sentence:" "Will be asked manually"
  printf "${YELLOW}${BOLD}%-34s${RESET} %s\n" "Task 5 sentence:" "Will be asked manually"
  echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
  echo
}

edit_file_values_one_by_one(){
  echo
  warn "File edit mode started. Press Enter on any line to keep the shown value."
  ask_with_default TASK_2_FILE_NAME "Task 2 API response file name. Do NOT use synthesize-text.json here" "${TASK_2_FILE_NAME}"
  ask_with_default TASK_3_REQUEST_FILE "Task 3 request file name" "${TASK_3_REQUEST_FILE}"
  ask_with_default TASK_3_RESPONSE_FILE "Task 3 response file name" "${TASK_3_RESPONSE_FILE}"
  ask_with_default TASK_4_FILE "Task 4 response file name" "${TASK_4_FILE}"
  ask_with_default TASK_5_FILE "Task 5 response file name" "${TASK_5_FILE}"
}

ask_task_sentences_every_time(){
  echo
  echo "${MAGENTA}${BOLD}╔════════════════ TASK 4 & TASK 5 TEXT INPUT REQUIRED ════════════════╗${RESET}"
  echo "${YELLOW}These two message/sentence values are lab-specific and can be different every time.${RESET}"
  echo "${YELLOW}Enter them exactly as shown in your lab instructions page.${RESET}"
  echo "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════════════════╝${RESET}"
  echo

  ask_required TASK_4_SENTENCE "Task 4 sentence to translate"
  ask_required TASK_5_SENTENCE "Task 5 sentence to detect"

  if [[ "${TASK_4_SENTENCE}" == "${TASK_5_SENTENCE}" ]]; then
    warn "Task 4 and Task 5 sentences are exactly the same. Usually they are different in the lab."
    read -r -n 1 -p "Press C to continue anyway, or press any other key to re-enter both sentences: " SAME_CONFIRM
    echo
    case "${SAME_CONFIRM}" in
      C|c)
        info "Continuing with same Task 4 and Task 5 sentence values as requested."
        ;;
      *)
        TASK_4_SENTENCE=""
        TASK_5_SENTENCE=""
        ask_required TASK_4_SENTENCE "Task 4 sentence to translate"
        ask_required TASK_5_SENTENCE "Task 5 sentence to detect"
        ;;
    esac
  fi
}

show_current_values
echo "${GREEN}${BOLD}Press C to continue with these file names.${RESET}"
echo "${YELLOW}${BOLD}Press any other key to edit file names one by one.${RESET}"
read -r -n 1 -p "Your choice: " VALUE_MODE
echo

case "${VALUE_MODE}" in
  C|c)
    info "Continuing with shown file names."
    ;;
  *)
    edit_file_values_one_by_one
    show_current_values
    ;;
esac

ask_task_sentences_every_time

if [[ "${TASK_2_FILE_NAME}" == "synthesize-text.json" ]]; then
  fail "Task 2 response file cannot be synthesize-text.json because that is the request file. Use synthesize-text.txt unless your lab says otherwise."
fi

echo
info "Enabling required services..."
gcloud services enable \
  apikeys.googleapis.com \
  texttospeech.googleapis.com \
  speech.googleapis.com \
  translate.googleapis.com \
  --project="${PROJECT_ID}" \
  --quiet >/dev/null
ok "Required services enabled."

echo
info "[Task 1] Creating/reusing API key with required API target restrictions..."
KEY_DISPLAY_NAME="orbit-arc132-api-key"
API_KEY="$(clean "${API_KEY:-}")"

if [[ -n "$API_KEY" ]]; then
  ok "Using API key already available in API_KEY environment variable."
else
  KEY_RESOURCE="$(gcloud services api-keys list \
    --project="${PROJECT_ID}" \
    --filter="displayName=${KEY_DISPLAY_NAME}" \
    --format="value(name)" \
    --limit=1 2>/dev/null || true)"

  if [[ -z "$KEY_RESOURCE" ]]; then
    info "No existing Orbit API key found. Trying automatic API key creation..."

    if run_gcloud_api_key_create "${KEY_DISPLAY_NAME}" >/tmp/orbit_api_key_create.log 2>&1; then
      sleep 8
      KEY_RESOURCE="$(gcloud services api-keys list \
        --project="${PROJECT_ID}" \
        --filter="displayName=${KEY_DISPLAY_NAME}" \
        --format="value(name)" \
        --limit=1 2>/dev/null || true)"
    else
      warn "Automatic API key creation failed."
      echo "${YELLOW}Reason from gcloud:${RESET}"
      cat /tmp/orbit_api_key_create.log || true
    fi
  fi

  if [[ -n "$KEY_RESOURCE" ]]; then
    API_KEY="$(get_api_key_string "${KEY_RESOURCE}")"
  fi
fi

if [[ -z "$API_KEY" ]]; then
  echo
  warn "API key is still empty, so automatic creation/reuse did not work."
  echo "${CYAN}${BOLD}Manual fallback:${RESET}"
  echo "1. Go to Google Cloud Console."
  echo "2. Open APIs & Services > Credentials."
  echo "3. Click Create credentials > API key."
  echo "4. Copy the generated API key."
  echo
  echo "${YELLOW}Optional CLI manual command:${RESET}"
  echo "gcloud services api-keys create --display-name='orbit-arc132-manual-key' \\"
  echo "  --api-target=service=texttospeech.googleapis.com \\"
  echo "  --api-target=service=speech.googleapis.com \\"
  echo "  --api-target=service=translate.googleapis.com"
  echo
  read -r -s -p "Paste the manually created API key here: " API_KEY
  echo
  API_KEY="$(clean "${API_KEY}")"
fi

[[ -z "$API_KEY" ]] && fail "No API key provided. Cannot continue."

export API_KEY
ok "API key ready. Continuing lab automation..."

echo
info "[Task 2] Creating Text-to-Speech request JSON..."
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

info "[Task 2] Calling Text-to-Speech API..."
curl -sS -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  --data-binary @synthesize-text.json \
  "https://texttospeech.googleapis.com/v1/text:synthesize?key=${API_KEY}" \
  -o "${TASK_2_FILE_NAME}"

json_has_key "${TASK_2_FILE_NAME}" "audioContent"
ok "Task 2 response saved: ${TASK_2_FILE_NAME}"

cat > tts_decode.py <<'PY'
import argparse
import json
from base64 import decodebytes

def decode_tts_output(input_file, output_file):
    with open(input_file, "r", encoding="utf-8") as f:
        response = json.load(f)
    audio_data = response["audioContent"]
    with open(output_file, "wb") as out:
        out.write(decodebytes(audio_data.encode("utf-8")))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Decode Cloud Text-to-Speech output")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    decode_tts_output(args.input, args.output)
PY

python3 tts_decode.py --input "${TASK_2_FILE_NAME}" --output synthesize-text-audio.mp3
ok "Audio generated: synthesize-text-audio.mp3"

echo
info "[Task 3] Creating Speech-to-Text request JSON..."
cat > "${TASK_3_REQUEST_FILE}" <<'JSON'
{
  "config": {
    "encoding": "FLAC",
    "sampleRateHertz": 44100,
    "languageCode": "fr-FR"
  },
  "audio": {
    "uri": "gs://cloud-samples-data/speech/corbeau_renard.flac"
  }
}
JSON

info "[Task 3] Calling Speech-to-Text API..."
curl -sS -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  --data-binary @"${TASK_3_REQUEST_FILE}" \
  "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
  -o "${TASK_3_RESPONSE_FILE}"

json_has_key "${TASK_3_RESPONSE_FILE}" "results"
ok "Task 3 response saved: ${TASK_3_RESPONSE_FILE}"

echo
info "[Task 4] Calling Translation API..."
python3 - "${TASK_4_SENTENCE}" > translate-request.json <<'PY'
import json, sys
print(json.dumps({"q": sys.argv[1], "target": "en", "format": "text"}, ensure_ascii=False))
PY

curl -sS -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  --data-binary @translate-request.json \
  "https://translation.googleapis.com/language/translate/v2?key=${API_KEY}" \
  -o "${TASK_4_FILE}"

json_has_key "${TASK_4_FILE}" "data"
ok "Task 4 response saved: ${TASK_4_FILE}"

echo
info "[Task 5] Calling Language Detection API..."
python3 - "${TASK_5_SENTENCE}" > detect-request.json <<'PY'
import json, sys
print(json.dumps({"q": [sys.argv[1]]}, ensure_ascii=False))
PY

curl -sS -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  --data-binary @detect-request.json \
  "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
  -o "${TASK_5_FILE}"

json_has_key "${TASK_5_FILE}" "data"
ok "Task 5 response saved: ${TASK_5_FILE}"

cat > orbit_arc132_resolved_values.txt <<EOF
PROJECT_ID=${PROJECT_ID}
TASK_2_FILE_NAME=${TASK_2_FILE_NAME}
TASK_3_REQUEST_FILE=${TASK_3_REQUEST_FILE}
TASK_3_RESPONSE_FILE=${TASK_3_RESPONSE_FILE}
TASK_4_FILE=${TASK_4_FILE}
TASK_5_FILE=${TASK_5_FILE}
EOF

echo
echo "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}║               ALL TASKS COMPLETED SUCCESSFULLY              ║${RESET}"
echo "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo
echo "Generated files:"
printf " - %s\n" \
  "synthesize-text.json" \
  "${TASK_2_FILE_NAME}" \
  "synthesize-text-audio.mp3" \
  "${TASK_3_REQUEST_FILE}" \
  "${TASK_3_RESPONSE_FILE}" \
  "${TASK_4_FILE}" \
  "${TASK_5_FILE}" \
  "orbit_arc132_resolved_values.txt"

footer
