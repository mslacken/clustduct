-- handle must be global
handle = nil
cnf_filename = "/etc/clustduct.conf"
need_signal = false
-- read the config
config = {}
-- simple print function for tables
function tprint (t, s)
    for k, v in pairs(t) do
        local kfmt = '["' .. tostring(k) ..'"]'
        if type(k) ~= 'string' then
            kfmt = '[' .. k .. ']'
        end
        local vfmt = '"'.. tostring(v) ..'"'
        if type(v) == 'table' then
            tprint(v, (s or '')..kfmt)
        else
            if type(v) ~= 'string' then
                vfmt = tostring(v)
            end
            print(type(t)..(s or '')..kfmt..' = '..vfmt)
        end
    end
end

-- update given file with the line first_arg.." "..second_arg
-- but checks if string is present in file
-- also the variable need_signal is set to true if the file is modified

function update_file(first_arg,second_arg,filename) 
	-- print("will manipulate file "..config.clustduct["ethers"])
	local file = io.open(filename,"r")
	if not file then error("could not open file "..filename) end
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
	file:write(node.." "..attr)
	file:close()
end

function send_signal()
	if need_signal then
		-- print("sending SIGHUP to dnsmasq")
		os.execute("pkill --signal SIGHUP dnsmasq")
		need_signal = false
	end
end

-- following functions must be present for a working together with dnsmasq
function init() 
	g_db = require("genders")
	print("init was called")
	local cnf_file,err = loadfile(cnf_filename,"t",config)
	if cnf_file then
		print("found config file "..cnf_filename)
		cnf_file()
	else
		-- no config file found
		print(err)
		config["clustduct"] = {}
		config.clustduct["ethers"]="/etc/ethers"
		config.clustduct["hosts"]="/etc/hosts"
		config.clustduct["genders"]="/etc/genders"
		config.clustduct["linear_add"]=true
	end
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
			if node ~= nil then 
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
end

