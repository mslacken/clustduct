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
-- common lua pxe/efi file functions is called from clustuct
-- and clustuctbf
function create_pxe_node_file(node,handle,config) 
	local file, err = io.open(config.clustduct["confdir"].."pxe_iptemplate","r")
	if not file then error(err) end
	local pxe_template = file:read("*a")
	file:close()
	-- now create boot entry table
	local entries = {} 
	local node_args = handle:getattr(node)
	pxe_template = string.gsub(pxe_template,"$NODE",node)	
	if node_args["ip"] ~= nil then 
		pxe_template = string.gsub(pxe_template,"$IP",node_args["ip"]) end
	if node_args["mac"] ~= nil then 
		pxe_template = string.gsub(pxe_template,"$MAC",node_args["mac"]) end
	if node_args["boot"] ~= nil then
		create_entry(node_args["boot"],entries,handle) end
	if node_args["install"] ~= nil then
		create_entry(node_args["install"],entries,handle) end
	local mand_entries = handle:query("mandatory")
	if mand_entries ~= nil then  
		for key,value in pairs(mand_entries) do
			create_entry(value,entries,handle)
		end
	end
	local sentr = ""
	for key,val in pairs(entries) do
		sentr = sentr.."LABEL "..key.."\n"
		if entries[key]["menu"] ~= nil then 
			sentr = sentr.."\tMENU LABEL "..entries[key]["menu"].."\n"
		else
			sentr = sentr.."\tMENU LABEL "..key.."\n"
		end
		if entries[key]["com32"] ~= nil then 
			sentr = sentr.."\tCOM32 "..entries[key]["com32"].."\n"
		end
		if entries[key]["kernel"] ~= nil then 
			sentr = sentr.."\tKERNEL "..entries[key]["kernel"].."\n"
		end
		if entries[key]["append"] ~= nil or entries[key]["initrd"] ~= nil then 
			sentr = sentr.."\tAPPEND "
			if entries[key]["append"] ~= nil then
				sentr = sentr..entries[key]["append"] end
			if entries[key]["initrd"] ~= nil then
				sentr = sentr..entries[key]["initrd"] end
		end
		for i = 0,100 do 
			local pxe_key = "pxe"..i
			if entries[key][pxe_key] ~= nil then
				sentr = sentr..entries[key][pxe_key].."\n" end
		end
		sentr = sentr.."\n"
	end
	pxe_template = string.gsub(pxe_template,"$ENTRY",sentr)	

	local ofile_name = config.clustduct["outdir"].."/"
	ofile_name = string.gsub(ofile_name,"//","/")
	ofile_name = ofile_name.."clustduct_node."..node..".pxe"
	if not file_exists(ofile_name) then
		local ofile, err = io.open(ofile_name,"w")
		if err ~= nil then
			error(err)
		end
		ofile:write(pxe_template)
	end
	if node_args["mac"] ~= nil then 
		local mac_filename = config.clustduct["tftpdir"].."/"
		mac_filename = string.gsub(mac_filename,"//","/")
		mac_filename = mac_filename.."default."..node_args["mac"]
		if not file_exists(mac_filename) then
			local mac_file_out = "KERNEL menu.c32\nAPPEND "..ofile_name
			local ofile, err = io.open(mac_filename,"w")
			if err ~= nil then
				error(err)
			end
			ofile:write(mac_file_out)
		end
	end
end

