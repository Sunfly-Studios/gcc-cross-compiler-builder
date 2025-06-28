#!/usr/bin/env bash

# This script upgrades the already built and working cross compiler
# to a new version, allowing for not having to go through the entire
# process again.

set -e

scriptname=${0##*/}

# UI
prompt="|>"
phasestars="*********"
funcstars="${phasestars}***"

log() {
    local fmt=""
    if [ "$#" -eq 1 ]; then
        fmt="%s"
    elif [ "$#" -gt 1 ]; then
        fmt="$1"
        shift 1
    fi
    printf "%s ${fmt}\n" "|>" "$@"
}

ARCH_DIR="./arch"

if [ ! -d "$ARCH_DIR" ]; then
    echo "Architecture directory not found!"
    exit 1
fi

# Array to hold configuration files
config_files=()

echo "Available architecture configurations:"
i=1
for config_file in "$ARCH_DIR"/env-*.sh; do
    if [ -f "$config_file" ]; then
        echo "$i) $(basename "$config_file")"
        config_files[$i]="$config_file"
        ((i++))
    fi
done

if [ ${#config_files[@]} -eq 0 ]; then
    echo "No configuration files found in $ARCH_DIR"
    exit 1
fi

read -p "Enter the number of the configuration to upgrade GCC for: " selection

if [ -z "${config_files[$selection]}" ]; then
    echo "Invalid selection"
    exit 1
fi

selected_config="${config_files[$selection]}"
echo "Upgrading GCC with configuration: $(basename "$selected_config")"
read -p "Are you sure this is the configuration? (Y/y/N/n) " confirm
case $confirm in
    [Yy]) source "$selected_config" ;;
    [Nn]) exit 0;;
    *) source "$selected_config" ;;
esac

# Log stdout and stderr.
date=$(date "+%Y-%m-%d")
log_file="/tmp/${scriptname}_${date}.log"
exec > >(tee -a "$log_file")
exec 2> >(tee -a "$log_file" >&2)
log "$(date "+%Y-%m-%d-%H:%M:%S") Appending stdout & stdin to: ${log_file}"

if [ ! -d "$TOOLS" ]; then
    echo "Error: Toolchain directory $TOOLS not found!"
    echo "Please build the base toolchain first using the main script."
    exit 1
fi

if [ ! -f "$TOOLS/bin/$TARGET-gcc" ]; then
    echo "Error: $TARGET-gcc not found in $TOOLS/bin"
    echo "Please ensure the base toolchain is properly built first."
    exit 1
fi

ensure_tools_in_path()
{
    if [[ ":$PATH:" != *":$TOOLS/bin:"* ]]; then
        log "Adding $TOOLS/bin to PATH"
        export PATH="$TOOLS/bin:$PATH"
    else
        log "PATH already contains $TOOLS/bin"
    fi
}

backup_existing_gcc()
{
    BACKUP_DIR="${TOOLS}_gcc_backup_$(date +%Y%m%d)"

    # Check if backup already exists for today
    if [ -d "$BACKUP_DIR" ]; then
        log "Backup already exists at $BACKUP_DIR"
        log "Skipping backup creation"
        return 0
    fi

    log "Creating backup of existing GCC..."

    # Create a backup of only the GCC-related files to save space
    mkdir -p "$BACKUP_DIR/bin"
    mkdir -p "$BACKUP_DIR/lib"
    mkdir -p "$BACKUP_DIR/libexec"
    mkdir -p "$BACKUP_DIR/include"

    # Copy GCC binaries
    cp -a "$TOOLS/bin/$TARGET-"* "$BACKUP_DIR/bin/"
    cp -a "$TOOLS/bin/"*gcc* "$BACKUP_DIR/bin/" 2>/dev/null || true
    cp -a "$TOOLS/bin/"*g++* "$BACKUP_DIR/bin/" 2>/dev/null || true

    # Copy library files
    cp -a "$TOOLS/lib/gcc" "$BACKUP_DIR/lib/" 2>/dev/null || true

    # Copy libexec files
    cp -a "$TOOLS/libexec/gcc" "$BACKUP_DIR/libexec/" 2>/dev/null || true

    # Copy include files
    cp -a "$TOOLS/include/c++" "$BACKUP_DIR/include/" 2>/dev/null || true

    log "Backup created at $BACKUP_DIR"
}

setup_upgrade_dir()
{
    local dir="$1"
    if [ -d "$dir" ]; then
        printf "%s exists, delete it? [Y/n]: " "$dir"
        read delete
        if ([ -z "$delete" ] || [[ "$delete" = [yY] ]]); then
            rm -rf "$dir"
            mkdir -p "$dir"
        fi
    else
        mkdir -p "$dir"
    fi
    cd "$dir"
}

download_and_extract_new_gcc()
{
    read -p "Enter the new GCC version to upgrade to (e.g., 12.4.0): " NEW_GCC_VERSION
    NEW_GCCV="gcc-$NEW_GCC_VERSION"

    log "Will upgrade to $NEW_GCCV"

    mkdir -p "$SRC"
    mkdir -p "$OBJ"

    cd "$SRC"

    if [ ! -f "$NEW_GCCV.tar.gz" ]; then
        log "Downloading $NEW_GCCV.tar.gz..."
        wget ftp://gcc.gnu.org/pub/gcc/releases/$NEW_GCCV/$NEW_GCCV.tar.gz
    fi

    if [ ! -d "$NEW_GCCV" ]; then
        log "Extracting $NEW_GCCV.tar.gz..."
        tar xfk $NEW_GCCV.tar.gz
        cd $NEW_GCCV
        log "Downloading prerequisites..."
        contrib/download_prerequisites
        cd ..
    fi

    return 0
}

