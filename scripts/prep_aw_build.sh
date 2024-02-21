#! /usr/bin/sh

# This script changes all LUA references in Awesome WM to the exact LUA
# interpreter you use.
# It prevent issues when you build and run tests with multiple LUA versions
# installed on you device and the default one (aka $lua) is lua5.4 which is not
# yet supported by Awesome.

# Script based on:
#  * https://aur.archlinux.org/packages/awesome-git/
#  * https://aur.archlinux.org/packages/awesome-luajit-git/
#  * https://github.com/awesomeWM/awesome/pull/3163#issuecomment-751760332

# Setup your LUA interpreter here
LUA=lua
LUA_VERSION=5.3
LUA_BINARY=${LUA}${LUA_VERSION}

# remove previously generated builds
rm -Rf build
rm -f CMakeCache.txt
rm -Rf CMakeFiles

# update lua binary calls
sed -i "s/COMMAND lua\b/COMMAND ${LUA_BINARY}/" awesomeConfig.cmake tests/examples/CMakeLists.txt
sed -i "s/LUA_COV_RUNNER lua\b/LUA_COV_RUNNER ${LUA_BINARY}/" tests/examples/CMakeLists.txt
sed -i 's/"lua"/\"'"${LUA_BINARY}"'"/g' tests/_client.lua
sed -i 's/"lua"/\"'"${LUA_BINARY}"'"/g' tests/test-selection-getter.lua
sed -i 's/"lua"/\"'"${LUA_BINARY}"'"/g' tests/test-selection-transfer.lua
sed -i 's/"lua"/\"'"${LUA_BINARY}"'"/g' tests/test-selection-watcher.lua
sed -i 's/"lua"/\"'"${LUA_BINARY}"'"/g' tests/test-spawn.lua
sed -i 's/"lua"/\"'"${LUA_BINARY}"'"/g' tests/test-titlebar.lua


# init cmake
mkdir build
cd build
cmake .. \
    -DLUA_INCLUDE_DIR=/usr/include/${LUA_BINARY} \
    -DLUA_LIBRARY=/usr/lib/x86_64-linux-gnu/liblua5.3.so
cd ..
