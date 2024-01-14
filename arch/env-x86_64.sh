# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="x86_64-linux-gnu"
export LINUX_ARCH="x86"

# Work directories
export CWORK="$HOME/sysroot/${TARGET}_gcc_build"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"
export HEADER_DIR="${CWORK}/${TARGET}"

# Pkg versions
export BINUTILSV=binutils-2.36.1
export GCCV=gcc-13.2.0
export GLIBCV=glibc-2.11.3
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-2.6.32.5
export TEXINFOV=texinfo-3.12

# Some older versions of GLIBC might
# complain about `make` or other tools being too old (false).
# Which would fail, this variable is optional
# and can be set for some targets like this one.
export MAKEV=make-4.0

export PARALLEL_MAKE="-j4"
