#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATS_FILE="$PROJECT_DIR/data/ctf-stats.json"

if [[ ! -f "$STATS_FILE" ]]; then
  echo "Erreur : fichier data/ctf-stats.json introuvable."
  exit 1
fi

read -rp "Niveau HTB : " LEVEL
read -rp "XP actuelle : " XP
read -rp "Rang HTB, par exemple Beginner : " RANK

if [[ -z "$LEVEL" || -z "$XP" || -z "$RANK" ]]; then
  echo "Erreur : toutes les valeurs doivent être renseignées."
  exit 1
fi

if ! [[ "$LEVEL" =~ ^[0-9]+$ ]]; then
  echo "Erreur : le niveau doit être un nombre."
  exit 1
fi

if ! [[ "$XP" =~ ^[0-9]+$ ]]; then
  echo "Erreur : l'XP doit être un nombre."
  exit 1
fi

TEMP_FILE="$(mktemp)"
UPDATE_DATE="$(date '+%d/%m/%Y')"

trap 'rm -f "$TEMP_FILE"' EXIT

jq \
  --arg level "$LEVEL" \
  --arg xp "$XP" \
  --arg rank "$RANK" \
  --arg updateDate "$UPDATE_DATE" \
  '
  .hackthebox.level = $level
  | .hackthebox.xp = $xp
  | .hackthebox.rank = $rank
  | .lastUpdate = $updateDate
  ' \
  "$STATS_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$STATS_FILE"
trap - EXIT

echo
echo "Hack The Box mis à jour :"
echo "- Niveau : $LEVEL"
echo "- XP : $XP"
echo "- Rang : $RANK"
echo "- Date : $UPDATE_DATE"
