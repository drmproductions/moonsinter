# moonsinter

`moonsinter` is a simple data synchronization tool contained in a single lua file that's around
500 lines of code (excluding embedded + minified json library, and external shared c libraries).
Updates are downloaded in chunks over HTTP or HTTPS.

An rsync style per byte rolling hash is not used by `moonsinter`, but instead a per chunk (a range
of bytes) hash. `moonsinter` works best when files have deterministic / reproducible layouts. So
changing a single character in your source shouldn't result in a massively different binary.

`moonsinter` uses [libcurl](https://curl.haxx.se/libcurl/) to download updates, and
[xxHash](https://cyan4973.github.io/xxHash/) to hash data. These are used via the ffi interface
built into [LuaJIT](http://luajit.org/). This project was designed for use in an embedded
environment that already has the aforementioned software installed, so compiling everything into a
single binary was not a goal. LuaJIT can also inline calls to c functions, greatly increasing the
performance of `moonsinter`.

Sintering is the process of compacting multiple materials together using heat or pressure without
melting it to the point of liquefaction. This project aims to do the same but with multiple sources
of data, while hopefully not melting your processor :). The moon part of the name comes from it
being wrote in Lua.


## Getting started

`moonsinter` has several dependencies: `luajit`, `libcurl`, `libxxhash`

Running `./build_deps.sh` on linux will build everything needed to run `moonsinter`. The following
files will be generated in the same directory: `luajit`, `libcurl.so`, `libxxhash.so`. You will
need gcc installed to build everything.

You can also specify where `libcurl` and `libxxhash` are using the `MOONSINTER_LIBCURL` and
`MOONSINTER_XXHASH` environment variables.


## Usage

All commands output JSON to stdout which can be consumed by a parent process for further processing.

`diff` will compare two files and output the difference as a percentage. `[chunk_size]` is the
number of bytes per chunk. It defaults to 128K (this is the default block size of a `squashfs`
file system) and can be suffixed with `K`, `M` and `G` (kibibyte, mebibyte, and gibibyte respectively).

	luajit moonsinter.lua diff <file_path_new> <file_path_old> [chunk_size]

`generate` creates a file at `<file_path>.json` that contains everything needed to `clone` the
differences later. The `<file_path>` and `<file_path>.json` files should both be uploaded to a
HTTP(S) server that supports [HTTP/1.1 Range Requests](https://tools.ietf.org/rfc/rfc7233.txt) requests.

	luajit moonsinter.lua generate <file_path> [chunk_size]

`clone` downloads the JSON file from `<input_url>.json` then loops over all the chunks, skipping
chunks already in the `<output_file_path>`, copying chunks in `<seed_file_path>`, and downloading
chunks that are in neither.

	luajit moonsinter.lua clone <input_url> <output_file_path> <seed_file_path>


## Goals

- Be simple, making it easier to maintain
- Be fast, making embedded use more feasible
- Have a small amount of dependencies, this includes making use of stuff that may already be installed (libcurl)


## Uses

`moonsinter` is used in production to download differences of `squashfs` root file systems. These
are generated with the [latest](https://github.com/plougher/squashfs-tools) `mksquashfs`, which
generates reproducible images by default as of 4.4. The `-sort` option is used to sort commonly
changed directories to the very end of the image.


## Example program

`rpi-partition-updater` can be used to perform updates between two partitions. Just copy
`moonsinter` and `rpi-partition-updater` to your linux machine and create a service that
starts `rpi-partition-updater` on boot like the following:

	luajit rpi-partition-updater.lua http://images.example.com/rootfs.squashfs /dev/mmcblk0p2 /dev/mmcblk0p3

NOTE: The program does not create missing partitions, but will ensure they exist before trying to perform updates.


## TODO

- [ ] While cloning, before copying a chunk from the seed file to the output file, check to see if
that location already matches the data we want to copy over. This will prevent unnecessary wear on
the storage device, at the cost of cpu time.


## Inspiration

- [bita](https://github.com/oll3/bita) - distributing updates via HTTP(S), generating an
intermediate file, and directly updating block devices was greatly inspired by this. How
the two accomplish this are vastly different though.

