
MarkerCommands = {}
do
	function MarkerCommands:new()
		local obj = {}
		obj.commands = {} --{command=string, action=function}
		
		setmetatable(obj, self)
		self.__index = self
		
		obj:start()
		
		DependencyManager.register("MarkerCommands", obj)
		return obj
	end
	
	function MarkerCommands:addCommand(command, action, hasParam, state)
		table.insert(self.commands, {command = command, action = action, hasParam = hasParam, state = state})
	end
	
	function MarkerCommands:start()
		local markEditedEvent = {}
		markEditedEvent.context = self
		function markEditedEvent:onEvent(event)
			if event.id == 26 and event.text and (event.coalition == 1 or event.coalition == 2) then -- mark changed
				local success = false
				env.info('MarkerCommands - input: '..event.text)
				
				for i,v in ipairs(self.context.commands) do
					if (not v.hasParam) and event.text == v.command then
						success = v.action(event, nil, v.state)
						break
					elseif v.hasParam and event.text:find('^'..v.command..':') then
						local param = event.text:gsub('^'..v.command..':', '')
						success = v.action(event, param, v.state)
						break
					end
				end
				
				if success then
					trigger.action.removeMark(event.idx)
				end
			end
		end
		
		world.addEventHandler(markEditedEvent)
	end
end


