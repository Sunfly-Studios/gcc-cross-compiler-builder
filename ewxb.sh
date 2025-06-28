#!/usr/bin/env bash

set -e

scriptname=${0##*/}

# UI
prompt="|>"
phasestars="*********"
funcstars="${phasestars}***"

log () {
    local fmt=""
    if [ "$#"  -eq 1 ]; then
        fmt="%s"
    elif [ "$#"  -gt 1 ]; then
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

read -p "Enter the number of the configuration to build: " selection

if [ -z "${config_files[$selection]}" ]; then
    echo "Invalid selection"
    exit 1
fi

selected_config="${config_files[$selection]}"
echo "Building with configuration: $(basename "$selected_config")"
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

extract_linux_version() {
    local version=$(echo "$1" | cut -d"-" -f2)
    local major_v=$(echo $version | cut -d"." -f1)

    # Every version after 3.0 has a .x.
    if [ "$major_v" -ge 3 ]; then
        echo "$major_v.x"
    else
        echo $version | grep -oE "^[0-9]+\.[0-9]+"
    fi
}

glibc_needs_port_pkg() {
    return 1
}

setup_and_enter_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        printf "%s exists, delete it? [Y/n]: " "$dir"
        read delete
        if ([ -z "$delete" ] || [[ "$delete" = [yY] ]]); then
            rm -rf "$dir"
            mkdir "$dir"
        fi
    else
        mkdir "$dir"
    fi
    cd "$dir"
}

get_phase_description() {
    case "$1" in
        0) echo "prefix" ;;
        1) echo "binutils, texinfo and (optionally) make." ;;
        2) echo "gcc1" ;;
        3) echo "linux headers" ;;
        4) echo "glibc headers" ;;
        5) echo "gcc2" ;;
        6) echo "glibc full" ;;
        7) echo "gcc3" ;;
        8) echo "testing" ;;
        *) echo "Unknown phase" ;;
    esac
}

ensure_tools_in_path() {
    # Check if $TOOLS/bin is already in PATH
    if [[ ":$PATH:" != *":$TOOLS/bin:"* ]]; then
        log "Adding $TOOLS/bin to PATH"
        export PATH="$TOOLS/bin:$PATH"
    else
        log "PATH already contains $TOOLS/bin"
    fi
}

phase_0() {
    log "Setting up work dirs and fetching/unpacking sources."

    mkdir -p "$CWORK"
    mkdir -p "$SRC"
    rm -rf $OBJ
    rm -rf $TOOLS
    rm -rf $SYSROOT
    mkdir $OBJ
    mkdir $TOOLS
    mkdir $SYSROOT
    mkdir -p $SYSROOT/usr/include

    cd $SRC

    if ! [ -f "$BINUTILSV.tar.gz" ]; then
        log "Downloading $BINUTILSV.tar.gz..."
        wget http://ftp.gnu.org/gnu/binutils/$BINUTILSV.tar.gz
    fi

    if ! [ -f "$TEXINFOV.tar.gz" ]; then
        log "Downloading $TEXINFOV.tar.gz..."
        wget http://ftp.gnu.org/gnu/texinfo/$TEXINFOV.tar.gz
    fi
    
    if ! [ -d "$BINUTILSV" ]; then
        tar xvzf $BINUTILSV.tar.gz
    fi
    
    if ! [ -d "$TEXINFOV" ]; then
        tar xvzf $TEXINFOV.tar.gz
    fi

    # Optionally build make.
    if ! [ -z "$MAKEV" ]; then
        log "Downloading $MAKEV.tar.gz..."

        if ! [ -f "$MAKEV.tar.gz" ]; then
            log "Downloading $MAKEV.tar.gz..."
            wget http://ftp.gnu.org/gnu/make/$MAKEV.tar.gz
        fi
    
        if ! [ -d "$MAKEV" ]; then
            tar xvzf $MAKEV.tar.gz
        fi
    fi

    if [ "$GCCV"  == "gccgo" ]; then
        if ! [ -d "$GCCV" ]; then
            log "Checking out $GCCV from SVN repo..."
            svn checkout svn://gcc.gnu.org/svn/gcc/branches/gccgo gccgo
            cd $GCCV
            contrib/download_prerequisites
            cd $SRC
        fi
    else
        if ! [ -f "$GCCV.tar.gz" ]; then
            log "Downloading $GCCV.tar.gz..."
            wget ftp://gcc.gnu.org/pub/gcc/releases/$GCCV/$GCCV.tar.gz
        fi
        if ! [ -d "$GCCV" ]; then
            tar xfk $GCCV.tar.gz
            cd $GCCV
            contrib/download_prerequisites
            cd $SRC
        fi
    fi

    if ! [ -f "$GLIBCV.tar.bz2" ]; then
        log "Downloading $GLIBCV.tar.bz2..."
        wget http://ftp.gnu.org/gnu/glibc/$GLIBCV.tar.bz2
    fi

    if ! [ -d "$GLIBCV" ]; then
        tar xfk $GLIBCV.tar.bz2
    fi

    if glibc_needs_port_pkg; then
        cd $GLIBCV
        glibcport="glibc-ports-2.11"
        if ! [ -f "$glibcport.tar.bz2" ]; then
            log "Fetching ports extension $glibcport.tar.bz2"
            wget http://ftp.gnu.org/gnu/glibc/$glibcport.tar.bz2
        fi
        if ! [ -d "$glibcport" ]; then
            tar xfk $glibcport.tar.bz2
            ln -s $glibcport ports
        fi
        cd ..
    fi

    if ! [ -f "$LINUXV.tar.gz" ]; then
        log "Downloading $LINUXV.tar.gz..."
        version=$(extract_linux_version $LINUXV)

        wget https://www.kernel.org/pub/linux/kernel/v$version/$LINUXV.tar.gz
    fi

    if ! [ -d "$LINUXV" ]; then
        tar xvzf $LINUXV.tar.gz
    fi
    return 0
}

