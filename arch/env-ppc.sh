# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="powerpc-linux-gnu"
export LINUX_ARCH="powerpc"

# Target flags for GCC abi consistency
# if not defined, then it uses defaults
export TARGET_CFLAGS="-mcpu=powerpc -mbig"
export TARGET_CONFIGURE_FLAGS="--with-cpu=powerpc --enable-secureplt --disable-altivec --with-long-double-64"

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
export GLIBCV=glibc-2.28
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-4.19
export LINUXMIN=2.6.9
export MAKEV=make-4.3
export TEXINFOV=texinfo-6.5
export PARALLEL_MAKE="-j8"
