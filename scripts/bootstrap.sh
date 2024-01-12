#!/bin/bash

# set -x

### Shared functions

# Renames files/folders containing template name
rename_object() {
    if [ $# -ne 1 ]; then
        echo "Function requires an argumeent: rename_object [filesystem object]"; exit 1
    else
        FS_OBJECT="$1"
    fi
    # Function take a filesystem object as a single argument
    FS_OBJECT="$1"
    OBJECT_PATH=$(dirname "$FS_OBJECT")
    OBJECT_NAME=$(basename "$FS_OBJECT")

    # Check if filesystem object contains template name
    if [[ ! "$OBJECT_NAME" == *"$TEMPLATE_NAME"* ]]; then
        # Nothing to do; abort early
        return
    fi

    NEW_NAME="${OBJECT_NAME//$TEMPLATE_NAME/$REPO_NAME}"git
    if [ -d "$FS_OBJECT" ]; then
        echo "Renaming folder:"
    elif  [ -f "$FS_OBJECT" ]; then
        echo "Renaming file:"
    elif [ -L "$FS_OBJECT" ]; then
        echo "Renaming symlink:"
    fi
    git mv "$OBJECT_PATH/$OBJECT_NAME" "$OBJECT_PATH/$NEW_NAME"
}

# Checks file content for template name and replaces matching strings
file_content_substitution() {
    if [ $# -ne 1 ]; then
        echo "Function requires an argumeent: file_content_substitution [filename]"; exit 1
    else
        FILENAME="$1"
    fi
    if (grep "$TEMPLATE_NAME" "$FILENAME" > /dev/null 2>&1); then
        MATCHES=$(grep -c "$TEMPLATE_NAME" "$FILENAME")
        if [ "$MATCHES" -eq 1 ]; then
            echo "1 content substitution required: $FILENAME"
        else
            echo "$MATCHES content substitutions required: $FILENAME"
        fi
    fi
    sed -i "s/$TEMPLATE_NAME/$REPO_NAME/g" "$FILENAME"
}

### Main script entry point

TEMPLATE_NAME=osc-python-template
if ! (git rev-parse --show-toplevel > /dev/null); then
    echo "Error: this folder is not part of a GIT repository"; exit 1
fi

REPO_DIR=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_DIR")

if [ "$TEMPLATE_NAME" == "$REPO_NAME" ]; then
    echo "Template name matches repository name"; exit 1
else
    echo "Template name: $TEMPLATE_NAME"
    echo "Repository name: $REPO_NAME"
fi

# Change to top-level of GIT repository
CURRENT_DIR=$(pwd)
if [ "$REPO_DIR" != "$CURRENT_DIR" ]; then
    echo "Changing directory to: $REPO_DIR"
    cd "$REPO_DIR" || echo "Cound not change directory!"; exit 1
fi

echo "Performing renaming/substitution operations on repository"

for FS_OBJECT in $(find -- * | xargs -0); do
    rename_object "$FS_OBJECT"
    if [ -f "$FS_OBJECT" ]; then
        file_content_substitution "$FS_OBJECT"
    fi
done