phase_1() {
    log "Building texinfo, (optionally) make and cross-compiling binutils."

    if ! [ -z "$MAKEV" ]; then
        setup_and_enter_dir "$OBJ/make"

        $SRC/$MAKEV/configure \
            --prefix=$TOOLS \
            --build=$MACHTYPE \
            --host=$TARGET || return 1
        
        # Make sure to fail if something did go wrong.
        make $PARALLEL_MAKE || return 1
        make install || return 1
    fi

    ensure_tools_in_path
    setup_and_enter_dir "$OBJ/texinfo"
    
    $SRC/$TEXINFOV/configure \
        --prefix=$TOOLS \
        --build=$MACHTYPE \
        --host=$TARGET || return 1
    make $PARALLEL_MAKE || return 1
    make install || return 1
    
    setup_and_enter_dir "$OBJ/binutils"

    $SRC/$BINUTILSV/configure \
        --prefix=$TOOLS \
        --target=$TARGET \
        --with-sysroot=$SYSROOT \
        --enable-plugins \
        --enable-shared \
        --enable-lto || return 1

    make $PARALLEL_MAKE || return 1
    make $PARALLEL_MAKE install || return 1
    return 0
}

phase_2() {
    log "Building barebone cross GCC so glibc headers can be compiled."

    ensure_tools_in_path
    setup_and_enter_dir "$OBJ/gcc1"

    $SRC/$GCCV/configure \
        --prefix=$TOOLS \
        --build=$BUILD \
        --host=$HOST \
        --target=$TARGET \
        --enable-languages=c \
        --without-headers \
        --with-newlib \
        --with-pkgversion="${USER}'s $TARGET GCC phase1 cross-compiler" \
        --disable-libgcc \
        --disable-shared \
        --disable-threads \
        --disable-multilib \
        --disable-libssp \
        --disable-libgomp \
        --disable-libmudflap \
        --disable-libquadmath \
        $TARGET_CONFIGURE_FLAGS || return 1

    PATH="$TOOLS/bin:$PATH" make $PARALLEL_MAKE all-gcc || return 1
    PATH="$TOOLS/bin:$PATH" make $PARALLEL_MAKE install-gcc || return 1
    return 0
}

phase_3() {
    log "Compiling and installing Linux header files."
    ensure_tools_in_path
    rm -rf $OBJ/$LINUXV
    cp -r $SRC/$LINUXV $OBJ # Make modifies the tree; make copy.
    cd $OBJ/$LINUXV

    make clean
    make mrproper
    make $PARALLEL_MAKE headers_install \
        ARCH=$LINUX_ARCH \
        CROSS_COMPILE=$TARGET \
        INSTALL_HDR_PATH=$SYSROOT/usr || return 1
    return 0
}

