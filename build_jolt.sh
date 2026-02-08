#!/usr/bin/bash

CONFIG=${1:-Debug}

echo "Building joltc with config: $CONFIG"

if [ ! -d "./joltc" ] ; then
    echo cloning jolt c
    git clone https://github.com/amerkoleci/joltc.git
fi
if [ ! -d "./odin-c-bindgen" ] ; then
    echo cloning odin bind gen
    git clone https://github.com/karl-zylinski/odin-c-bindgen.git
fi
if [ ! -f bindgen.bin ] ; then
    echo compiling odin bind gen
    # install libdevl
    odin build odin-c-bindgen/src -out:bindgen.bin
fi


cmake -S joltc -B joltc/build \
    -DJPH_SAMPLES=OFF \
    -DJPH_BUILD_SHARED=ON \
    -DCMAKE_BUILD_TYPE=$CONFIG

cmake --build joltc/build --config $CONFIG
echo "copying lib and h file"
cp ./joltc/include/joltc.h libs/jolt/jolt.h
cp ./joltc/build/lib/libjoltcd.so libs/jolt
echo "generating bindigns"
./bindgen.bin ./libs/jolt
