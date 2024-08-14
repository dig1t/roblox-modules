--[=[
Utility functions for working with React.

@class ReactUtil
]=]

--!native

local ApiDumpStatic =
	require(script.Parent.ApiDumpStatic) :: { Classes: { [string]: any } }

export type ReactElement<P = { [string]: any }, T = any> = {
	["$$typeof"]: number,

	type: T,
	key: string | number | nil,
	ref: any,
	props: P,
}

export type React = {
	createElement: <P, T>(
		type: T,
		props: P,
		children: ReactChildren
	) -> ReactElement<P, T>,
	Fragment: ReactElement<{}>,
}

export type ReactChildren =
	{ [string]: ReactElement<any, any> }
	| ReactElement<any, any>
	| nil

export type Props = { [any]: any }?

local DISALLOWED_PROPS = { "Parent", "Transparency", "Name", "ClassName" }

local function getPropertiesFromInstance(instance: Instance): { [any]: any }
	assert(typeof(instance) == "Instance", "Expected an instance")

	local api = ApiDumpStatic.Classes[instance.ClassName]
	assert(api, "Unknown instance type '" .. instance.ClassName .. "'")

	local properties = {}

	for name, info in pairs(api:Properties()) do
		-- Ignore disallowed props and props that can't be set in Studio
		if
			not table.find(DISALLOWED_PROPS, name)
			and ((info.Security :: any) == "None" or (info.Security.Read == "None" and info.Security.Write == "None"))
			and not (
				info.Tags
				and (
					table.find(info.Tags, "NotScriptable")
					or table.find(info.Tags, "ReadOnly")
				)
			)
		then
			pcall(function()
				local prop = (instance :: any)[name]

				if prop ~= api:GetPropertyDefault(name) then
					properties[name] = prop
				end
			end)
		end
	end

	return properties
end

local function mergeInto(into: { [any]: any }, from: { [any]: any }?): { [any]: any }
	if not from then
		return into
	end

	for key, value in pairs(from) do
		into[key] = value
	end

	return into
end

local function buildInstanceTree(
	React: React,
	instance: Instance,
	props: Props,
	children: ReactChildren
): ReactElement<any, any>
	assert(typeof(instance) == "Instance", "Expected an instance")

	local instanceChildren = {}

	for _, child in instance:GetChildren() do
		instanceChildren[child.Name] = buildInstanceTree(React, child)
	end

	if children then
		mergeInto(instanceChildren, children)
	end

	local element = React.createElement(
		instance.ClassName,
		mergeInto(getPropertiesFromInstance(instance), props),
		instanceChildren
	)

	return element
end

local ReactUtil = {}

--[=[
Hydrates an instance with React.

Uses snippets from [RoactTemplate](https://github.com/Corecii/roact-template) to be made compatible with React.

```lua
local React = require(game.ReplicatedStorage.Packages.React)
local ReactUtil = require(game.ReplicatedStorage.Packages.ReactUtil)

local template = game.ReplicatedStorage.TextBox

local component(props: { [any]: any })
	return ReactUtil.Hydrate(React, {
		Text = "Hello World!",
		TextScaled = true,
	}, {
		Child = React.createElement("UITextSizeConstraint", {
			MinTextSize = 20,
			MaxTextSize = 40,
		})
	})
end

return component
```

@param React React -- The React object.
@param instance Instance -- The instance to hydrate.
@param props { [any]: any } -- The element props.
@param children ReactChildren -- The children to set on the instance.
]=]
function ReactUtil.Hydrate(
	React: any,
	instance: Instance,
	props: Props,
	children: any?
): ReactElement<{}, any>
	assert(typeof(instance) == "Instance", "Expected an instance")
	assert(typeof(props) == "table" or props == nil, "Expected a table for props")

	local _react: React = React
	local _children: ReactChildren = children

	local element = React.createElement(
		_react.Fragment,
		{},
		buildInstanceTree(_react, instance, props, _children)
	)

	return element
end

return ReactUtil