phase_4() {
    log "Install header files and bootstrap libc with friends."
    ensure_tools_in_path

    setup_and_enter_dir "$OBJ/glibc-headers"

    LD_LIBRARY_PATH_old="$LD_LIBRARY_PATH"
    unset LD_LIBRARY_PATH

    local addons=""
    if glibc_needs_port_pkg; then
        addons="--enable-add-ons=nptl,ports"
    fi
    
    local linux_version=""
    if [ -n "$LINUXMIN" ]; then
        linux_version="$LINUXMIN"
    else
        linux_version=$(echo "$LINUXV" | sed -e 's/.*-//')
    fi
    
    if [[ $TARGET == "loongarch64-linux-gnu" ]]; then
        # Loongarch64 requires specific ABI settings
        extra_config_opts="--enable-stack-protector=strong --with-fp-cond=64"
        
        BUILD_CC=gcc \
        CC=$TOOLS/bin/$TARGET-gcc \
        CXX=$TOOLS/bin/$TARGET-g++ \
        AR=$TOOLS/bin/$TARGET-ar \
        RANLIB=$TOOLS/bin/$TARGET-ranlib \
        $SRC/$GLIBCV/configure \
            --prefix=/usr \
            --build=$BUILD \
            --host=$TARGET \
            --with-headers=$SYSROOT/usr/include \
            --disable-werror \
            --with-binutils=$TOOLS/$TARGET/bin \
            $addons \
            --enable-kernel="$linux_version" \
            --disable-profile \
            --without-gd \
            --without-cvs \
            --with-tls \
            $extra_config_opts \
            libc_cv_forced_unwind=yes || return 1
    else
        BUILD_CC=gcc \
        CC=$TOOLS/bin/$TARGET-gcc \
        CXX=$TOOLS/bin/$TARGET-g++ \
        AR=$TOOLS/bin/$TARGET-ar \
        RANLIB=$TOOLS/bin/$TARGET-ranlib \
        $SRC/$GLIBCV/configure \
            --prefix=/usr \
            --build=$BUILD \
            --host=$TARGET \
            --with-headers=$SYSROOT/usr/include \
            --disable-werror \
            --with-binutils=$TOOLS/$TARGET/bin \
            $addons \
            --enable-kernel="$linux_version" \
            --disable-profile \
            --without-gd \
            --without-cvs \
            --with-tls \
            libc_cv_ctors_header=yes \
            libc_cv_gcc_builtin_expect=yes \
            libc_cv_mips_tls=yes \
            libc_cv_forced_unwind=yes \
            libc_cv_c_cleanup=yes || return 1
    fi
    
    make $PARALLEL_MAKE install-headers install-bootstrap-headers=yes install_root=$SYSROOT || return 1

    mkdir -p $SYSROOT/usr/lib
    make $PARALLEL_MAKE csu/subdir_lib || return 1
    cp csu/crt1.o csu/crti.o csu/crtn.o $SYSROOT/usr/lib || return 1

    if [ "$GLIBCVNO" == "2.15" ]; then # At least 2.19 does this with install-headers target it self.
        cp bits/stdio_lim.h $SYSROOT/usr/include/bits
    fi

    $TOOLS/bin/$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $SYSROOT/usr/lib/libc.so

    touch $SYSROOT/usr/include/gnu/stubs.h

    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH_old"
    return 0
}

phase_5() {
    log "Build bootstrapped gcc that can compile a full glibc."
    ensure_tools_in_path

    setup_and_enter_dir "$OBJ/gcc2"
    $SRC/$GCCV/configure \
        --prefix=$TOOLS \
        --target=$TARGET \
        --build=$BUILD \
        --host=$HOST \
        --with-sysroot=$SYSROOT \
        --with-pkgversion="${USER}'s $TARGET GCC phase2 cross-compiler" \
        --enable-languages=c \
        --disable-libssp \
        --disable-libgomp \
        --disable-libmudflap \
        --disable-multilib \
        --with-ppl=no \
        --with-isl=no \
        --with-cloog=no \
        --with-libelf=no \
        --disable-nls \
        --disable-multilib \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --disable-libatomic \
        $TARGET_CONFIGURE_FLAGS || return 1

    if [[ $TARGET == "loongarch64-linux-gnu" || $TARGET == "mips64el-linux-gnu" || $TARGET == "mipsel-linux-gnu" || $TARGET == "mips64-linux-gnu" ]]; then
        # For some reason, GCC is looking at its own directories when
        # trying to find these files....
        mkdir -p $TOOLS/$TARGET/lib
        if [ ! -e $TOOLS/$TARGET/lib/crti.o ]; then
            ln -sf $SYSROOT/usr/lib/crti.o $TOOLS/$TARGET/lib/crti.o
        fi
        if [ ! -e $TOOLS/$TARGET/lib/crtn.o ]; then
            ln -sf $SYSROOT/usr/lib/crtn.o $TOOLS/$TARGET/lib/crtn.o
        fi
    fi
    PATH="$TOOLS/bin:$PATH" make $PARALLEL_MAKE || return 1
    PATH="$TOOLS/bin:$PATH" make $PARALLEL_MAKE install || return 1
    return 0
}

