local ffi = require('ffi')

local function safe_ffi_load(name)
	local lib
	local ran, err = pcall(function()
		lib = ffi.load(name)
	end)
	return lib
end

local C = (function()
	ffi.cdef[[
		enum {
			R_OK = 4,
			W_OK = 2,
		};

		int access(const char *__name, int __type);
	]]

	return ffi.C
end)()

local curl = (function()
	ffi.cdef[[
		typedef enum {
			CURLE_OK = 0,
		} CURLcode;

		typedef enum {
			CURLOPT_URL = 10002,
			CURLOPT_RANGE = 10007,
			CURLOPT_WRITEFUNCTION = 20011,
		} CURLoption;

		typedef struct Curl_easy CURL;

		void curl_easy_cleanup(CURL *curl);
		CURL *curl_easy_init(void);
		CURLcode curl_easy_perform(CURL *curl);
		CURLcode curl_easy_setopt(CURL *curl, CURLoption option, ...);
		const char *curl_easy_strerror(CURLcode);
	]]

	local path = os.getenv('MOONSINTER_LIBCURL')
	if path then return ffi.load(path) end

	return safe_ffi_load('curl') or ffi.load('./libcurl.so')
end)()

local json = (function()
	-- Minified version of https://github.com/rxi/json.lua
	--
	-- json.lua
	--
	-- Copyright (c) 2019 rxi
	--
	-- Permission is hereby granted, free of charge, to any person obtaining a copy of
	-- this software and associated documentation files (the "Software"), to deal in
	-- the Software without restriction, including without limitation the rights to
	-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
	-- of the Software, and to permit persons to whom the Software is furnished to do
	-- so, subject to the following conditions:
	--
	-- The above copyright notice and this permission notice shall be included in all
	-- copies or substantial portions of the Software.
	--
	-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	-- SOFTWARE.
	--
	local a={_version="0.1.2"}local b;local c={["\\"]="\\\\",["\""]="\\\"",["\b"]="\\b",["\f"]="\\f",["\n"]="\\n",["\r"]="\\r",["\t"]="\\t"}local d={["\\/"]="/"}for e,f in pairs(c)do d[f]=e end;local function g(h)return c[h]or string.format("\\u%04x",h:byte())end;local function i(j)return"null"end;local function k(j,l)local m={}l=l or{}if l[j]then error("circular reference")end;l[j]=true;if rawget(j,1)~=nil or next(j)==nil then local n=0;for e in pairs(j)do if type(e)~="number"then error("invalid table: mixed or invalid key types")end;n=n+1 end;if n~=#j then error("invalid table: sparse array")end;for o,f in ipairs(j)do table.insert(m,b(f,l))end;l[j]=nil;return"["..table.concat(m,",").."]"else for e,f in pairs(j)do if type(e)~="string"then error("invalid table: mixed or invalid key types")end;table.insert(m,b(e,l)..":"..b(f,l))end;l[j]=nil;return"{"..table.concat(m,",").."}"end end;local function p(j)return'"'..j:gsub('[%z\1-\31\\"]',g)..'"'end;local function q(j)if j~=j or j<=-math.huge or j>=math.huge then error("unexpected number value '"..tostring(j).."'")end;return string.format("%.14g",j)end;local r={["nil"]=i,["table"]=k,["string"]=p,["number"]=q,["boolean"]=tostring}b=function(j,l)local s=type(j)local t=r[s]if t then return t(j,l)end;error("unexpected type '"..s.."'")end;function a.encode(j)return b(j)end;local u;local function v(...)local m={}for o=1,select("#",...)do m[select(o,...)]=true end;return m end;local w=v(" ","\t","\r","\n")local x=v(" ","\t","\r","\n","]","}",",")local y=v("\\","/",'"',"b","f","n","r","t","u")local z=v("true","false","null")local A={["true"]=true,["false"]=false,["null"]=nil}local function B(C,D,E,F)for o=D,#C do if E[C:sub(o,o)]~=F then return o end end;return#C+1 end;local function G(C,D,H)local I=1;local J=1;for o=1,D-1 do J=J+1;if C:sub(o,o)=="\n"then I=I+1;J=1 end end;error(string.format("%s at line %d col %d",H,I,J))end;local function K(n)local t=math.floor;if n<=0x7f then return string.char(n)elseif n<=0x7ff then return string.char(t(n/64)+192,n%64+128)elseif n<=0xffff then return string.char(t(n/4096)+224,t(n%4096/64)+128,n%64+128)elseif n<=0x10ffff then return string.char(t(n/262144)+240,t(n%262144/4096)+128,t(n%4096/64)+128,n%64+128)end;error(string.format("invalid unicode codepoint '%x'",n))end;local function L(M)local N=tonumber(M:sub(3,6),16)local O=tonumber(M:sub(9,12),16)if O then return K((N-0xd800)*0x400+O-0xdc00+0x10000)else return K(N)end end;local function P(C,o)local Q=false;local R=false;local S=false;local T;for U=o+1,#C do local V=C:byte(U)if V<32 then G(C,U,"control character in string")end;if T==92 then if V==117 then local W=C:sub(U+1,U+5)if not W:find("%x%x%x%x")then G(C,U,"invalid unicode escape in string")end;if W:find("^[dD][89aAbB]")then R=true else Q=true end else local h=string.char(V)if not y[h]then G(C,U,"invalid escape char '"..h.."' in string")end;S=true end;T=nil elseif V==34 then local M=C:sub(o+1,U-1)if R then M=M:gsub("\\u[dD][89aAbB]..\\u....",L)end;if Q then M=M:gsub("\\u....",L)end;if S then M=M:gsub("\\.",d)end;return M,U+1 else T=V end end;G(C,o,"expected closing quote for string")end;local function X(C,o)local V=B(C,o,x)local M=C:sub(o,V-1)local n=tonumber(M)if not n then G(C,o,"invalid number '"..M.."'")end;return n,V end;local function Y(C,o)local V=B(C,o,x)local Z=C:sub(o,V-1)if not z[Z]then G(C,o,"invalid literal '"..Z.."'")end;return A[Z],V end;local function _(C,o)local m={}local n=1;o=o+1;while 1 do local V;o=B(C,o,w,true)if C:sub(o,o)=="]"then o=o+1;break end;V,o=u(C,o)m[n]=V;n=n+1;o=B(C,o,w,true)local a0=C:sub(o,o)o=o+1;if a0=="]"then break end;if a0~=","then G(C,o,"expected ']' or ','")end end;return m,o end;local function a1(C,o)local m={}o=o+1;while 1 do local a2,j;o=B(C,o,w,true)if C:sub(o,o)=="}"then o=o+1;break end;if C:sub(o,o)~='"'then G(C,o,"expected string for key")end;a2,o=u(C,o)o=B(C,o,w,true)if C:sub(o,o)~=":"then G(C,o,"expected ':' after key")end;o=B(C,o+1,w,true)j,o=u(C,o)m[a2]=j;o=B(C,o,w,true)local a0=C:sub(o,o)o=o+1;if a0=="}"then break end;if a0~=","then G(C,o,"expected '}' or ','")end end;return m,o end;local a3={['"']=P,["0"]=X,["1"]=X,["2"]=X,["3"]=X,["4"]=X,["5"]=X,["6"]=X,["7"]=X,["8"]=X,["9"]=X,["-"]=X,["t"]=Y,["f"]=Y,["n"]=Y,["["]=_,["{"]=a1}u=function(C,D)local a0=C:sub(D,D)local t=a3[a0]if t then return t(C,D)end;G(C,D,"unexpected character '"..a0 .."'")end;function a.decode(C)if type(C)~="string"then error("expected argument of type string, got "..type(C))end;local m,D=u(C,B(C,1,w,true))D=B(C,D,w,true)if D<=#C then G(C,D,"trailing garbage")end;return m end;return a
end)()

