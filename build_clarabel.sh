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

target=clarabel_cpp_$VERSION
install_dir=/var/tmp/$target

install -d $install_dir/include
install -d $install_dir/include/c
install -d $install_dir/include/cpp
install -d $install_dir/lib
install -d $install_dir/bin

install -t $install_dir/include include/* 
install -t $install_dir/include/c include/c/* 
install -t $install_dir/include/cpp include/cpp/* 

install -m644 rust_wrapper/target/debug/libclarabel_c.a $install_dir/lib/libclarabel_c-g.a
install -m644 rust_wrapper/target/debug/libclarabel_c.so $install_dir/lib/libclarabel_c-g.so
install -m644 rust_wrapper/target/release/libclarabel_c.a $install_dir/lib
install -m644 rust_wrapper/target/release/libclarabel_c.so $install_dir/lib

for file in   build/examples/c/example_* build/examples/cpp/cpp_example_*; do
  install $file $install_dir/bin
  file=`basename $file`
  patchelf --set-rpath '$ORIGIN/../lib' $install_dir/bin/$file
done

cd $install_dir/..
tar zcvf ${target}.tgz $target





