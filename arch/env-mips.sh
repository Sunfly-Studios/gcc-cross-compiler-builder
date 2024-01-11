# Sourceable xtraction of environment variables so you can continue working in a shell for manual labour.
# vi: ft=sh

# Cross variables.
export HOST="$MACHTYPE"
export BUILD="$HOST"
export TARGET="mipsel-unknown-linux-gnu"
export LINUX_ARCH="mips"

# Work directories
export CWORK="$HOME/src/${TARGET}_gcc_build"
export SRC="$CWORK/src"
export OBJ="$CWORK/obj"
export TOOLS="$CWORK/tools"
export SYSROOT="$CWORK/sysroot"

# Pkg versions
export BINUTILSV=binutils-2.24
export GCCV=gcc-4.9.0
#export GCCV=gccgo
export GLIBCV=glibc-2.19
export GLIBCVNO=$(echo $GLIBCV | sed -e 's/.*-\([[:digit:]]\)/\1/')
export LINUXV=linux-2.6.31.14

# GLIBC is very sensitive to any version except the ones
# the GNU team have said to work. Check
# https://elixir.bootlin.com/glibc/GLIBCV/source/INSTALL,
# find the "Recommended Tools for Compilation" section,
# and set the version to what they recommend there.
export TEXINFOV=texinfo-4.5

export PARALLEL_MAKE="-j4"