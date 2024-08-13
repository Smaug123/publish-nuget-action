#!/bin/bash

# Expects an env var NUGET_API_KEY.

NUGET_SOURCE="https://api.nuget.org/v3/index.json"
cd "$PACKAGE_DIR" || exit 1
SOURCE_NUPKG=$(find . -maxdepth 1 -type f -name '*.nupkg')

PACKAGE_VERSION=$(basename "$SOURCE_NUPKG" | rev | cut -d '.' -f 2-4 | rev)

echo "version=$PACKAGE_VERSION" >> "$GITHUB_OUTPUT"

tmp=$(mktemp)

if ! "$DOTNET_EXE" nuget push "$SOURCE_NUPKG" --api-key "$NUGET_API_KEY" --source "$NUGET_SOURCE" > "$tmp" ; then
    cat "$tmp"
    if grep 'already exists and cannot be modified' "$tmp" ; then
        echo "result=skipped" >> "$GITHUB_OUTPUT"
        exit 0
    else
        echo "Unexpected failure to upload"
        exit 1
    fi
fi

cat "$tmp"

echo "result=published" >> "$GITHUB_OUTPUT"
