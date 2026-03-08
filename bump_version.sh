#!/bin/bash
# Updates version to today's date in main_menu_screen.dart and pubspec.yaml, bumps build number

MENU_FILE="lib/screens/main_menu_screen.dart"
PUBSPEC_FILE="pubspec.yaml"

# Generate today's date as version: month.day.2-digit-year (no leading zeros)
MONTH=$(date +%-m)
DAY=$(date +%-d)
YEAR=$(date +%y)
TODAY_VERSION="$MONTH.$DAY.$YEAR"

# Update main_menu_screen.dart
sed -i "s/Golden Oaks Golf League - [0-9]*\.[0-9]*\.[0-9]*/Golden Oaks Golf League - $TODAY_VERSION/" "$MENU_FILE"

# Extract current build number from pubspec.yaml
CURRENT_BUILD=$(grep "^version:" "$PUBSPEC_FILE" | grep -o "+[0-9]*" | tr -d '+')

if [ -z "$CURRENT_BUILD" ]; then
  CURRENT_BUILD=0
fi

# Bump build number
NEW_BUILD=$((CURRENT_BUILD + 1))

# Update pubspec.yaml
sed -i "s/^version: .*/version: $TODAY_VERSION+$NEW_BUILD/" "$PUBSPEC_FILE"

echo "Version: $TODAY_VERSION+$NEW_BUILD"
