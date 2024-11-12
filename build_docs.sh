#!/bin/zsh

set -e  # Exit immediately if a command exits with a non-zero status

# Step 1: Get the DEVELOPER_DIR from xcode-select
export DEVELOPER_DIR="$(xcode-select -p)"

echo "Using Xcode at: $DEVELOPER_DIR"

# Step 3: Specify a known Derived Data path
DERIVED_DATA_PATH="build"

# Step 4: Build documentation using xcodebuild with the xcconfig file
echo "Building documentation..."
xcodebuild docbuild -scheme Extension \
    -destination 'generic/platform=iOS' \
    -skipMacroValidation \
    -derivedDataPath "$DERIVED_DATA_PATH"

# Step 5: Find the .doccarchive for your module
echo "Locating .doccarchive..."
DOCCARCHIVE_PATH="$(find "$DERIVED_DATA_PATH" -name 'Extension.doccarchive' | head -n 1)"
if [ -z "$DOCCARCHIVE_PATH" ]; then
    echo "Error: Failed to find Extension.doccarchive"
    exit 1
fi

# Step 6: Use xcrun to get the path to docc
echo "Locating docc tool..."
DOCC_EXECUTABLE=$(xcrun --sdk iphoneos --find docc)
if [ ! -x "$DOCC_EXECUTABLE" ]; then
    echo "Error: docc tool not found"
    exit 1
fi

# Step 7: Process the .doccarchive
echo "Processing .doccarchive..."
"$DOCC_EXECUTABLE" process-archive transform-for-static-hosting \
    "$DOCCARCHIVE_PATH" \
    --output-path docs \
    --hosting-base-path Extension

# Step 8: Clean up the temporary .xcconfig file
echo "Cleaning up..."
rm temp.xcconfig

echo "Documentation successfully built and output to 'docs' directory."