local xxhash = (function()
	ffi.cdef[[
		typedef unsigned int XXH32_hash_t;

		typedef enum { XXH_OK = 0, XXH_ERROR } XXH_errorcode;

		typedef struct XXH32_state_s XXH32_state_t;

		XXH32_hash_t XXH32(const void* input, size_t length, unsigned int seed);
		XXH32_state_t *XXH32_createState(void);
		XXH_errorcode XXH32_freeState(XXH32_state_t *statePtr);
		XXH_errorcode XXH32_update(XXH32_state_t *statePtr, const void *input, size_t length);
		XXH32_hash_t XXH32_digest(const XXH32_state_t *statePtr);
		XXH_errorcode XXH32_reset(XXH32_state_t *statePtr, XXH32_hash_t seed);
	]]

	local path = os.getenv('MOONSINTER_XXHASH')
	if path then return ffi.load(path) end

	return safe_ffi_load('xxhash') or ffi.load('./libxxhash.so')
end)()

local lib = {}

local function exit()
	if not MOONSINTER_EXPORT_LIB then os.exit(1) end
end

local function log(...)
	for _, arg in ipairs({...}) do
		io.write(tostring(arg))
	end
	io.write('\n')
	io.flush()
end

local function log_json(tbl)
	log(json.encode(tbl))
