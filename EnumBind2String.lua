local modules = {}

local tab = {
	MouseButton1 = 'LMB',
	MouseButton2 = 'RMB',
	MouseButton3 = 'MMB',
}

modules.E2S = function(en:Enum)
	if en then
		local give = string.split(tostring(en),'.')[3]
		if tab[tostring(give)] then
			give = tab[tostring(give)]
		end
		return give
	end
end

modules.S2E = function(str:string)
	if str then
		local get
		for i,v in pairs(tab) do
			if tostring(str) == tostring(v) then
				get = tostring(i)
			end
		end
		if not get then
			if Enum.KeyCode[str] then
				get = Enum.KeyCode[str]
			end
		else
			get = Enum.UserInputType[tostring(get)]
		end
		if get then
			return get
		end
	end
end

return modules
