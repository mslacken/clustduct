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
		create_entry(node_args["boot"],entries) end
	if node_args["install"] ~= nil then
		create_entry(node_args["install"],entries) end
	local mand_entries = handle:query("mandatory")
	if mand_entries ~= nil then  
		for key,value in pairs(mand_entries) do
			create_entry(value,entries)
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
		for i in 0..100 do 
			local pxe_key = "pxe"..i
			if entries[key][pxe_key] ~= nil then
				sentr = sentr..entries[key][pxe_key].."\n" end
		end
		sentr = sentr.."\n"
	end
	pxe_template = string.gsub(pxe_template,"$ENTRY",sentr)	

	print(pxe_template)

end

function create_pxe_grub_file(node,handle,config) 
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
		create_entry(node_args["boot"],entries) end
	if node_args["install"] ~= nil then
		create_entry(node_args["install"],entries) end
	local mand_entries = handle:query("mandatory")
	if mand_entries ~= nil then  
		for key,value in pairs(mand_entries) do
			create_entry(value,entries)
		end
	end
	local sentr = ""
	for key,val in pairs(entries) do
		sentr = sentr.."menuentry"..key.."\n"
		if entries[key]["menu"] ~= nil then 
			sentr = sentr.."'"..entries[key]["menu"].."' {"
		else
			sentr = sentr.."'"..entries[key]["menu"].."' {"
			sentr = sentr.."'"..key.."' {"
		end
		if entries[key]["kernel"] ~= nil then 
			sentr = sentr.."\tlinuxefi "..entries[key]["kernel"].."\n" end
		if entries[key]["linuxefi"] ~= nil then 
			sentr = sentr.."\tlinuxefi "..entries[key]["linuxefi"].."\n" end
		if entries[key]["append"] ~= nil then
			sentr = sentr.." "..entries[key]["append"].."\n" end
		if entries[key]["initrd"] ~= nil then
			sentr = "initrdefi "..sentr..entries[key]["initrd"].."\n" end
		if entries[key]["initrdefi"] ~= nil then
			sentr = "initrdefi "..sentr..entries[key]["initrdefi"].."\n" end
		if entries[key]["set"] ~= nil then
			sentr = "set"..sentr..entries[key]["set"].."\n" end
		if entries[key]["chainloader"] ~= nil then
			sentr = "chainloader"..sentr..entries[key]["chainloader"].."\n" end
		if entries[key]["grub"] ~= nil then
			sentr = sentr..entries[key]["grub"].."\n" end
		for i in 0..100 do 
			local grub_key = "grub"..i
			if entries[key][grub_key] ~= nil then
				sentr = sentr..entries[key][grub_key].."\n" end
		end
		sentr = sentr.."\n}\n"
	end
	grub_template = string.gsub(grub_template,"$ENTRY",sentr)	

	print(grub_template)

end

function create_pxe_structure(handle,config)

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

function create_entry(entry,entries)
	-- avoid double entries
	if entries[entry] ~= nil then return end
	print("creating attr for entry "..entry)
	local boot_args = handle:getattr(entry)
	if boot_args ~= nil then 
		-- do the pattern substiutions like \eq -> = here
		clean_genders(boot_args)
		entries[entry] = boot_args
	end

end
