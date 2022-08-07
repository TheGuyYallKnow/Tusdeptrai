local function split(str)
	return string.split(tostring(str),'')
end
return function(str:string, str2:string)
	local get = split(str)
	local get2 = split(str2)
	local toreturn = true
	for i = 1,#str do
		if str[i] ~= str2[2] then
			toreturn = false
		end
	end
	return toreturn
end
