local lines = 0
local letters = 0 
for _, v in next, game:GetDescendants() do
	if v:IsA("BaseScript") then
		lines += #v.Source:split('\n')
		letters += #v.Source
	end
end
--print(string.format("Total Letters: %s", tostring(letters)))
print(string.format("Total Lines: %s", tostring(lines)))
