#!/usr/bin/lua
g_db = require("genders")
require("bfcommons")
-- handle must be global
local cnf_filename = "/etc/clustduct.conf"
-- read the config
local config = {}
local cnf_file,err = loadfile(cnf_filename,"t",config)
if cnf_file then cnf_file() else print(err) end
if config.clustduct["confdir"]== nil then config.clustduct["confdir"]="/etc/clustduct.d/" end
config.clustduct["outdir"] = "/srv/tftpboot/clustduct"
config.clustduct["tftpdir"] = "/srv/tftpboot"
local handle = g_db.new(config.clustduct["genders"])
-- variables
local node = nil

-- parse commandline
getopt = require 'posix.unistd'.getopt
for r, optarg, optind in getopt(arg, 'hc:n:o:b:') do
	if r == '?' then
		return print('unrecognized option', arg[optind -1])
	end
	local base = 10
	if r == 'h' then
		print '-n      create config only for given and not all nodes'
		print '-h      print this help text'
		print '-o      overwrite output dir'
		print '-c ARG  overwrite confdir'
		return 0
	elseif r == 'c' then
		config.clustduct["confdir"] = optarg
	elseif r == 'b' then
		base = optarg
	elseif r == 'o' then
		config.clustduct["outdir"] = optarg
		config.clustduct["tftpdir"] = optarg
	elseif r == 'n' then
		node = optarg
	end
	config.clustduct["base"] = base
end

local nodes = handle:query("ip")
if node ~= nil then
	create_pxe_node_file(node,handle,config)
	create_grub_node_file(node,handle,config)
else
	create_pxe_structure(handle,config)
	create_grub_structure(handle,config)
end
