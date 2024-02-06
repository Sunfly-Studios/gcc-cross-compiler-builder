# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="powerpc-linux-gnu"
export LINUX_ARCH="powerpc"

# Work directories
export CWORK="$HOME/sysroot/${TARGET}_gcc_build"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"
export HEADER_DIR="${CWORK}/${TARGET}"

# Pkg versions
export BINUTILSV=binutils-2.31.1
export GCCV=gcc-9.5.0
export GLIBCV=glibc-2.28
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-4.19
export LINUXMIN=2.6.9
export TEXINFOV=texinfo-6.5
export PARALLEL_MAKE="-j4"