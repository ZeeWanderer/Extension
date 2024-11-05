xcodebuild docbuild -skipMacroValidation -scheme Extension \
    -destination generic/platform=iOS \
    OTHER_DOCC_FLAGS='--transform-for-static-hosting --hosting-base-path Extension --output-path docs --include Extension'