function create_grub_node_file(node,handle,config) 
	local file, err = io.open(config.clustduct["confdir"].."grub_iptemplate","r")
	if not file then error(err) end
	local grub_template = file:read("*a")
	file:close()
	-- now create boot entry table
	local entries = {} 
	local node_args = handle:getattr(node)
	grub_template = string.gsub(grub_template,"$NODE",node)	
	if node_args["ip"] ~= nil then 
		grub_template = string.gsub(grub_template,"$IP",node_args["ip"]) end
	if node_args["mac"] ~= nil then 
		grub_template = string.gsub(grub_template,"$MAC",node_args["mac"]) end
	if node_args["boot"] ~= nil then
		create_entry(node_args["boot"],entries,handle) end
	if node_args["install"] ~= nil then
		create_entry(node_args["install"],entries,handle) end
	local mand_entries = handle:query("mandatory")
	if mand_entries ~= nil then  
		for key,value in pairs(mand_entries) do
			create_entry(value,entries,handle)
		end
	end
	local sentr = ""
	for key,val in pairs(entries) do
		sentr = sentr.."menuentr "..key
		if entries[key]["menu"] ~= nil then 
			sentr = sentr.."'"..entries[key]["menu"].."' {\n"
		else
			sentr = sentr.."'"..key.."' {\n"
		end
		if entries[key]["kernel"] ~= nil then 
			sentr = sentr.."\tlinuxefi "..entries[key]["kernel"] end
		if entries[key]["linuxefi"] ~= nil then 
			sentr = sentr.."\tlinuxefi "..entries[key]["linuxefi"] end
		if entries[key]["append"] ~= nil and 
			(entries[key]["kernel"] ~= nil or entries[key]["linuxefi"] ~= nil ) then
			sentr = sentr.." "..entries[key]["append"].."\n" end
		if entries[key]["initrd"] ~= nil then
			sentr = sentr.."\tinitrdefi "..entries[key]["initrd"].."\n" end
		if entries[key]["initrdefi"] ~= nil then
			sentr = sentr.."\tinitrdefi "..entries[key]["initrdefi"].."\n" end
		if entries[key]["set"] ~= nil then
			sentr = sentr.."\tset "..entries[key]["set"].."\n" end
		if entries[key]["chainloader"] ~= nil then
			sentr = sentr.."\tchainloader"..entries[key]["chainloader"].."\n" end
		if entries[key]["grub"] ~= nil then
			sentr = sentr..entries[key]["grub"].."\n" end
		for i = 0,100 do 
			local grub_key = "grub"..i
			if entries[key][grub_key] ~= nil then
				sentr = sentr..entries[key][grub_key].."\n" end
		end
		sentr = sentr.."\n}\n"
	end
	grub_template = string.gsub(grub_template,"$ENTRY",sentr)	

	local ofile_name = config.clustduct["outdir"].."/"
	ofile_name = string.gsub(ofile_name,"//","/")
	ofile_name = ofile_name.."clustduct_node."..node..".grub"
	if not file_exists(ofile_name) then
		local ofile, err = io.open(ofile_name,"w")
		if err ~= nil then
			error(err)
		end
		ofile:write(grub_template)
	end
	local ip_filename = config.clustduct["outdir"].."/"
	ip_filename = string.gsub(ip_filename,"//","/")
	ip_filename = ip_filename.."grub.cfg."..node_args["ip"]
	if not file_exists(ip_filename) then
		local ip_file_out = "configfile "..ofile_name
		local ofile, err = io.open(ip_filename,"w")
		if err ~= nil then
			error(err)
		end
		ofile:write(ip_file_out)
	end

end

function create_pxe_structure(handle,config)
	local incrementcount=0
	local nodes = handle:query("ip")
	-- nr_nodes=$(nodeattr -f $GENDERSFILE -n ip | wc -l)
	-- base=${BASE:-10}
	local exponent = math.floor(math.log(#nodes)/math.log(config.clustduct["base"]))
	local counter=1
	local level=0
	local i=1
	local output_str = ""
	-- clean up preexisting entries
	local ofile_name = config.clustduct["outdir"].."/"
	ofile_name = string.gsub(ofile_name,"//","/")
	ofile_name = ofile_name.."nodes.pxe"
	if file_exists(ofile_name) then return end
	for key, node in pairs(nodes)  do
		if counter == 1  then
			local i_inc = i - 1
			for n = 1, exponent  do
				local modulo = i_inc%(config.clustduct["base"]^n)
				if modulo == 0  then
					output_str = output_str.."MENU BEGIN list_"..node.."\nMENU LABEL Boot "..node.." to ENDNODE\n"
					level = level+1
				end
			end
		end	
		-- to pxe menu structure
		output_str = output_str.."LABEL "..node.."\n\tMENU LABEL Boot as node "..node.."\n\tKERNEL menu.c32\n\tAPPEND "..config.clustduct["outdir"].."/clustduct_node."..node..".grub\n"
		-- to the node file
		create_pxe_node_file(node,handle,config) 
		if counter == config.clustduct["base"]  then
			for n = 1, exponent do
				local modulo = i%(config.clustduct["base"]^n)
				if modulo == 0 then
					output_str = output_str.."LABEL go_back\n\tMENU LABEL Go back...\n\tMENU EXIT\nMENU END"
					output_str = string.gsub(output_str,"ENDNODE",node)

					level = level - 1
				end
			end
		end
		if counter < config.clustduct["base"]  then
			counter = counter + 1
		else
			counter = 1
		end
		i = i + 1
	end
	for n = 1, level do
		output_str = output_str.."LABEL go_back\n\tMENU LABEL Go back...\n\tMENU EXIT\n\tMENU END\n"
	end
	output_str = output_str.."LABEL go_back\n\tMENU LABEL Go back...\n\tKERNEL menu.c32\n\tAPPEND ~\n"
	if not file_exists(ofile_name) then
		local ofile, err = io.open(ofile_name,"w")
		if err ~= nil then
			error(err)
		end
		ofile:write(output_str)
	end

end

function create_grub_structure(handle,config)

end

function clean_genders(table)
	for key,value in pairs(table) do 
		local t_str = value
		t_str = string.gsub(t_str,"\\ws"," ")
		t_str = string.gsub(t_str,"\\eq","=")
		table[key] = t_str
	end
end

function create_entry(entry,entries,handle)
	-- avoid double entries
	if entries[entry] ~= nil then return end
	local boot_args = handle:getattr(entry)
	if boot_args ~= nil then 
		-- do the pattern substiutions like \eq -> = here
		clean_genders(boot_args)
		entries[entry] = boot_args
	end

end

function file_exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end