build_and_install_new_gcc()
{
    log "Building new GCC ($NEW_GCCV)..."
    ensure_tools_in_path

    setup_upgrade_dir "$OBJ/gcc-upgrade"

    OLD_PATH="$PATH"
    OLD_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"

    # Make sure we're using the system compiler for building
    # These variables ensure the configure script doesn't use the cross compiler for its tests
    export CC=gcc
    export CXX=g++
    export AR=ar
    export AS=as
    export LD=ld
    export RANLIB=ranlib
    export STRIP=strip

    export PATH="/usr/bin:/bin:$PATH"

    log "Configuring $NEW_GCCV for $TARGET..."
    $SRC/$NEW_GCCV/configure \
        --prefix=$TOOLS \
        --target=$TARGET \
        --build=$(gcc -dumpmachine) \
        --host=$(gcc -dumpmachine) \
        --with-sysroot=$SYSROOT \
        --enable-languages=c,c++,lto \
        --disable-multilib \
        --disable-libssp \
        --disable-libgomp \
        --disable-libmudflap \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --with-pkgversion="${USER}'s $TARGET GCC upgrade" \
        --with-ppl=no \
        --with-isl=no \
        --with-cloog=no \
        --with-libelf=no \
        $TARGET_CONFIGURE_FLAGS || return 1

    # Use appropriate make version if specified
    MAKE_CMD="make"
    if [ ! -z "$MAKEV" ]; then
        # Check if we have built a custom make instead
        # newer versions > 4.3 have issues building
        if [ -f "$TOOLS/bin/make" ]; then
            MAKE_CMD="$TOOLS/bin/make"
        fi
    fi

    log "Building with $MAKE_CMD..."
    $MAKE_CMD $PARALLEL_MAKE || return 1

    log "Installing new GCC..."
    $MAKE_CMD $PARALLEL_MAKE install || return 1

    # Restore original PATH and LD_LIBRARY_PATH
    export PATH="$OLD_PATH"
    export LD_LIBRARY_PATH="$OLD_LD_LIBRARY_PATH"

    # Create symlinks without target prefix
    cd $TOOLS/bin
    for file in $(find . -type f); do
        tool_name=$(echo $file | sed -e "s/${TARGET}-\(.*\)$/\1/")

        if [ "$file" != "$tool_name" ]; then
            ln -sf "$file" "$tool_name"
        fi
    done

    return 0
}

test_new_gcc()
{
    log "Testing the upgraded GCC..."

    test_path="/tmp/${TARGET}_test_upgrade_$$"
    setup_upgrade_dir "$test_path"

    # Create a C++ test file with C++20 features
    cat <<-EOF > hello_cpp20.cpp
	#include <iostream>
	#include <concepts>
	#include <string_view>
	#include <ranges>

	// Use a C++20 concept
	template <typename T>
	concept Printable = requires(T t) {
	    { std::cout << t } -> std::same_as<std::ostream&>;
	};

	// Function template that uses the concept
	template <Printable T>
	void print(T item) {
	    std::cout << item << std::endl;
	}

	int main() {
	    std::string_view message = "Hello, ${LINUX_ARCH} world with GCC $NEW_GCC_VERSION C++20 support!";

	    // Use a C++20 range-based for loop with init statement
	    for (int i = 0; auto c : message) {
	        if (i % 10 == 0)
	            std::cout << "| ";
	        std::cout << c;
	        i++;
	    }
	    std::cout << std::endl;

	    // Test the concept
	    print("C++20 concepts work!");

	    return 0;
	}
EOF

    log "Compiling C++20 test program..."
    PATH="$TOOLS/bin:$PATH" $TARGET-g++ -std=c++20 -Wall -o hello_cpp20 ./hello_cpp20.cpp

    log "RUN MANUALLY: Produced C++20 test binary at: $test_path/hello_cpp20"
    log "Access compiler tools: $ export PATH=\"$TOOLS/bin:\$PATH\""

    # Show GCC version
    PATH="$TOOLS/bin:$PATH" $TARGET-g++ --version

    return 0
}

# Main execution
log "Starting GCC upgrade process for $TARGET"

# Check if TOOLS and SYSROOT are set
if [ -z "$TOOLS" ] || [ -z "$SYSROOT" ]; then
    log "Error: TOOLS or SYSROOT variables not set. Please check your configuration."
    exit 1
fi

# Backup existing GCC
backup_existing_gcc

# Download and extract new GCC
download_and_extract_new_gcc

# Build and install new GCC
if ! build_and_install_new_gcc; then
    log "Error: Failed to build and install new GCC."
    log "Your original GCC has been backed up to $BACKUP_DIR"
    exit 1
fi

# Test new GCC
if ! test_new_gcc; then
    log "Error: Failed to test new GCC."
    exit 1
fi

log "GCC upgrade successful! Your GCC has been updated to $NEW_GCCV."
log "Original GCC backup location: $BACKUP_DIR"
log "You can now use your upgraded cross-compiler with C++20 support."
