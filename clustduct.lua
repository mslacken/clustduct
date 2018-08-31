-- handle must be global
handle = nil
cnf_filename = "/etc/dnsmasq.d/clustduct"
-- read the config
config = {}
cnf_file = loadfile(cnf_filename,"t",config)
if cnf_file then
	print("found config file "..cnf_filename)
	cnf_file()
else
	-- no config file found
	print("no config file found")
	config["clustduct"] = {}
	config.clustduct["ethers"]="/etc/ethers"
end
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
function update_ether(ip_address,mac_address) 
	print("will manipulate file "..config.clustduct["ethers"])
end
function init() 
	g_db = require("genders")
	print("init was called")
	db_file="/etc/genders"
	handle=g_db.new(db_file)
	print("opened genders database "..db_file.." with "..#handle:getnodes().." nodes")
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
		end
	elseif action == "add" then
		print("in add tree")
		-- query genders for mac
		local node=handle:query("mac="..args["mac_address"])
		if node~= nil and #node == 1 then
			print("found node "..node[1].." with mac="..args["mac_address"])
		end

	else
		print("unknown action "..action.." doing nothing")
	end
end

function tftp(action,args)
	print("tftp was called with "..action)
	tprint(args)
end

