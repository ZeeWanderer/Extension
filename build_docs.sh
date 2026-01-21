#!/bin/zsh

set -e

export DEVELOPER_DIR="$(xcode-select -p)"

echo "Using Xcode at: $DEVELOPER_DIR"

DERIVED_DATA_PATH="build"

echo "Building documentation..."  
xcodebuild docbuild -scheme Extension \
    -destination "generic/platform=iOS"\
    -skipMacroValidation \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    OTHER_DOCC_FLAGS="--enable-inherited-docs"

echo "Locating .doccarchive..."
DOCCARCHIVE_PATH="$(find "$DERIVED_DATA_PATH" -name 'Extension.doccarchive' | head -n 1)"
if [ -z "$DOCCARCHIVE_PATH" ]; then
    echo "Error: Failed to find Extension.doccarchive"
    exit 1
fi

echo ".doccarchive located at: $DOCCARCHIVE_PATH"

echo "Locating docc tool..."
DOCC_EXECUTABLE=$(xcrun --sdk iphoneos --find docc)
if [ ! -x "$DOCC_EXECUTABLE" ]; then
    echo "Error: docc tool not found"
    exit 1
fi

echo "docc tool located at: $DOCC_EXECUTABLE"

echo "Processing .doccarchive..."
"$DOCC_EXECUTABLE" process-archive transform-for-static-hosting \
    "$DOCCARCHIVE_PATH" \
    --output-path docs \
    --hosting-base-path Extension

echo "Documentation successfully built and output to 'docs' directory."
