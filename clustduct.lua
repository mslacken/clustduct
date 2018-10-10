-- handle must be global
handle = nil
cnf_filename = "/etc/clustduct.conf"
need_signal = false
-- read the config
local config = {}

-- update given file with the line first_arg.." "..second_arg
-- but checks if string is present in file
-- also the variable need_signal is set to true if the file is modified

function update_file(first_arg,second_arg,filename) 
	-- print("will manipulate file "..config.clustduct["ethers"])
	local file, err = io.open(filename,"r")
	if not file then error(err) end
	local file_content = file:read("*a")
	file:close()
	-- escape as the search args could have magical characted like -
	ff_arg = string.gsub(first_arg,"(%W)","%%%1")
	sf_arg = string.gsub(second_arg,"(%W)","%%%1")
	-- look if we allready got the right string
	if string.find(file_content,ff_arg.." "..sf_arg) then
		return
	end
	need_signal = true
	-- search for first_arg and second_arg
	local first_pos = string.find(file_content,ff_arg.."%s+%g+")
	local second_pos = string.find(file_content,"%g+%s+"..sf_arg)
	if first_pos then
		file_content = string.gsub(file_content,ff_arg.."[%g%s]+\n","")
		-- print("found ip, content is now [snip]\n"..file_content.."\n[snap]")
	elseif second_pos then
		file_content = string.gsub(file_content,"%g+%s+"..sf_arg,"")
		-- print("found mac, content is now [snip]\n"..file_content.."\n[snap]")
	end
	file = io.open(filename,"w")
	file_content=file_content..first_arg.." "..second_arg.."\n"
	file:write(file_content)
	file:close()
end

function update_db(node, attr)
	local db_file = config.clustduct["genders"]
	local file = io.open(db_file,"a")
	if not file then error("could not open file "..db_file) end
	file:write("\n"..node.." "..attr)
	file:close()
	need_signal = true
end

function send_signal()
	if need_signal then
		-- print("sending SIGHUP to dnsmasq")
		os.execute("pkill --signal SIGHUP dnsmasq")
		need_signal = false
	end
end

function allowfromhost(node)
	local node_attrs = handle:getattr(node)
	-- should not happen but be sure
	if node_attrs == nil then return false end
	if node_attrs["block"] then 
		return false
	else
		return true
	end
	return false
end

