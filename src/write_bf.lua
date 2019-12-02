#!/usr/bin/lua
g_db = require("genders")
require("bfcommons")
-- handle must be global
local cnf_filename = "/etc/clustduct.conf"
-- read the config
local config = {}
local cnf_file,err = loadfile(cnf_filename,"t",config)
if cnf_file then cnf_file() else print(err) end
if config.clustduct["confdir" ]== nil then config.clustduct["confdir"]="/etc/clustduct.d/" end
if config.clustduct["tftpdir"] == nil then config.clustduct["tftpdir"] = "/srv/tftpboot" end
if config.clustduct["outdir"] == nil then config.clustduct["outdir"] = "/clustduct" end
if config.clustduct["netclass"] == nil then config.clustduct["netclass"] = "01" end
if config.clustduct["genders"] == nil then config.clustduct["genders"] = "/etc/genders" end
local handle = g_db.new(config.clustduct["genders"])
-- always overwrite files
config.clustduct['overwrite'] = true
-- variables
local node = nil
local force = false


-- parse commandline
getopt = require 'posix.unistd'.getopt
for r, optarg, optind in getopt(arg, 'hfc:n:o:b:') do
	if r == '?' then
		return print('unrecognized option', arg[optind -1])
	end
	if r == 'h' then
		print '-h      print this help text'
		print '-n NODE create config only for given and not all nodes'
		print '-o ARG  output dir'
		print '-c ARG  confguration dir'
		return 0
	elseif r == 'c' then
		config.clustduct["confdir"] = optarg
	elseif r == 'b' then
		config.clustduct["base"] = optarg
	elseif r == 'o' then
		config.clustduct["outdir"] = optarg
		config.clustduct["tftpdir"] = optarg
	elseif r == 'n' then
		node = optarg
	end
end

local nodes = handle:query("ip")
if node ~= nil then
	create_pxe_node_file(node,handle,config)
	create_grub_node_file(node,handle,config)
end
create_pxe_structure(handle,config)
create_grub_structure(handle,config)
