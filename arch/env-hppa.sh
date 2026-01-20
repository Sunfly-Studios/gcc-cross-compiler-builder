# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="hppa-linux-gnu"

# Linux kernel source folder is 'parisc', not 'hppa'
export LINUX_ARCH="parisc"

export TARGET_CFLAGS="-march=2.0"
export TARGET_CONFIGURE_FLAGS="--with-arch=2.0"

# Work directories
export CWORK="$HOME/sysroot/${TARGET}"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"
export HEADER_DIR="${CWORK}/${TARGET}"

# Pkg versions
export BINUTILSV=binutils-2.31.1
export GCCV=gcc-9.5.0
export GLIBCV=glibc-2.24
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-4.19
export LINUXMIN=2.6.9
export MAKEV=make-4.3
export TEXINFOV=texinfo-6.8
export PARALLEL_MAKE="-j8"
