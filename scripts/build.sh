#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
if [[ -z "${DEVELOPER_DIR:-}" && "$(xcode-select -p)" == /Library/Developer/CommandLineTools && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
mkdir -p build
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/lkk-ime.XXXXXX")
ditto upstream "$STAGE/upstream"
SRC="$STAGE/upstream"
PRODUCTS="$STAGE/build/Release64"
FLAGS=(-project "$SRC/Takao.xcodeproj" -configuration Release64 -sdk macosx ARCHS=arm64 ONLY_ACTIVE_ARCH=YES MACOSX_DEPLOYMENT_TARGET=26.0 CODE_SIGNING_ALLOWED=NO CLANG_CXX_LANGUAGE_STANDARD=c++11 GCC_PRECOMPILE_PREFIX_HEADER=NO GCC_PREFIX_HEADER= DEBUG_INFORMATION_FORMAT=dwarf "SYMROOT=$STAGE/build" "OBJROOT=$STAGE/build/Intermediates" 'OTHER_CPLUSPLUSFLAGS=$(inherited) -include unistd.h -UOVIMSMARTMANDARIN_USE_SQLITE_CRYPTO -UOVLOADER_USE_SQLITE_CRYPTO -USQLITE_HAS_CODEC')
xcodebuild "${FLAGS[@]}" -target 'OpenVanilla (Library)' -target 'Formosa (Library)' build > build/build.log 2>&1 || { tail -100 build/build.log; exit 1; }
xcrun clang++ -arch arm64 -std=c++11 -Wno-parentheses -I"$SRC/Frameworks/Formosa/Headers" "$SRC/Distributions/Takao/DatabaseCooker/EncodeStandardLayout.cpp" "$PRODUCTS/libFormosa.a" "$PRODUCTS/libOpenVanilla.a" -o build/encode-readings
python3 scripts/fetch-data.py
python3 scripts/build-model.py
(cd data/opencc && shasum -a 256 -c SHA256SUMS)
COOKER="$SRC/Distributions/Takao/DatabaseCooker"
mkdir -p "$SRC/Distributions/Takao/CookedDatabase"
python3 "$COOKER/BuildPortDatabase.py" build/model.db "$SRC/Distributions/Takao/CookedDatabase/KeyKey.db" "$ROOT/build/encode-readings"
python3 "$COOKER/BuildPhraseConversion.py" "$ROOT/data/opencc" "$SRC/ModulePackages/OVAFPhraseConverter/Phrases.cin" "$SRC/ModulePackages/OVOFHanConvert"
xcodebuild "${FLAGS[@]}" -target 'Takao (Loader OSX-IMK)' build >> build/build.log 2>&1 || { tail -100 build/build.log; exit 1; }
APP="$PRODUCTS/LKK.app"
xcrun clang++ -arch arm64 -std=c++11 -Wno-parentheses -include unistd.h -F"$PRODUCTS" -I"$SRC/Frameworks/Formosa/Headers" -I"$SRC/Frameworks/Manjusri/Headers" -I"$SRC/ModulePackages/OVIMMandarin" -I"$SRC/ModulePackages/OVIMGeneric" "$SRC/Tests/PortBehavior.cpp" "$PRODUCTS/libTakaoModulePackages.a" "$PRODUCTS/libPlainVanilla.a" "$PRODUCTS/libOpenVanilla.a" "$PRODUCTS/libKeyring.a" -framework Foundation -lsqlite3 -lz -o build/port-behavior-test
TEST_DIR=$(mktemp -d "$STAGE/test.XXXXXX")
cp "$SRC/Distributions/Takao/CookedDatabase/KeyKey.db" "$TEST_DIR/model.db"
build/port-behavior-test "$TEST_DIR/model.db" "$TEST_DIR"
mkdir -p "$APP/Contents/Resources/Licenses"
cp LICENSE "$APP/Contents/Resources/"
cp docs/THIRD-PARTY-NOTICES.md "$APP/Contents/Resources/"
cp Licenses/* "$APP/Contents/Resources/Licenses/"
cp "$SRC/COPYING" "$APP/Contents/Resources/Licenses/UPSTREAM-COPYING.txt"
# Do not distribute workspace-specific Dropbox metadata.
while IFS= read -r -d '' entry; do
  if xattr "$entry" | grep -qx 'com.dropbox.attrs'; then
    xattr -d com.dropbox.attrs "$entry"
  fi
done < <(find "$APP" -print0)
# Sign from inner bundles to the app. Ad-hoc signatures are for development.
while IFS= read -r -d '' child; do
  codesign --force --sign - "$child"
done < <(find "$APP/Contents" -depth -type d \( -name '*.app' -o -name '*.bundle' -o -name '*.framework' \) -print0)
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
file "$APP/Contents/MacOS/LKK"
mkdir -p build/artifacts
ARTIFACT="build/artifacts/LKK-IME-arm64.zip"
ditto --norsrc --noextattr -c -k --keepParent "$APP" "$ARTIFACT"
(cd build/artifacts && shasum -a 256 LKK-IME-arm64.zip > LKK-IME-arm64.zip.sha256)
COPYFILE_DISABLE=1 pkgbuild --component "$APP" --install-location '/Library/Input Methods' --identifier io.github.wing.lkkime.pkg --version 0.1.0 build/artifacts/LKK-IME-arm64.pkg
(cd build/artifacts && shasum -a 256 LKK-IME-arm64.pkg > LKK-IME-arm64.pkg.sha256)
printf 'Development archive: %s\nBuild workspace: %s\n' "$ARTIFACT" "$STAGE"
