
Preset = {}
do
    function Preset:new(obj)
		setmetatable(obj, self)
		self.__index = self
		return obj
    end

	function Preset:extend(new)
		return Preset:new(Utils.merge(self, new))
	end
end

