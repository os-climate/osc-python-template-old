#!/bin/bash

# set -x
set -eu -o pipefail

### Shared functions


### Main script entry point

DEVOPS_REPO="https://github.com/os-climate/devops-toolkit.git"
REPO_DIR=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_DIR")

echo "Cloning DevOps repository into /tmp"
DEVOPS_DIR=$(mktemp -d -t devops-XXXXXXXX)
git clone https://github.com/os-climate/devops-toolkit.git "$DEVOPS_DIR"

# Change to top-level of GIT repository
CURRENT_DIR=$(pwd)
if [ "$REPO_DIR" != "$CURRENT_DIR" ]; then
    echo "Changing directory to: $REPO_DIR"
    if ! (cd "$REPO_DIR"); then
        echo "Error: unable to change directory"; exit 1
    fi
fi

echo "Extracting shell code from bootstrap.yaml file..."

EXTRACT="false"
while read -r LINE
do
    if [ "$LINE" = "### SHELL CODE START ###" ]; then
        EXTRACT="true"
        SHELL_SCRIPT=$(mktemp -t script-XXXXXXXX.sh)
        touch "$SHELL_SCRIPT"
        chmod a+x "$SHELL_SCRIPT"
        echo "Creating shell script: $SHELL_SCRIPT"
        echo "#!/bin/sh" > "$SHELL_SCRIPT"
    fi
    if [ "$EXTRACT" = "true" ]; then
        echo "$LINE" >> "$SHELL_SCRIPT"
        if [ "$LINE" = "### SHELL CODE END ###" ]; then
            echo "Successfully extracted shell script from bootstrap.yaml"
            break
        fi
    fi
done < "$DEVOPS_DIR"/.github/workflows/bootstrap.yaml


### Tidy up afterwards

echo "Cleaning up..."
if [ -d "$DEVOPS_DIR" ] && [ ! -z "$DEVOPS_DIR" ]; then
    rm -Rf "$DEVOPS_DIR"
fi
if [ -f "$SHELL_SCRIPT" ]; then
    echo "Deleting shell script code: $SHELL_SCRIPT"
    # rm "$SHELL_SCRIPT"
fi
