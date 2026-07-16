#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATS_FILE="$PROJECT_DIR/data/ctf-stats.json"

if [[ ! -f "$STATS_FILE" ]]; then
  echo "Erreur : fichier data/ctf-stats.json introuvable."
  exit 1
fi

read -rp "Nombre de rooms terminées : " ROOMS
read -rp "Nombre de badges : " BADGES
read -rp "Classement, par exemple Top 35% : " RANK

if [[ -z "$ROOMS" || -z "$BADGES" || -z "$RANK" ]]; then
  echo "Erreur : toutes les valeurs doivent être renseignées."
  exit 1
fi

TEMP_FILE="$(mktemp)"
UPDATE_DATE="$(date '+%d/%m/%Y')"

jq \
  --arg rooms "$ROOMS" \
  --arg badges "$BADGES" \
  --arg rank "$RANK" \
  --arg updateDate "$UPDATE_DATE" \
  '
  .tryhackme.rooms = $rooms
  | .tryhackme.badges = $badges
  | .tryhackme.rank = $rank
  | .lastUpdate = $updateDate
  ' \
  "$STATS_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$STATS_FILE"

echo
echo "TryHackMe mis à jour :"
echo "- Rooms : $ROOMS"
echo "- Badges : $BADGES"
echo "- Rang : $RANK"
echo "- Date : $UPDATE_DATE"
