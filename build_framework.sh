
# A shell script for creating an XCFramework for iOS.
# configuration: Release (default), Beta, QA, or Prod

# Get configuration from argument, default to Release
CONFIGURATION="${1:-Release}"

echo "🔨 Building AdgeistAdvertiserSDK XCFramework with configuration: $CONFIGURATION"

# Starting from a clean slate
# Removing the build and output folders
rm -rf ./build &&\
rm -rf ./output &&\

# Cleaning the workspace cache
xcodebuild \
    clean \
    -workspace native-ios-advertiser-sdk.xcworkspace \
    -scheme AdgeistAdvertiserSDK

# Create an archive for iOS devices
xcodebuild \
    archive \
        ONLY_ACTIVE_ARCH=NO \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        -workspace native-ios-advertiser-sdk.xcworkspace \
        -scheme AdgeistAdvertiserSDK \
        -configuration "$CONFIGURATION" \
        -destination "generic/platform=iOS" \
        -archivePath build/AdgeistAdvertiserSDK-iOS.xcarchive \
         -sdk iphoneos

# Create an archive for iOS simulators
xcodebuild \
    archive \
        ONLY_ACTIVE_ARCH=NO \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        -workspace native-ios-advertiser-sdk.xcworkspace \
        -scheme AdgeistAdvertiserSDK \
        -configuration "$CONFIGURATION" \
        -destination "generic/platform=iOS Simulator" \
        -archivePath build/AdgeistAdvertiserSDK-iOS_Simulator.xcarchive \
        -sdk iphonesimulator

# Convert the archives to .framework
# and package them both into one xcframework
xcodebuild \
    -create-xcframework \
    -framework build/AdgeistAdvertiserSDK-iOS.xcarchive/Products/Library/Frameworks/AdgeistAdvertiserSDK.framework \
    -framework build/AdgeistAdvertiserSDK-iOS_Simulator.xcarchive/Products/Library/Frameworks/AdgeistAdvertiserSDK.framework \
    -output output/AdgeistAdvertiserSDK.xcframework &&\
    rm -rf build
