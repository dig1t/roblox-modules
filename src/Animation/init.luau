local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Util = require(script.Parent.Util)

--[=[
	Animation library for animating instances.

	@class Animation
]=]
local Animation = {}

--[=[
	The default animation configuration.

	Example:
	```lua
	Animation.setDefaultConfig({
		tweenInfo = TweenInfo.new(1),
		start = {
			Transparency = 1
		},
		stop = {
			Transparency = 0
		}
	})

	Animation.prepareAnimatedModel(model)

	-- Animate the model
	Animation.animate({
		source = model.PrimaryPart,
	})
	```

	@within Animation
	@prop defaultConfig AnimationConfig
]=]
Animation.defaultConfig = {}

export type AnimationConfig = {
	source: Instance | { [any]: any }?,
	start: { [string]: any }?,
	stop: { [string]: any }?,
	tweenInfo: TweenInfo?,
	frameCallback: () -> (),
	stopCallback: () -> (),
	async: boolean?
}

--[=[
	Prepares a model for animation by welding all descendant parts to the primary part.

	@param model Model -- The model to prepare
	@return nil
]=]
function Animation.prepareAnimatedModel(model)
	if not model.PrimaryPart then
		return
	end

	model.PrimaryPart.Anchored = true

	for _, part in pairs(model:GetDescendants()) do
		if part ~= model.PrimaryPart and part:IsA("BasePart") then
			Util.weld(part, model.PrimaryPart)
			part.Anchored = false
		end
	end
end

--[=[
	Sets the default animation configuration.

	@param config AnimationConfig -- The default animation configuration
	@return nil
]=]
function Animation.setDefaultConfig(config: AnimationConfig): ()
	assert(config and typeof(config) == "table", "Table must be passed to set the default animation config")

	Animation.defaultConfig = config
end

--[=[
	Animates an instance.

	@param config AnimationConfig -- The animation configuration
	@return nil
]=]
function Animation.animate(config: AnimationConfig): ()
	assert(config and typeof(config) == "table", "Missing animation configuration")
	assert(typeof(config.source) == "Instance" or typeof(config.source) == "table", "Missing instance to animate")
	assert(typeof(config.start) == "table", "Missing start properties")
	assert(typeof(config.stop) == "table", "Missing stop properties")
	assert(config.tweenInfo, "Missing TweenInfo")

	-- Place default values
	for k, v in pairs(Animation.defaultConfig) do
		if config[k] == nil then
			config[k] = v
		end
	end

	if config.start then
		local source = config.source :: { [any]: any }

		for property, value in pairs(config.start) do
			source[property] = value
		end
	end

	local TweenBuild = TweenService:Create(
		config.source,
		config.tweenInfo,
		config.stop
	)

	TweenBuild:Play()

	if config.frameCallback then
		while TweenBuild.PlaybackState == Enum.PlaybackState.Playing do
			config.frameCallback()
			RunService.Stepped:Wait()
		end
	end

	if config.async then
		TweenBuild.Completed:Wait()
	end

	if config.stopCallback then
		config.stopCallback()
	end
end

return Animation