end

local function parse_chunk_size(chunk_size)
	local default = 1024 * 128 -- default to 128K (the default for squashfs)

	if chunk_size == nil then return default end

	local result
	local multiplier = 1
	local chunk_size_lower = chunk_size:lower()

	local unit = chunk_size_lower:sub(-1)
	if unit == 'k' then
		result = tonumber(chunk_size_lower:sub(0, -2))
		multiplier = 1024
	elseif unit == 'm' then
		result = tonumber(chunk_size_lower:sub(0, -2))
		multiplier = 1024 * 1024
	elseif unit == 'g' then
		result = tonumber(chunk_size_lower:sub(0, -2))
		multiplier = 1024 * 1024 * 1024
	else
		result = tonumber(chunk_size_lower)
	end

	if result == nil then return default end

	return result * multiplier
end

function lib.clone(input_url, output_file_path, seed_file_path, event_callback)
	local emit = event_callback or log_json

	local function create_downloader(input_url, max_chunk_size)
		local data = ffi.new('char[?]', max_chunk_size)
		local data_offset = 0

		local write_function = ffi.cast('size_t (*)(char *, size_t, size_t, void *)', function(ptr, size, nmemb, userdata)
			ffi.copy(data + data_offset, ptr, nmemb)
			data_offset = data_offset + nmemb
			return nmemb
		end)

		local c = curl.curl_easy_init()
		curl.curl_easy_setopt(c, curl.CURLOPT_URL, input_url)
		curl.curl_easy_setopt(c, curl.CURLOPT_WRITEFUNCTION, write_function)

		local function cleanup()
			curl.curl_easy_cleanup(c)
			-- this is important as LuaJIT can create only a limited amount of c callbacks
			write_function:free()
		end

		return {
			download = function(chunk_start, chunk_size, chunk_hash)
				data_offset = 0
				ffi.fill(data, max_chunk_size, 0)

				local range = chunk_start .. '-' .. (chunk_start + chunk_size - 1)

				curl.curl_easy_setopt(c, curl.CURLOPT_RANGE, range)
				local result = curl.curl_easy_perform(c)

				if result ~= curl.CURLE_OK then
					cleanup()
					return nil, ffi.string(curl.curl_easy_strerror(result))
				end

				local hash = xxhash.XXH32(data, chunk_size, 0)
				if hash ~= chunk_hash then
					cleanup()
					return nil, 'Hashes don\'t match'
				end

				return data
			end,
			done = cleanup,
		}
	end

	local function download_manifest(input_url)
		local json_parts = {}

		local write_function = ffi.cast('size_t (*)(char *, size_t, size_t, void *)', function(ptr, size, nmemb, userdata)
			table.insert(json_parts, ffi.string(ptr, nmemb))
			return nmemb
		end)

		local c = curl.curl_easy_init()
		curl.curl_easy_setopt(c, curl.CURLOPT_URL, input_url .. '.json')
		curl.curl_easy_setopt(c, curl.CURLOPT_WRITEFUNCTION, write_function)
		local result = curl.curl_easy_perform(c)

		curl.curl_easy_cleanup(c)
		write_function:free()

		if result ~= curl.CURLE_OK then
			return nil, ffi.string(curl.curl_easy_strerror(result))
		end

		return table.concat(json_parts, '')
	end

	local function hash_file(file_path, file_size, chunk_size)
		local file = assert(io.open(file_path, 'rb'))
		file:setvbuf('no')

		local state = xxhash.XXH32_createState()
		xxhash.XXH32_reset(state, 0)

		local reached_end = false
		local total_data_size = 0
		while true do
			local data = file:read(chunk_size)
			if data == nil then break end

			local data_size = #data
			total_data_size = total_data_size + data_size

			-- subtract the difference
			if total_data_size > file_size then
				data_size = data_size - (total_data_size - file_size)
				reached_end = true
			end

			if xxhash.XXH32_update(state, data, data_size) ~= xxhash.XXH_OK then
				return nil, false
			end

			if reached_end then break end
		end

		local hash = xxhash.XXH32_digest(state)
		xxhash.XXH32_freeState(state)

		file:close()

		return hash, true
	end

	local function parse_chunk_hashes_string(str)
		local results = {}
		local start_index = 1
		while true do
			local end_index = str:find(',', start_index)
			if end_index == nil then
				table.insert(results, tonumber('0x' .. str:sub(start_index)))
				break
			end
			table.insert(results, tonumber('0x' .. str:sub(start_index, end_index - 1)))
			start_index = end_index + 1
		end
		return results
	end

	-- download the manifest

	emit { event = 'dl_manifest_start' }
	local manifest_str, err = download_manifest(input_url)
	if err then
		emit { event = 'dl_manifest_failed', value = err }
		return exit()
	end
	emit { event = 'dl_manifest_end' }

	local manifest = json.decode(manifest_str)
	local chunk_size = manifest['chunk_size']
	local last_chunk_size = manifest['last_chunk_size']

	local chunk_hashes = parse_chunk_hashes_string(manifest['chunk_hashes'])
	local total_chunks = #chunk_hashes
	emit { event = 'total_chunks', value = total_chunks }

	emit { event = 'seed_file_hash_start' }
	local seed_file_hash, ok = hash_file(seed_file_path, manifest['file_size'], chunk_size)
	if not ok then
		emit { event = 'seed_file_hash_error', value = 'Failed to hash seed file' }
		return exit()
	end
	emit { event = 'seed_file_hash_end' }

	if seed_file_hash == manifest['file_hash'] then
		emit { event = 'seed_file_hash_match' }
		return exit()
	end

	local seed_file = assert(io.open(seed_file_path, 'rb'))
	seed_file:setvbuf('no')

	local output_file = assert(io.open(output_file_path, 'wb'))
	output_file:setvbuf('no')

	-- allocate memory that can fit the max chunk size (the last chunk while probably be smaller than this)
	-- local downloaded_chunk_data = ffi.new('char[?]', chunk_size)
	local total_bytes_downloaded = 0
	local total_chunks_downloaded = 0
	local downloader = create_downloader(input_url, chunk_size)

	for chunk_index, hash in ipairs(chunk_hashes) do
		local size = chunk_index == total_chunks and last_chunk_size or chunk_size

		local data = seed_file:read(size)
		local data_size = data and #data or 0

		if data_size == size and xxhash.XXH32(data, data_size, 0) == hash then
			output_file:write(data)
			emit { event = 'cp_chunk', value = chunk_index }
		else
			local data, err = downloader.download(output_file:seek(), size, hash)

			if err then
				emit { event = 'dl_chunk_failed', index = chunk_index, value = err }
				return exit()
			end

			total_chunks_downloaded = total_chunks_downloaded + 1
			total_bytes_downloaded = total_bytes_downloaded + size
			output_file:write(ffi.string(data, size))
			emit { event = 'dl_chunk', value = chunk_index, size = size }
		end
	end

	downloader.done()

	seed_file:close()
	output_file:close()

	emit { event = 'output_file_hash_start' }
	local output_file_hash, ok = hash_file(output_file_path, manifest['file_size'], chunk_size)
	if not ok then
		emit { event = 'output_file_hash_error', value = 'Failed to hash output file' }
		return exit()
	end

	if output_file_hash ~= manifest['file_hash'] then
		emit { event = 'output_file_hash_bad', value = string.format('Expected %i but got %i', manifest['file_hash'], output_file_hash) }
		return exit()
	end
	emit { event = 'output_file_hash_end' }

	emit {
		event = 'done',
		total_bytes_downloaded = total_bytes_downloaded,
		total_chunks_downloaded = total_chunks_downloaded,
	}
