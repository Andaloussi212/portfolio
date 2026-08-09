#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATS_FILE="$PROJECT_DIR/data/ctf-stats.json"
ENV_FILE="$PROJECT_DIR/.env"

if [[ ! -f "$STATS_FILE" ]]; then
    echo "Erreur : $STATS_FILE introuvable."
    exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Erreur : $ENV_FILE introuvable."
    exit 1
fi

# Charger le .env
set -a
source "$ENV_FILE"
set +a

if [[ -z "${HTB_API_TOKEN:-}" ]]; then
    echo "Erreur : HTB_API_TOKEN absent du .env."
    exit 1
fi

if [[ -z "${HTB_USER_ID:-}" ]]; then
    echo "Erreur : HTB_USER_ID absent du .env."
    exit 1
fi

echo "Récupération du profil Hack The Box..."

# --------------------------------------------------
# 1. Profil HTB classique
# --------------------------------------------------

PROFILE_RESPONSE="$(
    curl -fsS \
        -H "Authorization: Bearer $HTB_API_TOKEN" \
        -H "Accept: application/json" \
        "https://labs.hackthebox.com/api/v4/user/profile/basic/$HTB_USER_ID"
)"

USERNAME="$(jq -r '.profile.name // empty' <<< "$PROFILE_RESPONSE")"
RANK="$(jq -r '.profile.rank // empty' <<< "$PROFILE_RESPONSE")"
POINTS="$(jq -r '.profile.points // 0' <<< "$PROFILE_RESPONSE")"
ACCOUNT_ID="$(jq -r '.profile.account_id // empty' <<< "$PROFILE_RESPONSE")"

if [[ -z "$USERNAME" || -z "$ACCOUNT_ID" ]]; then
    echo "Erreur : impossible de récupérer correctement le profil HTB."
    exit 1
fi

# --------------------------------------------------
# 2. Nouveau système Level / XP
# --------------------------------------------------

echo "Récupération du niveau et de l'XP..."

XP_RESPONSE="$(
    curl -fsS \
        -H "Authorization: Bearer $HTB_API_TOKEN" \
        -H "Accept: application/json" \
        "https://labs.hackthebox.com/api/experience/v1/account/$ACCOUNT_ID"
)"

LEVEL="$(jq -r '.level // 0' <<< "$XP_RESPONSE")"
LEVEL_TITLE="$(jq -r '.levelTitle // empty' <<< "$XP_RESPONSE")"

TOTAL_XP="$(jq -r '.totalExperiencePoints // 0' <<< "$XP_RESPONSE")"
LEVEL_XP="$(jq -r '.levelExperiencePoints // 0' <<< "$XP_RESPONSE")"
XP_UNTIL_NEXT="$(jq -r '.experienceUntilNextLevel // 0' <<< "$XP_RESPONSE")"

# Exemple : 149 + 72 = 221
LEVEL_XP_MAX=$((LEVEL_XP + XP_UNTIL_NEXT))

UPDATE_DATE="$(date '+%d/%m/%Y')"

# --------------------------------------------------
# 3. Mise à jour du JSON
# --------------------------------------------------

TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

jq \
    --arg username "$USERNAME" \
    --arg rank "$RANK" \
    --argjson points "$POINTS" \
    --argjson level "$LEVEL" \
    --arg levelTitle "$LEVEL_TITLE" \
    --argjson totalXp "$TOTAL_XP" \
    --argjson levelXp "$LEVEL_XP" \
    --argjson levelXpMax "$LEVEL_XP_MAX" \
    --arg updateDate "$UPDATE_DATE" \
    '
    .hackthebox.username = $username
    | .hackthebox.rank = $rank
    | .hackthebox.points = $points
    | .hackthebox.level = $level
    | .hackthebox.levelTitle = $levelTitle
    | .hackthebox.totalXp = $totalXp
    | .hackthebox.xp = $levelXp
    | .hackthebox.xpMax = $levelXpMax
    | .lastUpdate = $updateDate
    ' \
    "$STATS_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$STATS_FILE"
trap - EXIT

echo
echo "Hack The Box mis à jour automatiquement :"
echo "- Username       : $USERNAME"
echo "- Rang           : $RANK"
echo "- Points         : $POINTS"
echo "- Niveau         : $LEVEL"
echo "- Titre          : $LEVEL_TITLE"
echo "- XP niveau      : $LEVEL_XP / $LEVEL_XP_MAX"
echo "- XP total       : $TOTAL_XP"
echo "- Date           : $UPDATE_DATE"
