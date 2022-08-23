return function(file,DataStructure)
	local Variables = DataStructure
	if not isfolder('Tushub') then
		makefolder('Tushub')
	end 
	if not isfile(file) then
		writefile(file,'[]')
	end
	setmetatable(Variables,{
		__index = function(t,k,v)
			if not k then 
				return DataStructure
			else
				return DataStructure[k]
			end
		end,
		__newindex = function(t,k,v)
			DataStructure[k] = v

			--// Saving
			local get_data = game:service'HttpService':JSONDecode(readfile(file))
			for i,v in pairs(DataStructure) do
				get_data[i] = v
			end
			writefile(file, game:service'HttpService':JSONEncode(get_data))
		end,
	})

	local data_Get = game:GetService('HttpService'):JSONDecode(readfile(file))
	for i,v in pairs(DataStructure) do
		if not data_Get[i] then
			data_Get[i] = v
			writefile(file,game:GetService('HttpService'):JSONEncode(data_Get))
		else
			Variables[i] = v
		end
	end
	return Variables
end