end

function lib.diff(file_path_new, file_path_old, chunk_size, event_callback)
	local emit = event_callback or log_json

	if C.access(file_path_new, C.R_OK) == -1 then
		emit { event = 'unable_to_access_file', value = file_path_new }
		return exit()
	end

	if C.access(file_path_old, C.R_OK) == -1 then
		emit { event = 'unable_to_access_file', value = file_path_old }
		return exit()
	end

	chunk_size = parse_chunk_size(chunk_size)
	emit { event = 'chunk_size', value = chunk_size }

	local file_new = assert(io.open(file_path_new, 'rb'))
	file_new:setvbuf('no')

	local file_old = assert(io.open(file_path_old, 'rb'))
	file_old:setvbuf('no')

	local diff, total, same = 0, 0, 0

	while true do
		local data_new = file_new:read(chunk_size)
		local data_old = file_old:read(chunk_size)

		if not data_new or not data_old then
			break
		end

		local hash_new = data_new and xxhash.XXH32(data_new, #data_new, 0) or 0
		local hash_old = data_old and xxhash.XXH32(data_old, #data_old, 0) or 0

		total = total + 1

		if hash_new == hash_old then
			same = same + 1
		else
			diff = diff + 1
		end
	end

	file_old:close()
	file_new:close()

	emit { event = 'done', percentage_different = (diff / total) * 100 }
end

function lib.generate(file_path, chunk_size, event_callback)
	local emit = event_callback or log_json
	file_path = file_path or ''

	if C.access(file_path, C.R_OK) == -1 then
		emit { event = 'unable_to_access_file', value = file_path }
		return exit()
	end

	chunk_size = parse_chunk_size(chunk_size)
	emit { event = 'chunk_size', value = chunk_size }

	local input_file = assert(io.open(file_path, 'rb'))
	input_file:setvbuf('no')

	local output_file = assert(io.open(file_path .. '.json', 'w'))
	output_file:write('{')
	output_file:write('"chunk_hashes":"')

	local chunk_count = 0
	local state = xxhash.XXH32_createState()
	local file_size = 0
	local last_chunk_size = 0
	xxhash.XXH32_reset(state, 0)
	while true do
		local data = input_file:read(chunk_size)
		if data == nil then
			break
		end

		local data_size = #data
		file_size = file_size + data_size

		-- write the comma for the previous hash
		if chunk_count > 0 then
			output_file:write(',')
		end

		if xxhash.XXH32_update(state, data, data_size) ~= xxhash.XXH_OK then
			emit { event = 'hash_update_failed' }
			return exit()
		end

		output_file:write(string.format('%x', xxhash.XXH32(data, data_size, 0)))

		chunk_count = chunk_count + 1

		last_chunk_size = data_size
	end
	output_file:write('",')
	output_file:write('"chunk_size":' .. chunk_size .. ',')
	output_file:write('"last_chunk_size":' .. last_chunk_size .. ',')
	local file_hash = xxhash.XXH32_digest(state)
	output_file:write('"file_hash":' .. file_hash .. ',')
	output_file:write('"file_size":' .. file_size)
	xxhash.XXH32_freeState(state)

	output_file:write('}')
	output_file:close()
	input_file:close()

	emit {
		event = 'done',
		chunk_count = chunk_count,
		chunk_size = chunk_size,
		file_hash = file_hash,
		file_size = file_size,
	}
end

if MOONSINTER_EXPORT_LIB then return lib end

if arg[1] == 'clone' then
	if #arg < 4 then
		log('usage: luajit moonsinter.lua clone <input_url> <output_file_path> <seed_file_path>')
		os.exit(1)
	end
	lib.clone(arg[2], arg[3], arg[4])
elseif arg[1] == 'diff' then
	if #arg < 3 then
		log('usage: luajit moonsinter.lua diff <file_path_new> <file_path_old> [chunk_size]')
		os.exit(1)
	end
	lib.diff(arg[2], arg[3], arg[4])
elseif arg[1] == 'generate' then
	if #arg < 2 then
		log('usage: luajit moonsinter.lua generate <file_path> [chunk_size]')
		os.exit(1)
	end
	lib.generate(arg[2], arg[3])
else
	log('Usage:')
	log('  luajit moonsinter.lua clone <input_url> <output_file_path> <seed_file_path>')
	log('  luajit moonsinter.lua diff <file_path_new> <file_path_old> [chunk_size]')
	log('  luajit moonsinter.lua generate <file_path> [chunk_size]')
end
