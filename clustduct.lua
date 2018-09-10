-- handle must be global
handle = nil
cnf_filename = "/etc/dnsmasq.d/clustduct"
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

-- update the ethers file with ip and mac
function update_ether(mac_address,ip_address) 
	print("will manipulate file "..config.clustduct["ethers"])
	local file = io.open(config.clustduct["ethers"],"r")
	if not file then error("could not open file "..config.clustduct["ethers"]) end
	local file_content = file:read("*a")
	file:close()
	-- search for mac_address and ip_address
	local ip_pos = string.find(file_content,"%g+%s+"..ip_address)
	local mac_pos = string.find(file_content,mac_address.."%s+%g+")
--	if not ip_pos and not mac_pos then
--		-- add ip and mac if not found
--		print("will add mac "..mac_address.." and ip "..ip_address)
--		file = io.open(config.clustduct["ethers"],"a")
--		file:write(mac_address.." "..ip_address)
--		file:flush()
--		file:close()
	if ip_pos then
		file_content = string.gsub(file_content,"%g+%s+"..ip_address.."\n","")
		print("found ip, content is now [snip]\n"..file_content.."\n[snap]")
	elseif mac_pos then
		file_content = string.gsub(file_content,mac_address.."%s+%g+\n","")
		print("found mac, content is now [snip]\n"..file_content.."\n[snap]")
	else 
		print("did no find mac or ip content was\n"..file_content.."\n[snap]")
	end
	file = io.open(config.clustduct["ethers"],"w")
	file_content=file_content..mac_address.." "..ip_address.."\n"
	file:write(file_content)
	file:close()
end

-- is called at startup
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
	end
	db_file="/etc/genders"
	handle=g_db.new(db_file)
	print("opened genders database "..db_file.." with "..#handle:getnodes().." nodes")
	if config.clustduct["linear_add"] then print("will add nodes linear") else print("do nothing with new nodes") end
	print("end init")
end

function shutdown() 
	print("shutdown was called")
end

function lease(action,args) 
	print("lease was called with action "..action)
	tprint(args)
	if action == "old" then
		print("in old tree")
		local node=handle:query("mac="..args["mac_address"])
		if node~= nil and #node == 1 then
			print("found node "..node[1].." with mac="..args["mac_address"])
			update_ether(args["mac_address"],args["ip_address"])
		else
			print("node with mac "..args["mac_address"].." is not known to genders")
			update_ether(args["mac_address"],args["ip_address"])
		end
	elseif action == "add" then
		print("in add tree")
		-- query genders for mac
		local node=handle:query("mac="..args["mac_address"])
		if node~= nil and #node == 1 then
			print("found node "..node[1].." with mac="..args["mac_address"])
			update_ether(args["mac_address"],args["ip_address"])
		else
			print("node with mac "..args["mac_address"].." is not known to genders")
			update_ether(args["mac_address"],args["ip_address"])
		end

	elseif action == "del" then
		print("in del, but do not care about vanished leases")
	else
		print("unknown action "..action.." doing nothing")
	end
end

function tftp(action,args)
	print("tftp was called with "..action)
	tprint(args)
end

