#!/bin/bash

# Usage:set GH_TOKEN env variable before running. 
# https://github.com/settings/tokens
# ./clone_dotfiles.sh owner_name repo_name
# add the following to .bashrc
# alias config='/usr/bin/git --git-dir=/home/obbie/.dotfiles --work-tree=/home/obbie'
# run bash to update bashrc


function setup_nvidia() {
    sudo nvidia-xconfig
}

setup_nvidia

#!/bin/bash

# Check if GitHub token is set
if [ -z "$GH_TOKEN" ]; then
    echo "GitHub token not set. Please export GH_TOKEN with your GitHub token."
    exit 1
fi

# Check if repository owner and name are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <owner> <repo>"
    exit 1
fi

# Extract arguments
REPO_OWNER=$1
REPO_NAME=$2

# SSH key path
SSH_KEY_PATH="$HOME/.ssh/github_rsa"

# Check if SSH key already exists
if [ -f "$SSH_KEY_PATH" ]; then
    echo "SSH key already exists at $SSH_KEY_PATH. Aborting key generation."
else
    # Generate SSH key
    ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f "$SSH_KEY_PATH" -N ""
fi
chmod 600 ~/.ssh/github_rsa
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_rsa

# Read and encode the public key
PUB_KEY=$(cat "$SSH_KEY_PATH.pub")

# Upload the public key to GitHub
API_URL="https://api.github.com/user/keys"
UPLOAD_KEY_RES=$(curl -s -H "Authorization: token $GH_TOKEN" -X POST -d "{\"title\":\"Your Key Description\", \"key\":\"$PUB_KEY\"}" "$API_URL")

# Get the repository SSH clone URL
REPO_API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME"
SSH_URL=$(curl -s -H "Authorization: token $GH_TOKEN" "$REPO_API_URL" | jq -r '.ssh_url')

# Check if the SSH URL is empty
if [ -z "$SSH_URL" ]; then
    echo "Failed to retrieve repository SSH URL. Please check your access token and repository details."
    exit 1
fi

git clone --bare "$CLONE_URL" "$HOME/.$REPO_NAME"

echo "Repository cloned as a bare repository at $HOME/.$REPO_NAME"
