#!/bin/bash

set -eou pipefail

# Ask how many key-value pairs should be in the secret
NUM_VARS=$(gum input --placeholder "How many variables for the secret?" --value "1")
NUM_VARS=${NUM_VARS:-1}

# Prompt for secret metadata
SECRET_NAME=$(gum input --placeholder "Secret name")
NAMESPACE=$(kubectl get ns | awk 'NR>1 {print $1}' | gum filter --placeholder='Choose Namespace')

# Collect key-value pairs or file inputs
declare -a SECRET_ARGS=()
for ((i = 1; i <= NUM_VARS; i++)); do
  NAME=$(gum input --placeholder "Key name for variable #$i")

  # Choose input method
  USE_FILE=$(gum choose "Manual input (from-literal)" "File input (from-file)")

  if [[ $USE_FILE == "File input (from-file)" ]]; then
    FILE_PATH=$(gum input --placeholder "Path to file for $NAME")
    if [[ ! -f $FILE_PATH ]]; then
      echo "❌ File '$FILE_PATH' does not exist. Exiting."
      exit 1
    fi
    SECRET_ARGS+=(--from-file="$NAME=$FILE_PATH")
  else
    gum style --foreground 202 --border normal --margin "1" --padding "1" \
      "If you're inputting JSON manually, make sure all double quotes (\") are escaped:

Example:
  {\\\"key\\\":\\\"value\\\"}

For complex values, use file input instead."
    VALUE=$(gum input --placeholder "Value for $NAME")
    SECRET_ARGS+=(--from-literal="$NAME=$VALUE")
  fi
done

# Create the raw secret YAML
kubectl create secret generic "$SECRET_NAME" -n "$NAMESPACE" \
  "${SECRET_ARGS[@]}" \
  --dry-run=client -o yaml >"${SECRET_NAME}.yaml"

# Seal the secret
kubeseal -f "${SECRET_NAME}.yaml" -w "${SECRET_NAME}.yaml"

echo "Sealed secret written to ${SECRET_NAME}.yaml"

