#!/bin/bash

# Simple version bump script for Home Assistant addon
# Usage: ./bump-version.sh [major|minor|patch]
# Default: patch

set -e

ADDON_DIR="screenshot-frame"
CONFIG_FILE="$ADDON_DIR/config.yaml"

# Get current version
CURRENT_VERSION=$(grep "^version:" "$CONFIG_FILE" | sed 's/version: "\(.*\)"/\1/')
echo "Current version: $CURRENT_VERSION"

# Parse version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Determine bump type (default to patch)
BUMP_TYPE="${1:-patch}"

case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Usage: $0 [major|minor|patch]"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "New version: $NEW_VERSION"

# Update config.yaml
sed -i '' "s/^version: \"$CURRENT_VERSION\"/version: \"$NEW_VERSION\"/" "$CONFIG_FILE"
echo "Updated $CONFIG_FILE"

# Create CHANGELOG entry if file exists
CHANGELOG="$ADDON_DIR/CHANGELOG.md"
if [ -f "$CHANGELOG" ]; then
  # Insert new version at the top
  {
    echo "## $NEW_VERSION"
    echo ""
    echo "- Update"
    echo ""
    cat "$CHANGELOG"
  } > "$CHANGELOG.tmp"
  mv "$CHANGELOG.tmp" "$CHANGELOG"
  echo "Updated $CHANGELOG"
fi

# Stage and commit
git add "$CONFIG_FILE" "$CHANGELOG" 2>/dev/null || true
git commit -m "Bump version to $NEW_VERSION"

echo "✓ Version bumped to $NEW_VERSION"
echo "Ready to push with: git push"
