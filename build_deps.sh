#!/bin/sh

CURL_VERSION=7.68.0
LUAJIT_VERSION=2.2.0
XXHASH_VERSION=0.7.2
CORE_COUNT=$(grep -c ^processor /proc/cpuinfo)

echo 'Installing LuaJIT'
wget https://github.com/moonjit/moonjit/archive/$LUAJIT_VERSION.tar.gz
tar xf $LUAJIT_VERSION.tar.gz
rm $LUAJIT_VERSION.tar.gz
cd moonjit-$LUAJIT_VERSION
make -j$CORE_COUNT
cp src/luajit ..
cd ..
rm -rf moonjit-$LUAJIT_VERSION

echo 'Installing curl'
wget https://github.com/curl/curl/releases/download/curl-$(echo $CURL_VERSION | tr . _)/curl-$CURL_VERSION.tar.xz
tar xf curl-$CURL_VERSION.tar.xz
rm curl-$CURL_VERSION.tar.xz
cd curl-$CURL_VERSION
./configure --disable-ftp --disable-file --disable-ldap \
	--disable-ldaps --disable-rtsp --disable-dict \
	--disable-telnet --disable-tftp --disable-pop3 \
	--disable-imap --disable-smb --disable-smtp \
	--disable-gopher --disable-manual --disable-debug --disable-verbose
make -j$CORE_COUNT
cp lib/.libs/libcurl.so ..
cd ..
rm -rf curl-$CURL_VERSION

echo 'Installing xxHash'
wget https://github.com/Cyan4973/xxHash/archive/v$XXHASH_VERSION.tar.gz
tar xf v$XXHASH_VERSION.tar.gz
rm v$XXHASH_VERSION.tar.gz
cd xxHash-$XXHASH_VERSION
make -j$CORE_COUNT
cp libxxhash.so ..
cd ..
rm -rf xxHash-$XXHASH_VERSION

echo 'Use the following to run:'
echo './luajit moonsinter.lua'

