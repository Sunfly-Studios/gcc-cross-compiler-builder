# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="loongarch64-linux-gnu"
export LINUX_ARCH="loongarch"

# Target flags for GCC abi consistency
# if not defined, then it uses defaults
export TARGET_CFLAGS=""
export TARGET_CONFIGURE_FLAGS="--with-arch=loongarch64 --with-abi=lp64d"

# Work directories
export CWORK="$HOME/sysroot/${TARGET}"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"
export HEADER_DIR="${CWORK}/${TARGET}"

# Pkg versions
export BINUTILSV=binutils-2.38
export GCCV=gcc-12.1.0
export GLIBCV=glibc-2.36
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-5.19
export TEXINFOV=texinfo-6.8
export MAKEV=make-4.4

export PARALLEL_MAKE="-j8"
