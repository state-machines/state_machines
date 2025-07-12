#!/bin/bash
# Simple shell script to update version in coss.toml

set -e

VERSION=$(grep "VERSION = " lib/state_machines/version.rb | sed "s/.*'\(.*\)'.*/\1/")

if [ -z "$VERSION" ]; then
  echo "Error: Could not extract version from lib/state_machines/version.rb"
  exit 1
fi

if [ ! -f "coss.toml" ]; then
  echo "Error: coss.toml not found"
  exit 1
fi

# Update version in coss.toml
sed -i.bak "s/^version = .*/version = \"$VERSION\"/" coss.toml
rm -f coss.toml.bak

echo "Updated coss.toml version to $VERSION"
