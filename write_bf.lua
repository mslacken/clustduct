#!/usr/bin/lua
g_db = require("genders")
require("bfcommons")
-- handle must be global
cnf_filename = "/etc/clustduct.conf"
-- read the config
config = {}
cnf_file,err = loadfile(cnf_filename,"t",config)
if cnf_file then
	print("found config file "..cnf_filename)
	cnf_file()
else print(err) end
if config.clustduct["confdir"]==nil then config.clustduct["confdir"]="/etc/clustduct.d/" end
handle = g_db.new(config.clustduct["genders"])
-- variables
node = nil

-- parse commandline
getopt = require 'posix.unistd'.getopt
for r, optarg, optind in getopt(arg, 'hc:n:o:') do
	if r == '?' then
		return print('unrecognized option', arg[optind -1])
	end
	if r == 'h' then
		print '-n      create config only for given and not all nodes'
		print '-h      print this help text'
		print '-o      overwrite output dir'
		print '-c ARG  overwrite confdir'
	elseif r == 'c' then
		config.clustduct["confdir"] = optarg
	elseif r == 'o' then
		config.clustduct["outdir"] = optarg
		config.clustduct["tftpdir"] = optarg
	elseif r == 'n' then
		node = optarg
	end
end

nodes = handle:query("ip")
if node ~= nil then
	create_pxe_node_file(node,handle,config)
	create_grub_node_file(node,handle,config)
else
	for ntale,node in pairs(nodes) do 
		create_pxe_node_file(node,handle,config)
		create_grub_node_file(node,handle,config)
	end
end
