#!/usr/bin/lua
need_signal = false
ethers = {}
unknown_macs = {}
unknown_macs_filename = "/srv/pillar/clustuct/unknown_macs"

function send_signal()
	if need_signal then
		-- print("clustduct: sending SIGHUP to dnsmasq")
		os.execute("pkill --signal SIGHUP dnsmasq")
		need_signal = false
	end
end


function string:split(sSeparator, nMax, bRegexp)
    if sSeparator == '' then
        sSeparator = ','
    end

    if nMax and nMax < 1 then
        nMax = nil
    end

    local aRecord = {}

    if self:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1
        
        local nField, nStart = 1, 1
        local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = self:sub(nStart, nFirst-1)
            nField = nField+1
            nStart = nLast+1
            nFirst,nLast = self:find(sSeparator, nStart, bPlain)
            nMax = nMax-1
        end
        aRecord[nField] = self:sub(nStart)
    end

    return aRecord
end

function read_csv(path,sep,comment,tonum, null)
    tonum = tonum or true
    sep = sep or ','
    null = null or ''
    comment = comment or '#'
    local csvFile = {}
    local file = io.open(path, "r")
    if file == nil then
      return {}
    end
    for line in file:lines() do
        local pos_com = line:find(comment)
        if pos_com ~= nil then
          line = line:sub(1,pos_com)
        end
        if line:len() > 1 then
          fields = line:split(sep,2,true)
          if tonum then -- convert numeric fields to numbers
              for i=1,#fields do
                  local field = fields[i]
                  if field == '' then
                      field = null
                  end
                  fields[i] = tonumber(field) or field
              end
            end
          if fields ~= nil and fields[1] ~= nil then
            if fields[2] ~= nil then
              fields[1] = fields[2]
            else
              fields[1] = 1
            end
          end
        end
    end
    file:close()
    return csvFile
end

function write_csv(path, data, sep)
    sep = sep or ','
    local file = assert(io.open(path, "w"))
    for i=1,#data do
        for j=1,#data[i] do
            if j>1 then file:write(sep) end
            file:write(data[i][j])
        end
        file:write('\n')
    end
    file:close()
end

-- following functions must be present for a working together with dnsmasq
function init() 
	print("clustduct: end init "..os.date("%H:%M:%S_%d.%m.%y"))
  ethers = read_csv("/etc/hosts","%s+",'#')
  unknown_macs = read_csv(unknown_macs_filename,"%s+",'#')
end

function shutdown()
	print("clustduct: shutdown was called")
end

function lease(action,args)
	print("clustduct: lease was called with action "..action)
	if action == "old" then
		print("clustduct: in old tree")
    -- Find mac address either in ethers or in unknown_macs, if
    -- not add it to unknown_macs, other actions have to be triggered
    -- by admin
    if ethers[args["mac_address"]] == nil or unknown_macs[args["mac_address"]] == nil then
      ethers[args["mac_address"]] = os.date("%H:%M:%S_%d.%m.%y")
      local file = assert(io.open(path, "a"))
      file:write(ethers[args["mac_address"]]..' '..os.date("%H:%M:%S_%d.%m.%y"))
      file:close()
    end
  end
end

function tftp(action,args)
	print("clustduct: tftp was called with:")
end


require("bfcommons")
init()
