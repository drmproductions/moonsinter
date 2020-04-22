MOONSINTER_EXPORT_LIB = true

local ffi = require('ffi')
local moonsinter = require('moonsinter')

ffi.cdef [[
	unsigned int sleep(unsigned int seconds);
]]

local C = ffi.C

local function read_file(path)
	local file = io.open(path, 'r')
	local str = file:read('*all')
	file:close()
	return str
end

local function write_file(path, contents)
	local file = io.open(path, 'w')
	file:write(contents)
	file:close()
end

local function parse_kernel_config()
	local str = read_file('/proc/cmdline')
	local kernel_config = {}
	for prop in str:gmatch('%S+') do
		local n = prop:gmatch('[^=]+')
		local k, v = n(), n()
		kernel_config[k] = v or true
	end
	return kernel_config
end

local function get_seed_and_output_partition(partition_a, partition_b)
	local current_partition = parse_kernel_config().root

	if current_partition == partition_a then
		return partition_a, partition_b
	elseif current_partition == partition_b then
		return partition_b, partition_a
	end

	error('The current partition needs to be partition_a or partition_b')
end

local function update_boot_cmdline(seed_partition, output_partition)
	os.execute('mount /dev/mmcblk0p1 /boot')
	local str = read_file('/boot/cmdline.txt')
	str = str:gsub(seed_partition, output_partition)
	write_file('/boot/cmdline.txt', str)
	os.execute('umount /boot')
	write_file('/tmp/update-available', '1')
end

local function log(...)
	for _, arg in ipairs({...}) do
		io.write(tostring(arg))
	end
	io.write('\n')
	io.flush()
end

if #arg < 3 then
	log('usage: luajit rpi-partition-updater.lua <input_url> <partition_a> <partition_b> [minutes_before_update_attempts]')
	log('example: luajit rpi-partition-updater.lua http://images.example.com/rootfs.squashfs /dev/mmcblk0p2 /dev/mmcblk0p3 5')
	os.exit(1)
end

local input_url = arg[1]
local partition_a = arg[2]
local partition_b = arg[3]
local minutes_before_update_attempts = tonumber(arg[4]) or 5

while true do ::continue::
	local mins = minutes_before_update_attempts
	log(string.format('Sleeping %i minute%s before attempting next update', mins, mins == 1 and '' or 's'))
	C.sleep(minutes_before_update_attempts * 60)

	if C.access(partition_a, C.R_OK) == -1 then
		log('Unable to access partition a')
		goto continue
	end

	if C.access(partition_b, C.R_OK) == -1 then
		log('Unable to access partition b')
		goto continue
	end

	local seed_partition, output_partition = get_seed_and_output_partition(partition_a, partition_b)
	log('Seed partition: ', seed_partition)
	log('Output partition: ', output_partition)

	local total_chunks = 0

	moonsinter.clone(input_url, output_partition, seed_partition, function(tbl)
		local e = tbl.event
		if e == 'dl_manifest_start' then
			log('Downloading manifest')
		elseif e == 'dl_manifest_end' then
			log('Manifest downloaded')
		elseif e == 'dl_manifest_failed' then
			log('Failed to download manifest: ', tbl.value)
		elseif e == 'total_chunks' then
			total_chunks = tbl.value
			log('Total chunks: ', total_chunks)
		elseif e == 'seed_file_hash_start' then
			log('Starting hash of seed file')
		elseif e == 'seed_file_hash_error' then
			log('Error while hashing seed file: ', tbl.value)
		elseif e == 'seed_file_hash_end' then
			log('Finished hash of seed file')
		elseif e == 'seed_file_hash_match' then
			log('Seed hash matches manifest hash, no update needed!')
			-- ensure the boot command line is correct
			update_boot_cmdline(seed_partition, output_partition)
		elseif e == 'output_file_hash_start' then
			log('Starting hash of output file')
		elseif e == 'output_file_hash_error' then
			log('Error while hashing output file: ', tbl.value)
		elseif e == 'output_file_hash_end' then
			log('Finished hash of output file')
		elseif e == 'output_file_hash_match' then
			log('Output hash matches manifest hash, no update needed!')
			-- ensure the boot command line is correct
			update_boot_cmdline(seed_partition, output_partition)
		elseif e == 'cp_chunk' then
			log('Copied chunk: ', tbl.value, '/', total_chunks)
		elseif e == 'dl_chunk_failed' then
			log('Error while downloading chunk ', tbl.index, ': ', tbl.value)
		elseif e == 'dl_chunk' then
			log('Downloaded chunk: ', tbl.value, '/', total_chunks, ' size = ', tbl.size)
		elseif e == 'output_file_hash_start' then
			log('Validating output partition')
		elseif e == 'output_file_hash_error' then
			log('Validation failed: ', tbl.value)
		elseif e == 'output_file_hash_bad' then
			log('Validation failed: ', tbl.value)
		elseif e == 'output_file_hash_end' then
			log('Validation complete')
		elseif e == 'done' then
			log('Update complete: bytes downloaded = ', tbl.total_bytes_downloaded, ', chunks downloaded = ', tbl.total_chunks_downloaded)
			update_boot_cmdline(seed_partition, output_partition)
		end
	end)
end