phase_6() {
    log "Building a full glibc for $TARGET."
    ensure_tools_in_path

    setup_and_enter_dir "$OBJ/glibc"

    LD_LIBRARY_PATH_old="$LD_LIBRARY_PATH"
    unset LD_LIBRARY_PATH

    local addons=""
    
    if glibc_needs_port_pkg; then
        addons="--enable-add-ons=nptl,ports"
    fi

    local extra_lib_cv=""
    if [ "$GLIBCVNO" == "2.15" ]; then # The one I've noticed, 2.19 does not need for example.
        extra_lib_cv="libc_cv_ctors_header=yes libc_cv_c_cleanup=yes"
    fi
    
    local linux_version=""
    if [ -n "$LINUXMIN" ]; then
        linux_version="$LINUXMIN"
    else
        linux_version=$(echo "$LINUXV" | sed -e 's/.*-//')
    fi

    if [[ $TARGET == "loongarch64-linux-gnu" ]]; then
        # Loongarch64 requires specific ABI settings
        extra_config_opts="--enable-stack-protector=strong --with-fp-cond=64"
        
        BUILD_CC=gcc \
        CC=$TOOLS/bin/$TARGET-gcc \
        CXX=$TOOLS/bin/$TARGET-g++ \
        AR=$TOOLS/bin/$TARGET-ar \
        RANLIB=$TOOLS/bin/$TARGET-ranlib \
        $SRC/$GLIBCV/configure \
            --prefix=/usr \
            --build=$BUILD \
            --host=$TARGET \
            --with-headers=$SYSROOT/usr/include \
            --disable-werror \
            --with-binutils=$TOOLS/$TARGET/bin \
            $addons \
            --enable-kernel="$linux_version" \
            --disable-profile \
            --without-gd \
            --without-cvs \
            --with-tls \
            $extra_config_opts \
            libc_cv_forced_unwind=yes || return 1
    else
        BUILD_CC=gcc \
        CC=$TOOLS/bin/$TARGET-gcc \
        CXX=$TOOLS/bin/$TARGET-g++ \
        AR=$TOOLS/bin/$TARGET-ar \
        RANLIB=$TOOLS/bin/$TARGET-ranlib \
        $SRC/$GLIBCV/configure \
            --prefix=/usr \
            --build=$BUILD \
            --host=$TARGET \
            --disable-profile \
            --without-gd \
            --without-cvs \
            --disable-werror \
            --with-binutils=$TOOLS/$TARGET/bin \
            $addons \
            --enable-kernel="$linux_version" \
            libc_cv_forced_unwind=yes \
            $extra_lib_cv || return 1
    fi

    PATH="$TOOLS/bin:$PATH" make $PARALLEL_MAKE || return 1
    PATH="$TOOLS/bin:$PATH" make $PARALLEL_MAKE install install_root=$SYSROOT || return 1

    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH_old"
    return 0
}

