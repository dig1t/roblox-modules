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
	useRef: <T>(initialValue: T) -> { current: T },
	Fragment: ReactElement<{}>,
}

export type ReactChildren =
	{ [string]: ReactElement<any, any> }
	| ReactElement<any, any>
	| nil

export type Props = { [any]: any }?

local React: React

-- Search for the React module automatically
-- If React is not found, it will have to be set manually using ReactUtil.locateReact(React)
if script.Parent and script.Parent.Parent and script.Parent.Parent.Parent then
	React = script.Parent.Parent.Parent:FindFirstChild("React")

	if not React then
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Packages = ReplicatedStorage:FindFirstChild("Packages")

		if Packages then
			React = Packages:FindFirstChild("React", true)
		else
			-- Recursively search for the package folder
			local _Index = ReplicatedStorage:FindFirstChild("_Index", true)
			local _IndexPackages = _Index and _Index.Parent

			React = _IndexPackages and _IndexPackages:FindFirstChild("React", true)
		end
	end
end

if React then
	React = require(React) :: React
end

local REACT_NOT_FOUND =
	"React module not found. Set it using ReactUtil.locateReact(React)"

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

local function mergeInto(into: { [any]: any }, from: { { [any]: any } }?): { [any]: any }
	if not from then
		return into
	end

	for _, value in pairs(from) do
		for k, v in pairs(value) do
			into[k] = v
		end
	end

	return into
end

local function buildInstanceTree(
	instance: Instance,
	props: Props,
	children: ReactChildren,
	refs: any
): ReactElement<any, any>
	assert(typeof(instance) == "Instance", "Expected an instance")

	local instanceChildren = {}

	refs[instance.Name] = {}

	for _, child in instance:GetChildren() do
		instanceChildren[child.Name] =
			buildInstanceTree(child, nil, nil, refs[instance.Name])
	end

	if children then
		mergeInto(instanceChildren, { children })
	end

	local ref = React.useRef(nil)

	local element = React.createElement(
		instance.ClassName,
		mergeInto(
			getPropertiesFromInstance(instance),
			{ props or {}, {
				ref = ref,
			} }
		),
		instanceChildren
	)

	refs[instance.Name]["$$root"] = element

	return element
end

local ReactUtil = {}

--[=[
Sets the React module to be used by ReactUtil.

This can be set anywhere in your codebase, but it is recommended to set it in a single location such as your main module.

```lua
local React = require(Location.To.React)
local ReactUtil = require(game.ReplicatedStorage.Packages.ReactUtil)

ReactUtil.locateReact(React)
```

@param react React -- The React module to use
]=]
function ReactUtil.locateReact(react: React)
	assert(react, "Expected a React module")

	React = react
end

local Util = require(script.Parent.Parent.Parent.Util)

type RefNode = {
	["$$root"]: ReactElement<{}, any>,
	[string]: RefNode,
}

--[=[
Hydrates an instance with React.

Uses snippets from [RoactTemplate](https://github.com/Corecii/roact-template) to be made compatible with React.

```lua
local React = require(game.ReplicatedStorage.Packages.React)
local ReactUtil = require(game.ReplicatedStorage.Packages.ReactUtil)

local template = game.ReplicatedStorage.TextBox

local component(props: { [any]: any })
	return ReactUtil.Hydrate(template, {
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

@param instance Instance -- The instance to hydrate
@param props { [any]: any } -- The element props
@param children ReactChildren -- The children to set on the instance
@return () -> ReactElement<{}, any> -- The hydrated element as a functional component
]=]
function ReactUtil.Hydrate(
	instance: Instance,
	props: Props,
	children: any?
): {
	context: () -> ReactElement<{}, any>,
	element: ReactElement<{}, any>,
	getRef: (string) -> any,
	getElement: (string) -> ReactElement<{}, any>?,
}
	assert(React, REACT_NOT_FOUND)
	assert(typeof(instance) == "Instance", "Expected an instance")
	assert(typeof(props) == "table" or props == nil, "Expected a table for props")

	local _children: ReactChildren = children
	local refs = {} :: RefNode

	local instanceTree = buildInstanceTree(instance, props, _children, refs)

	if refs[instance.Name] then
		-- Go up one level to the root
		refs = refs[instance.Name]
	end

	return {
		context = function()
			return instanceTree
		end,
		element = instanceTree,
		getRef = function(name: string)
			local res = Util.treePath(refs, name)

			if res then
				return res["$$root"] and res["$$root"].ref
			end

			return nil
		end,
		getElement = function(name: string)
			local res = Util.treePath(refs, name)

			if res then
				return res["$$root"]
			end

			return nil
		end,
	}
end

return ReactUtil
