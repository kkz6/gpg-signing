#!/bin/bash

KEY_COMMENT="git-ssh-signing-key"
KEY_PATH="$HOME/.ssh/$KEY_COMMENT"
EXPORT_ONLY=0
FORCE=0
GPG_MODE=0
IMPORT_MODE=0
GITHUB_TOKEN=""
GITHUB_USERNAME=""
EMAIL=""

usage() {
  echo "Usage: $0 [-f] [-x] [-g] [-e email] [-t github_token] [-u github_username] [--import]"
  echo "  -f                Force regenerate SSH signing key"
  echo "  -x                Only export SSH signing key to GitHub"
  echo "  -g                Use GPG signing instead of SSH"
  echo "  -e email          Email for GPG key"
  echo "  -t token          GitHub personal access token"
  echo "  -u username       GitHub username"
  echo "  --import          Use existing SSH signing key"
  exit 1
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    -f) FORCE=1; shift ;;
    -x) EXPORT_ONLY=1; shift ;;
    -g) GPG_MODE=1; shift ;;
    -e) EMAIL="$2"; shift 2 ;;
    -t) GITHUB_TOKEN="$2"; shift 2 ;;
    -u) GITHUB_USERNAME="$2"; shift 2 ;;
    --import) IMPORT_MODE=1; shift ;;
    *) usage ;;
  esac
done

#######################################
# SSH-based commit signing functions
#######################################
setup_ssh_signing_key() {
  if [[ -f "$KEY_PATH" && $FORCE -eq 0 ]]; then
    echo "✅ SSH signing key already exists at $KEY_PATH"
  elif [[ $EXPORT_ONLY -eq 0 && $IMPORT_MODE -eq 0 ]]; then
    echo "🔐 Generating new SSH key..."
    ssh-keygen -t ed25519 -C "$KEY_COMMENT" -f "$KEY_PATH" -N ""
  elif [[ $IMPORT_MODE -eq 1 ]]; then
    if [[ ! -f "$KEY_PATH" || ! -f "$KEY_PATH.pub" ]]; then
      echo "❌ SSH key files not found at $KEY_PATH and $KEY_PATH.pub"
      exit 1
    fi
    echo "📥 Using imported SSH signing key."
  fi

  echo "🔑 Adding SSH key to agent..."
  eval "$(ssh-agent -s)"
  ssh-add "$KEY_PATH"

  echo "🛠 Configuring Git to use SSH key for commit signing..."
  git config --global gpg.format ssh
  git config --global user.signingkey "$(cat $KEY_PATH.pub)"
  git config --global commit.gpgsign true

  echo "✅ SSH signing setup complete."
}

upload_ssh_key_to_github() {
  if [[ -z "$GITHUB_TOKEN" || -z "$GITHUB_USERNAME" ]]; then
    echo "⚠️ GitHub credentials not provided. Skipping key upload."
    return
  fi

  PUB_KEY=$(cat "$KEY_PATH.pub")
  TITLE="Git SSH Signing Key from $(hostname) on $(date +%Y-%m-%d_%H-%M-%S)"

  echo "📡 Uploading SSH signing key to GitHub..."

  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/user/ssh_signing_keys \
    -d "{\"key\":\"$PUB_KEY\",\"title\":\"$TITLE\"}")

  if [[ "$RESPONSE" -eq 201 ]]; then
    echo "✅ SSH signing key uploaded to GitHub."
  else
    echo "❌ Failed to upload signing key. HTTP status: $RESPONSE"
  fi
}

#######################################
# GPG-based commit signing
#######################################
setup_gpg_signing() {
  if [[ -z "$EMAIL" ]]; then
    echo "❌ Email is required for GPG mode. Use -e to specify it."
    exit 1
  fi

  echo "🔧 Installing GPG tools..."
  brew install gpg2 gnupg pinentry-mac

  echo "🔐 Generating GPG key for email: $EMAIL"
  gpg --full-generate-key

  echo "📋 Locating GPG key..."
  KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$EMAIL" | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -n 1)

  if [[ -z "$KEY_ID" ]]; then
    echo "❌ Could not find GPG key for $EMAIL"
    exit 1
  fi

  echo "✅ Found GPG key ID: $KEY_ID"

  gpg --armor --export "$KEY_ID" > "$HOME/${EMAIL}_gpgkey.asc"
  echo "📝 GPG public key exported to: $HOME/${EMAIL}_gpgkey.asc"

  echo "🛠 Configuring Git to use GPG signing..."
  git config --global user.email "$EMAIL"
  git config --global user.signingkey "$KEY_ID"
  git config --global commit.gpgsign true
  git config --global gpg.program "$(which gpg)"

  echo "🔐 --- BEGIN PUBLIC KEY ---"
  cat "$HOME/${EMAIL}_gpgkey.asc"
  echo "🔐 --- END PUBLIC KEY ---"

  echo "🌐 Please upload this key to GitHub:"
  echo "👉 https://github.com/settings/keys"
  read -p "Open GitHub in browser now? (y/n): " ans
  [[ "$ans" =~ ^[Yy]$ ]] && open https://github.com/settings/keys
}

#######################################
# Main logic
#######################################
main() {
  if [[ $GPG_MODE -eq 1 ]]; then
    setup_gpg_signing
    exit 0
  fi

  if [[ $EXPORT_ONLY -eq 1 ]]; then
    echo "📤 Export-only mode enabled: skipping SSH key generation."
  fi

  setup_ssh_signing_key

  if [[ -n "$GITHUB_TOKEN" && -n "$GITHUB_USERNAME" ]]; then
    upload_ssh_key_to_github
  fi
}

main
