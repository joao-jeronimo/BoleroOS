# Install previously:
# sudo apt-get install libgtk2.0-dev libsdl1.2-dev libsdl2-dev libwxbase3.0-dev

mkdir bochs
cd bochs
svn checkout svn://svn.code.sf.net/p/bochs/code/trunk/bochs bochs-code
mkdir bochs-build
mkdir bochs-install

cd bochs-build
../bochs-code/configure --help
CFLAGS=" -Wall -pipe -O3 -march=native" CXXFLAGS=$CFLAGS ../bochs-code/configure --prefix=`pwd`/../bochs-install --with-all-libs --enable-readline --enable-debugger --enable-x86-64 --enable-smp --enable-show-ips --enable-disasm --enable-all-optimizations --enable-instrumentation="instrument/stubs" --enable-usb --enable-ne2000
make -j3
make install
