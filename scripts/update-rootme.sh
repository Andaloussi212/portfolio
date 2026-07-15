#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
STATS_FILE="$PROJECT_DIR/data/ctf-stats.json"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Erreur : fichier .env introuvable."
  exit 1
fi

if [[ ! -f "$STATS_FILE" ]]; then
  echo "Erreur : fichier data/ctf-stats.json introuvable."
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ -z "${ROOTME_API_KEY:-}" ]]; then
  echo "Erreur : ROOTME_API_KEY absente du fichier .env."
  exit 1
fi

USER_ID="$(
  curl --silent --fail \
    --cookie "api_key=${ROOTME_API_KEY}" \
    "https://api.www.root-me.org/auteurs?nom=4ndalussi" |
  jq -r '.[0]["0"].id_auteur'
)"

if [[ -z "$USER_ID" || "$USER_ID" == "null" ]]; then
  echo "Erreur : identifiant Root-Me introuvable."
  exit 1
fi

PROFILE="$(
  curl --silent --fail \
    --cookie "api_key=${ROOTME_API_KEY}" \
    "https://api.www.root-me.org/auteurs/${USER_ID}"
)"

SCORE="$(jq -r '.score' <<< "$PROFILE")"
POSITION="$(jq -r '.position' <<< "$PROFILE")"
CHALLENGES="$(jq -r '.challenges | length' <<< "$PROFILE")"
UPDATE_DATE="$(date '+%d/%m/%Y')"

TEMP_FILE="$(mktemp)"

jq \
  --arg score "$SCORE" \
  --arg position "$POSITION" \
  --arg challenges "$CHALLENGES" \
  --arg updateDate "$UPDATE_DATE" \
  '
  .rootme.points = $score
  | .rootme.rank = $position
  | .rootme.challenges = $challenges
  | .lastUpdate = $updateDate
  ' \
  "$STATS_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$STATS_FILE"

echo "Root-Me mis à jour :"
echo "- Points : $SCORE"
echo "- Challenges : $CHALLENGES"
echo "- Rang : $POSITION"
echo "- Date : $UPDATE_DATE"
