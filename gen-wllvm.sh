#!/usr/bin/env bash
# Build wllvm for nuttx projects

compile() {
  DB="$RTOSExploration/bitcode-db/nuttx/$1"
  [ -f "$DB/DONE" ] && echo "Skip $DB" && return
  mkdir -p "$DB"

  make distclean
  ./tools/configure.sh "$1"
  make CROSSDEV=arm-none-eabi- -j$(nproc)
  extract-bc nuttx && "$LLVM_COMPILER_PATH/llvm-dis" "nuttx.bc"
  cp nuttx.bc nuttx.ll "$DB"

  #make clean
  touch "$DB/DONE"
}

#export PATH="$(realpath ../gcc-arm-none-eabi-9-2019-q4-major/bin/):$PATH"
#export CCACHE_DISABLE=1 # disabled in ~/.ccache/ccache.conf
export PATH="$RTOSExploration/bin-wrapper:$PATH"
export WLLVM_OUTPUT_LEVEL=INFO \
       LLVM_COMPILER=hybrid \
       LLVM_COMPILER_PATH=/usr/lib/llvm-14/bin \
       GCC_PATH="$(realpath "$RTOSExploration/gcc-arm-none-eabi-9-2019-q4-major/bin/")" \
       GCC_CROSS_COMPILE_PREFIX=arm-none-eabi-

TOPDIR=nuttx
DUMPCFGS=""
configlist=`find ${TOPDIR}/boards/arm -name defconfig`
for defconfig in ${configlist}; do
  config=`dirname ${defconfig} | sed -e "s,${TOPDIR}/boards/,,g"`
  boardname=`echo ${config} | cut -d'/' -f3`
  configname=`echo ${config} | cut -d'/' -f5`
  DUMPCFGS="${DUMPCFGS} ${boardname}:${configname}"
done

cd nuttx
for cfg in $(echo "$DUMPCFGS" | sed 's, ,\n,g' | sort -t ':' -k2 -u); do
  echo "Compiling $cfg"
  compile $cfg
done
