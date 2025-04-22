# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="loongarch64-linux-gnu"
export LINUX_ARCH="loongarch"

# Work directories
export CWORK="$HOME/sysroot/${TARGET}_gcc_build"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"
export HEADER_DIR="${CWORK}/${TARGET}"

# Pkg versions
export BINUTILSV=binutils-2.39
export GCCV=gcc-12.2.0
export GLIBCV=glibc-2.36
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-5.19
export TEXINFOV=texinfo-6.8

# Make version
export MAKEV=""

export PARALLEL_MAKE="-j4"
