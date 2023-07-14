#!/bin/zsh

# constants
orange='\033[38;5;208m'
red='\033[38;5;196m'
green='\033[38;5;46m'
reset='\033[0m'
# END constants

print_help() {
    cat <<EOF
Usage: ./build.sh <pico_sdk_release_tag> <toolchain_tag>

To build and sign set APPLE_DEVELOPER_INSTALLER_ID environment variable 
before.
For example, if you have a signing identity with the identifier 
"Developer ID Installer: Your Name (ABC123DEF)" set it in the variable.
EOF
}

# specify count of arguments expected
if [ $# -lt 2 ]; then
  print_help >&2
  exit 1
fi

verbose=false

if [ $# -eq 3 ] && { [ "$3" = "--verbose" ] || [ "$3" = "-v" ]; }; then
  verbose=true
fi

# static method helpers
echo_orange() {
    # redirect to original stdout file descriptor
    exec >&3
    echo -e "${orange}$1${reset}"
    # redirect to selected stdout file descriptor
    exec >&4
}
echo_red() {
    # redirect to original stdout file descriptor
    exec >&3
    echo -e "${red}$1${reset}" >&1
    # redirect to selected stdout file descriptor
    exec >&4
}
echo_green() {
    # redirect to original stdout file descriptor
    exec >&3
    echo -e "${green}$1${reset}" >&1
    # redirect to selected stdout file descriptor
    exec >&4
}
# END static method helpers

# was interrupted exit
int_or_err=false
int_cleanup() {
    # avoid running twice for INT and EXIT by parsing true as argument to set flag
    cleanup true
}
err_cleanup() {
    echo_red "An error occurred!\n"
    # avoid running twice for ERR and EXIT by parsing true as argument to set flag
    cleanup true
}
 
cleanup() {
    # avoid running twice for INT and EXIT
    if $int_or_err; then
        return 0
    fi
    if $1; then
        int_or_err=true
    fi

    echo_orange "Cleaning up..."

    rm -rf bundle

    # if the script fails before moving it
    rm -rf pico-sdk
    rm -rf content
    rm -rf components
    rm -rf scripts

    echo_green "Cleaned up."
}

# store the original stdout file descriptor
exec 3>&1
if $verbose; then
    exec 4>&1
else
    # redirect stdout to /dev/null (this will change &1)
    exec 4> /dev/null
fi
# redirect stdout to selected descriptor (this will change &1)
exec >&4

trap cleanup EXIT
trap int_cleanup INT
trap err_cleanup ERR
set -e

# would allow to set a different pkg version than the pico-sdk release tag
#tag_name="$1"
#pico_sdk_tag="$2"
#toolchain_tag="$3"
pico_sdk_tag="$1"
tag_name="$pico_sdk_tag"
toolchain_tag="$2"

get_toolchain_download_url() {
    # moved to Azure blob storage
    #local url="https://developer.arm.com/-/media/Files/downloads/gnu/$toolchain_tag/binrel/arm-gnu-toolchain-$toolchain_tag-darwin-$1-arm-none-eabi.pkg"
    # new url
    local url="https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu/$toolchain_tag/binrel/arm-gnu-toolchain-$toolchain_tag-darwin-arm64-arm-none-eabi.pkg"
    echo "$url"
}

# download toolchain pkgs
mkdir -p components
echo_orange "Downloading toolchain pkgs..."
curl --progress-bar -o components/arm-toolchain-arm64.pkg "$(get_toolchain_download_url arm64)"
curl --progress-bar -o components/arm-toolchain-x86_64.pkg "$(get_toolchain_download_url x86_64)"
echo_green "Toolchain pkgs downloaded.\n"

############################
# build pico sdk pkg #
############################

# download pico-sdk
echo_orange "Downloading pico-sdk v$pico_sdk_tag..."

# Store the original value of advice.detachedHead
git_original_setting=$(git config --get advice.detachedHead)
# Check if the value is empty
if [ -z "$original_setting" ]; then
  original_setting="true"  # Set a default value if empty
fi
# Set advice.detachedHead to false for the clone operation
git config advice.detachedHead "false"

if $verbose; then
    gh repo clone raspberrypi/pico-sdk pico-sdk -- --depth 1 --branch "$pico_sdk_tag"
else
    gh repo clone raspberrypi/pico-sdk pico-sdk -- --depth 1 --branch "$pico_sdk_tag" -q
fi

# download submodules
cd pico-sdk
if $verbose; then
    git submodule update --init
else
    git submodule update --init -q
fi
cd ..
# Revert advice.detachedHead to the original value
git config advice.detachedHead "$git_original_setting"

echo_green "Pico-sdk downloaded.\n"

#####################################
# dynamically fill distribution.xml #
#####################################

new_sdk_path_base="/usr/local/RaspberryPi"
new_sdk_path="$new_sdk_path_base/pico-sdk-$pico_sdk_tag"

echo_orange "Updating postinstall script with toolchain and sdk paths..."

toolchain_path_placeholder="<toolchain-path>"
toolchain_bin_path="/Applications/ArmGNUToolchain/$toolchain_tag/arm-none-eabi/bin"
sdk_version_placeholder="<sdk-version>"
sdk_path_placeholder="<sdk-path>"
mkdir -p scripts
cp -f postinstall "scripts/postinstall"

sed -i '' "s|$toolchain_path_placeholder|$toolchain_bin_path|g" "scripts/postinstall"
sed -i '' "s|$sdk_version_placeholder|$pico_sdk_tag|g" "scripts/postinstall"
sed -i '' "s|$sdk_path_placeholder|$new_sdk_path|g" "scripts/postinstall"

echo_green "Postinstall script updated.\n"

#########################################
# END dynamically fill distribution.xml #
#########################################

echo_orange "Building pico-sdk pkg..."
mkdir -p "content$new_sdk_path_base"
mv -f pico-sdk "content$new_sdk_path"

# build pico sdk pkg
if [ -n "$APPLE_DEVELOPER_INSTALLER_ID" ]; then
    pkgbuild \
    --root "content/" \
    --scripts "scripts/" \
    --identifier "org.raspberrypi.pico-sdk" \
    --version "$pico_sdk_tag" \
    --install-location "/" \
    --timestamp \
    --sign "$APPLE_DEVELOPER_INSTALLER_ID" \
    "components/org.raspberrypi.pico-sdk.pkg"

else 
    echo_red "Skipping macOS pkg code-signing. Set APPLE_DEVELOPER_INSTALLER_ID to sign." >&2

    pkgbuild \
    --root "content/" \
    --scripts "scripts/" \
    --identifier "org.raspberrypi.pico-sdk" \
    --version "$pico_sdk_tag" \
    --install-location "/" \
    "components/org.raspberrypi.pico-sdk.pkg"
fi
echo_green "Pico SDK pkg built.\n"

################################
# END build pico sdk component #
################################

echo_orange "Building final macOS universal pkg..."
mkdir -p out

if [ -n "$APPLE_DEVELOPER_INSTALLER_ID" ]; then
    productbuild \
    --distribution "distribution.xml" \
    --package-path components/ \
    --resources "resources/" \
    --version "$tag_name" \
    --identifier org.raspberrypi.pico-sdk.bundle \
    --timestamp \
    --sign "$APPLE_DEVELOPER_INSTALLER_ID" \
    "out/pico_sdk_${tag_name}_macOS_arm64.pkg"

    productbuild \
    --distribution "distribution-x86_64.xml" \
    --package-path components/ \
    --resources "resources/" \
    --version "$tag_name" \
    --identifier org.raspberrypi.pico-sdk.bundle \
    --timestamp \
    --sign "$APPLE_DEVELOPER_INSTALLER_ID" \
    "out/pico_sdk_${tag_name}_macOS_x86_64.pkg"
else
    productbuild \
    --distribution "distribution.xml" \
    --package-path components/ \
    --resources "resources/" \
    --version "$tag_name" \
    --identifier org.raspberrypi.pico-sdk.bundle \
    "out/pico_sdk_${tag_name}_macOS_arm64.pkg"

    productbuild \
    --distribution "distribution-x86_64.xml" \
    --package-path components/ \
    --resources "resources/" \
    --version "$tag_name" \
    --identifier org.raspberrypi.pico-sdk.bundle \
    "out/pico_sdk_${tag_name}_macOS_x86_64.pkg"
fi

echo_green "\r\nmacOS universal pkg built."
echo_green "Done.\n"

cleanup
