# Sourceable xtraction of environment variables so you can continue working in a shell for manual labour.
# vi: ft=sh

# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="powerpc64le-linux-gnu"
export LINUX_ARCH="powerpc"

# Work directories
export CWORK="$HOME/sysroot/${TARGET}_gcc_build"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"
export HEADER_DIR="${CWORK}/${TARGET}"

# Pkg versions
export BINUTILSV=binutils-2.35.2
export GCCV=gcc-13.2.0
export GLIBCV=glibc-2.33
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-4.19
export TEXINFOV=texinfo-6.7

export PARALLEL_MAKE="-j4"
