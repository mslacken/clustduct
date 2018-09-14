#!/usr/bin/lua
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

db_file = "/etc/genders"
g_db = require("genders")
handle = g_db.new(db_file)
print("opened genders database "..db_file.." with " ..#handle:getnodes().." nodes")
query = handle:query("~ip")
tprint(query)
nodes = handle:query("ip")
for index,node in pairs(nodes) do
	print(index.." "..node)
end

