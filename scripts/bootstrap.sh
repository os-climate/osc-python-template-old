#!/bin/bash

# set -x
set -eu -o pipefail

### Shared functions


### Main script entry point

DEVOPS_REPO="git@github.com:os-climate/devops-toolkit.git"

GIT_CMD=$(which git)
if [ ! -x "$GIT_CMD" ]; then
    echo "GIT command was not found in PATH"; exit 1
fi

REPO_DIR=$(git rev-parse --show-toplevel)
# Change to top-level of GIT repository
CURRENT_DIR=$(pwd)
if [ "$REPO_DIR" != "$CURRENT_DIR" ]; then
    echo "Changing directory to: $REPO_DIR"
    if ! (cd "$REPO_DIR"); then
        echo "Error: unable to change directory"; exit 1
    fi
fi

# Directory used below MUST match code in bootstrap.yaml
DEVOPS_DIR=".devops"
echo "Cloning DevOps repository into: $DEVOPS_DIR"
git clone "$DEVOPS_REPO" "$DEVOPS_DIR"

echo "Extracting shell code from bootstrap.yaml file..."

EXTRACT="false"
while read -r LINE; do
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

echo "Running extracted shell script code"
set +eu +o pipefail
set -x
"$SHELL_SCRIPT"

### Tidy up afterwards

echo "Cleaning up..."
if [ -d "$DEVOPS_DIR" ] && [ -n "$DEVOPS_DIR" ]; then
    rm -Rf "$DEVOPS_DIR"
fi
if [ -f "$SHELL_SCRIPT" ]; then
    echo "Shell code temporarily left in place during testing"
    # echo "Deleting shell script code: $SHELL_SCRIPT"
    # rm "$SHELL_SCRIPT"
fi
