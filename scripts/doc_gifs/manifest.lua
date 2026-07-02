local targets = require("doc_gifs.examples")

local Manifest = {}

function Manifest.targets()
	return targets
end

function Manifest.find(id)
	for _, item in ipairs(targets) do
		if item.id == id then
			return item
		end
	end
	return nil
end

return Manifest