-- following functions must be present for a working together with dnsmasq
function init() 
	g_db = require("genders")
	require("bfcommons")
	print("init was called")
	local cnf_file,err = loadfile(cnf_filename,"t",config)
	-- initialize with defaults
	if cnf_file then
		print("found config file "..cnf_filename)
		cnf_file()
	else
		-- no config file found
		print(err)
	end
	if config["clustduct"] == nil then config["clustduct"] = {} end
	if config.clustduct["ethers"] == nil then config.clustduct["ethers"]="/etc/ethers" end
	if config.clustduct["hosts"] == nil then config.clustduct["hosts"]="/etc/hosts"  end
	if config.clustduct["genders"] == nil then config.clustduct["genders"]="/etc/genders"  end
	if config.clustduct["linear_add"] == nil then config.clustduct["linear_add"]=false  end
	if config.clustduct["confdir"] == nil then config.clustduct["confdir"]="/etc/clustduct.d/"  end
	if config.clustduct["outdir"]  == nil then config.clustduct["outdir"] = "/srv/tftpboot/clustduct" end
	if config.clustduct["tftpdir"]  == nil then config.clustduct["tftpdir"] = "/srv/tftpboot" end
	if config.clustduct["netclass"]  == nil then config.clustduct["netclass"] = "01" end
	handle = g_db.new(config.clustduct["genders"])
	print("opened genders database "..config.clustduct["genders"].." with "..#handle:getnodes().." nodes")
	-- will update hosts file now
	nodes = handle:query("ip")
	for index,node in pairs(nodes) do
		local node_attrs = handle:getattr(node)
		local node_names = node
		if config.clustduct["domain"] then
			node_names = node.."."..config.clustduct["domain"].." "..node
		end
		update_file(node_attrs["ip"],node_names,config.clustduct["hosts"])
	end	
	send_signal()
	if config.clustduct["linear_add"] then print("will add nodes linear") else print("do nothing with new nodes") end
	print("end init")
end

function shutdown() 
	print("shutdown was called")
end

function lease(action,args) 
	print("lease was called with action "..action)
	if action == "old" then
		print("in old tree")
		local node=handle:query("mac="..args["mac_address"])
		if node~= nil and #node == 1 then
			-- found node in genders, update ethers/hosts
			local node_attrs = handle:getattr(node[1])
			print("found node "..node[1].." with mac="..args["mac_address"].." updating hosts and ethers")
			local node_names = node[1]
			if config.clustduct["domain"] then
				node_names = node[1].."."..config.clustduct["domain"].." "..node[1]
			end
			update_file(node_attrs["ip"],node_names,config.clustduct["hosts"])
			update_file(node_attrs["mac"],node_attrs["ip"],config.clustduct["ethers"])
			print(type(node[1]),type(handle),type(config))
			create_pxe_node_file(node[1],handle,config) 
			create_grub_node_file(node[1],handle,config) 
			-- hosts/ethers is reread after signal is sned
			send_signal()
		else
			print("node with mac "..args["mac_address"].." is not known to genders")
		end
	elseif action == "add" then
		print("in add tree")
		-- query genders for mac
		local node = handle:query("mac="..args["mac_address"])
		if node~= nil and #node == 1 then
			-- found node in genders, update ethers/hosts
			local node_attrs = handle:getattr(node[1])
			print("found node "..node[1].." with mac="..args["mac_address"].." updating hosts and ethers")
			local node_names = node[1]
			if config.clustduct["domain"] then
				node_names = node[1].."."..config.clustduct["domain"].." "..node[1]
			end
			update_file(node_attrs["ip"],node_names,config.clustduct["hosts"])
			update_file(node_attrs["mac"],node_attrs["ip"],config.clustduct["ethers"])
			-- hosts/ethers is reread after signal is sned
			send_signal()
		elseif config.clustduct["linear_add"] then
			-- add the new node to genders, update ethers/hosts
			local node = handle:query("~mac&&ip")
			if #node >= 1 then 
				print("add node with mac "..args["mac_address"].." as "..node[1])
				local node_attr = handle:getattr(node[1])
				update_db(node[1],"mac="..args["mac_address"])
				-- reload handle
				handle:reload(config.clustduct["genders"])
				local node_names = node[1]
				if config.clustduct["domain"] then
					node_names = node[1].."."..config.clustduct["domain"].." "..node[1]
				end
				update_file(node_attr["ip"],node_names,config.clustduct["hosts"])
				update_file(args["mac_address"],node_attr["ip"],config.clustduct["ethers"])
				create_pxe_node_file(node[1],handle,config) 
				create_grub_node_file(node[1],handle,config) 
				-- hosts/ethers is reread after signal is sned
				send_signal()
			end
		end

	elseif action == "del" then
		print("in del, but do not care about vanished leases")
	else
		print("unknown action "..action.." doing nothing")
	end
end

function tftp(action,args)
	print("tftp was called with "..action)
	-- check if node specific config was selected, which may called from other ip
	-- we can always return as installation is always done with node specific file
	local nodefromfile = string.match(args["file_name"],"%g+/clustduct_node.(%g+).pxe")
	if nodefromfile == nil then return end
	print("This is node "..nodefromfile)
	-- check for valid nodename
	if not handle:isnode(nodefromfile) then return end
	-- check if ip is in database
	local node = handle:query("ip="..args["destination_address"])
	if node == nil or node ~= nodefromfile then
		print("Will set ip="..args["destination_address"].." to "..nodefromfile)
		if not allowfromhost(nodefromfile) then return end
		-- read adress from the arp table
		local shellhandle = io.popen("ip neigh show "..args["destination_address"])
		local shellresult = shellhandle:read("*a")
		shellhandle:close()
		-- 
		local mac = string.match(shellresult,"%g+%s%g+%s%g+%s%g+%s(%g+)%s%g+")
		if mac ~= nil then
			-- just update the mac in genders, the rest will be handled by old
			update_db(nodefromfile,"mac="..mac)
			handle:reload(config.clustduct["genders"])
			send_signal()
			return 
		end
	end
	if #node == 1 then
		local node_attrs = handle:getattr(node[1])
		-- check if boot exists and return, check for install=$IMAGE
		-- afterwards, so that the boot preceeds the install
		-- after installation the boot=local may be added, ram only
		-- installation will only provide a boot
		-- for reinstalltion the boot entry must be removed
		-- check if node has boot entry
		if node_attrs["boot"] ~= nil then return end
		-- also do nothing if install was node defined
		if node_attrs["install"] == nil then return end
		-- check if the install entry is valid
		if not handle:isnode(node_attrs["install"]) then return end
		-- check is we have trigger
		local install_attr = handle:getattr(node_attrs["install"])
		if install_attr == nil then return end
		if install_attr["trigger"] == nil then return end
		-- check if trigger is in the transfered file
		if args["file_name"] ~= nil then
			local ftrigger = string.gsub(install_attr["trigger"],"(%W)","%%%1")
			if string.find(args["file_name"],"%g*"..ftrigger.."%g*") and install_attr["nextboot"] ~= nil then
				print("trigger "..install_attr["trigger"].." setting "..node[1].." boot="..install_attr["nextboot"])
				update_db(node[1],"boot="..install_attr["nextboot"])
			end
		end
	end
end

