# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="arm-linux-gnueabihf"
export LINUX_ARCH="arm"

# Target flags for GCC abi consistency
# if not defined, then it uses defaults
export TARGET_CFLAGS="-march=armv7-a -mthumb -mfpu=vfpv3-d16 -mfloat-abi=hard"
export TARGET_CONFIGURE_FLAGS="--with-arch=armv7-a --with-mode=thumb --with-float=hard --with-fpu=vfpv3-d16 --with-float-abi=hard"

# Work directories
export CWORK="$HOME/sysroot/${TARGET}"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"
export HEADER_DIR="${CWORK}/${TARGET}"

# Pkg versions
export BINUTILSV=binutils-2.28
export GCCV=gcc-9.5.0
export GLIBCV=glibc-2.24
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-4.19
export LINUXMIN=2.6.9
export MAKEV=make-4.3
export TEXINFOV=texinfo-6.0
export PARALLEL_MAKE="-j8"
