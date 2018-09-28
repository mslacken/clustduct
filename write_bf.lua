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
print("opened genders database "..config.clustduct["genders"].." with "..#handle:getnodes().." nodes")
-- parse commandline
getopt = require 'posix.unistd'.getopt
for r, optarg, optind in getopt(arg, 'hc:') do
	if r == '?' then
		return print('unrecognized option', arg[optind -1])
	end
	if r == 'h' then
		print '-h      print this help text'
		print '-c ARG  overwrite confdir'
	elseif r == 'c' then
		config.clustduct["confdir"] = optarg
	end
end


create_pxe_node_file("compute-01",handle,config)
print("Foo")
