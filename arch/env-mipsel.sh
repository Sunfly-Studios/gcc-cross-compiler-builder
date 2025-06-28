# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="mipsel-linux-gnu"
export LINUX_ARCH="mips"

# Target flags for GCC abi consistency
# if not defined, then it uses defaults
export TARGET_CFLAGS="-march=mips32 -mabi=32 -mlittle-endian"
export TARGET_CONFIGURE_FLAGS="--with-arch=mips32 --with-abi=32 --with-endian=little"

# Work directories
export CWORK="$HOME/sysroot/${TARGET}"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"
export HEADER_DIR="${CWORK}/${TARGET}"

# Pkg versions
export BINUTILSV=binutils-2.29.1
export GCCV=gcc-9.5.0
export GLIBCV=glibc-2.21
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-4.9
export LINUXMIN=2.6.9
export MAKEV=make-4.3
export TEXINFOV=texinfo-6.8
export PARALLEL_MAKE="-j8"
