-- From dphfox/tiniest, licenced under MIT
--!strict

export type Plugin = {
	is_tiniest_plugin: true
}

local tiniest_plugin = {}

function tiniest_plugin.configure(
	plugins: {any}?
)
	local self = {}

	function self.notify(
		method_name: string,
		...
	): ()
		if plugins == nil then
			return
		end
		for _, plugin in plugins do
			local method = plugin[method_name]
			if typeof(method) == "function" then
				coroutine.wrap(method)(...)
			end
		end
	end

	return self
end

return tiniest_plugin