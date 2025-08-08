# Script to download and install the C/C++ wrappers for Clarabel.rs
#
# https://github.com/oxfordcontrol/Clarabel.cpp
#
# Prequisites:
#
# Install rust toolchain:
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#
# Install Eigen library source code:
# sudo apt install libeigen3-dev
#
# Install CMake:
# sudo apt install cmake
#
# Install patchelf:
# sudo apt install patchelf

VERSION=v0.11.1
ARCH=`uname -m`

git clone --recurse-submodules https://github.com/oxfordcontrol/Clarabel.cpp.git
cd Clarabel.cpp
git checkout tags/$VERSION
mkdir build
cd build

echo Building debug library and tests...
cmake .. -DCLARABEL_CARGO_FEATURES="buildinfo" -DCLARABEL_BUILD_TESTS=true
cmake --build .
./tests/clarabel_cpp_tests
if [ $? != 0  ] ; then
    echo Test Failure!
    echo Exiting build
    exit 1
fi

echo Building release library...
cmake .. -DCLARABEL_CARGO_FEATURES="buildinfo" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../install
cmake --build .

echo Creating the install tarball...
cd ..

TARGET=clarabel_cpp-$VERSION
INSTALL_DIR=/var/tmp/$TARGET

install -d $INSTALL_DIR/include
install -d $INSTALL_DIR/include/c
install -d $INSTALL_DIR/include/cpp
install -d $INSTALL_DIR/lib
install -d $INSTALL_DIR/bin

install -t $INSTALL_DIR/include include/* 
install -t $INSTALL_DIR/include/c include/c/* 
install -t $INSTALL_DIR/include/cpp include/cpp/* 

install -m644 rust_wrapper/target/debug/libclarabel_c.a $INSTALL_DIR/lib/libclarabel_c-g.a
install -m644 rust_wrapper/target/debug/libclarabel_c.so $INSTALL_DIR/lib/libclarabel_c-g.so
install -m644 rust_wrapper/target/release/libclarabel_c.a $INSTALL_DIR/lib
install -m644 rust_wrapper/target/release/libclarabel_c.so $INSTALL_DIR/lib

for file in build/examples/c/example_* build/examples/cpp/cpp_example_*; do
  install $file $INSTALL_DIR/bin
  file=`basename $file`
  patchelf --set-rpath '$ORIGIN/../lib' $INSTALL_DIR/bin/$file
done

cd $INSTALL_DIR/..
tar zcvf ${TARGET}-${ARCH}.tgz $TARGET
md5sum ${TARGET}-${ARCH}.tgz > ${TARGET}-${ARCH}.md5




