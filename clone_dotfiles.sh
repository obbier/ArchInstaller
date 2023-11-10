#!/bin/bash

# Usage:set GH_TOKEN env variable before running. 
# https://github.com/settings/tokens
# ./clone_dotfiles.sh owner_name repo_name
# add the following to .bashrc
# alias config='/usr/bin/git --git-dir=/home/obbie/.dotfiles --work-tree=/home/obbie'
# run bash to update bashrc

# Check if repository owner and name are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <owner> <repo>"
    exit 1
fi

# Extract arguments
REPO_OWNER=$1
REPO_NAME=$2

API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME"
CLONE_URL=$(curl -s -H "Authorization: token $GH_TOKEN" "$API_URL" | grep -w "clone_url" | cut -d '"' -f 4)

# Check if the clone URL is empty
if [ -z "$CLONE_URL" ]; then
    echo "Failed to retrieve repository URL. Please check your access token and repository details."
    exit 1
fi

git clone --bare "$CLONE_URL" "$HOME/.$REPO_NAME"

echo "Repository cloned as a bare repository at $HOME/.$REPO_NAME"