phase_7() {
    log "Building the full GCC."
    ensure_tools_in_path

    setup_and_enter_dir "$OBJ/gcc3"
    $SRC/$GCCV/configure \
        --prefix=$TOOLS \
        --target=$TARGET \
        --build=$BUILD \
        --host=$HOST \
        --with-sysroot=$SYSROOT \
        --enable-languages=c,c++,lto \
        --disable-multilib \
        --disable-libssp \
        --disable-libgomp \
        --disable-libmudflap \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --with-pkgversion="${USER}'s $TARGET GCC phase3 cross-compiler" \
        --with-ppl=no \
        --with-isl=no \
        --with-cloog=no \
        --with-libelf=no \
        $TARGET_CONFIGURE_FLAGS || return 1

    PATH="$TOOLS/bin:$PATH" make $PARALLEL_MAKE || return 1
    PATH="$TOOLS/bin:$PATH" make $PARALLEL_MAKE install || return 1
    
    cd $TOOLS/bin
    for file in $(find . -type f); do
        tool_name=$(echo $file | sed -e "s/${TARGET}-\(.*\)$/\1/")
        
        if [ "$file" != "$tool_name" ]; then
            ln -sf "$file" "$tool_name"
        fi
    done
    return 0
}

phase_8() {
    log "Testing to compile a C program."

    test_path="/tmp/${TARGET}_test_$$"
    setup_and_enter_dir "$test_path"

    cat <<-EOF > helloc.c
	#include <stdlib.h>
	#include <stdio.h>

	int main(int argc, const char *argv[])
	{
	    printf("%s\n", "Hello, ${LINUX_ARCH} world!");
	    return EXIT_SUCCESS;
	}
EOF

    PATH="$TOOLS/bin:$PATH" $TARGET-gcc -Wall -static -o helloc ./helloc.c
    log "RUN MANUALLY: Produced test-binary at: $test_path/helloc"
    log "Access compiler tools: $ export PATH=\"$TOOLS/bin:\$PATH\""
    log "Removing obj files"
    rm -rf $OBJ
    return 0
}

list_phases() {
    echo "Available phases:"
    for phase_no in $(seq 0 8); do
        printf "\t%d => %s\n" "$phase_no" "$(get_phase_description $phase_no)"
    done
}

help_text="Erik Westrup's GCC cross-compiler builder

Usage: ${scriptname} -p phases | -l | (-h | -?)
    -p phases   The phases to run. Supported formats:
                1) 2    => run phase 3
                2) 4-   => run phase 4 to last (inclusive). \"0-\" => full build
                e) 1-5  => run phases 1 to 5 (inclusive)
    -l          List available phases.
    -h, -?      This help text."

phase_first=0
phase_last=8
phase_start="$phase_first"
phase_stop="$phase_last"

validate_phase() {
    local phase="$1"
    if ! ([ "$phase" -ge "$phase_first" ] && [ "$phase"  -le "$phase_last" ]); then
        printf "Invalid phase %d\n" "$phase"
        exit 2
    fi
}

parse_cmdline() {
    if [ "$#" -eq 0 ]; then
        echo "$help_text"
        exit 1
    fi
    while getopts "p:lh?" opt; do
        case "$opt" in
            p)
                if [[ $OPTARG =~ ^[[:digit:]]+$ ]]; then
                    phase_start="$OPTARG"
                    validate_phase "$phase_start"
                    phase_stop="$phase_start"
                elif [[ $OPTARG =~ ^[[:digit:]]+-$ ]]; then
                    phase_start="${OPTARG%-}"
                    validate_phase "$phase_start"
                    phase_stop="$phase_last"
                elif [[ $OPTARG =~ ^[[:digit:]]+-[[:digit:]]+$ ]]; then
                    IFS='-' read -a parts <<< "$OPTARG"
                    phase_start=${parts[0]}
                    phase_stop=${parts[1]}
                    validate_phase "$phase_start"
                    validate_phase "$phase_stop"
                    if [ "$phase_start" -gt "$phase_stop" ]; then
                        printf "invalid relation: %d <!= %d\n" "$phase_start" "$phase_stop"
                        exit 4
                    fi
                else
                    echo "Bogus range." 1>&2
                    exit 3
                fi
                ;;
            l) list_phases; exit 0;;
            :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
            h|?|*) echo "$help_text"; exit 0;;
        esac
    done
    shift $(($OPTIND - 1))
}

parse_cmdline "$@"
for (( phase="$phase_start"; phase <= "$phase_stop"; phase++ )); do
    log "$funcstars Starting phase $phase"
    log "$phasestars $(get_phase_description "$phase")"
    # Add a pause so that we can easily see the
    # phase completed and phase to go next.
    read -p "" -n1 -s
    if ! eval "phase_$phase"; then
        log "Error occurred in phase $phase"
        exit 1
    fi
    log "$phasestars $(get_phase_description "$phase")"
    log "$funcstars Completed phase $phase"
done
