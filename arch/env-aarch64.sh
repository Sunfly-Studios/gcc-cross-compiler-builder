# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="aarch64-linux-gnu"
export LINUX_ARCH="arm64"

# Work directories
export CWORK="$HOME/sysroot/${TARGET}_gcc_build"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"
export HEADER_DIR="${CWORK}/${TARGET}"

# Pkg versions
export BINUTILSV=binutils-2.29.1
export GCCV=gcc-9.5.0
export GLIBCV=glibc-2.19
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-4.19
export LINUXMIN=2.6.9
export TEXINFOV=texinfo-5.0
export PARALLEL_MAKE="-j4"