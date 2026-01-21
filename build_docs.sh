#!/bin/zsh

set -e

export DEVELOPER_DIR="$(xcode-select -p)"

echo "Using Xcode at: $DEVELOPER_DIR"

DERIVED_DATA_PATH="build"
DOCS_OUTPUT_PATH="docs"
PRODUCTS_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphoneos"
MERGED_ARCHIVE_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphoneos/Extension.merged.doccarchive"

echo "Building documentation..."  
xcodebuild docbuild -scheme Extension \
    -destination "generic/platform=iOS"\
    -skipMacroValidation \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    OTHER_DOCC_FLAGS="--enable-inherited-docs"

echo "Locating docc tool..."
DOCC_EXECUTABLE=$(xcrun --sdk iphoneos --find docc)
if [ ! -x "$DOCC_EXECUTABLE" ]; then
    echo "Error: docc tool not found"
    exit 1
fi

echo "docc tool located at: $DOCC_EXECUTABLE"

echo "Merging module archives..."
MODULE_ARCHIVES=(
    "$PRODUCTS_PATH/SwiftExtension.doccarchive"
    "$PRODUCTS_PATH/FoundationExtension.doccarchive"
    "$PRODUCTS_PATH/CoreGraphicsExtension.doccarchive"
    "$PRODUCTS_PATH/UIKitExtension.doccarchive"
    "$PRODUCTS_PATH/SpriteKitExtension.doccarchive"
    "$PRODUCTS_PATH/SwiftUIExtension.doccarchive"
    "$PRODUCTS_PATH/ObservationExtension.doccarchive"
    "$PRODUCTS_PATH/osExtension.doccarchive"
    "$PRODUCTS_PATH/AccelerateExtension.doccarchive"
    "$PRODUCTS_PATH/GeneralExtensions.doccarchive"
    "$PRODUCTS_PATH/MacrosExtension.doccarchive"
)

EXISTING_ARCHIVES=()
for archive in "${MODULE_ARCHIVES[@]}"; do
    if [ -d "$archive" ]; then
        EXISTING_ARCHIVES+=("$archive")
    else
        echo "Warning: Missing archive at $archive"
    fi
done

if [ "${#EXISTING_ARCHIVES[@]}" -eq 0 ]; then
    echo "Error: No DocC archives found to merge."
    exit 1
fi

rm -rf "$MERGED_ARCHIVE_PATH"
"$DOCC_EXECUTABLE" merge "${EXISTING_ARCHIVES[@]}" \
    --output-path "$MERGED_ARCHIVE_PATH" \
    --synthesized-landing-page-name "Extension" \
    --synthesized-landing-page-kind "Package" \
    --synthesized-landing-page-topics-style detailedGrid

echo "Processing merged archive for static hosting..."
rm -rf "$DOCS_OUTPUT_PATH"
"$DOCC_EXECUTABLE" process-archive transform-for-static-hosting \
    "$MERGED_ARCHIVE_PATH" \
    --output-path "$DOCS_OUTPUT_PATH" \
    --hosting-base-path Extension

echo "Documentation successfully built and output to '$DOCS_OUTPUT_PATH' directory."
