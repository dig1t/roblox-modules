# dLib Modules

dLib is a collection of modules and libraries for development in Roblox.

[![CI](https://github.com/dig1t/dlib/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dig1t/dlib/actions/workflows/ci.yml)

## Installing Modules (wally)
**Available modules:**
```toml
Animation = "dig1t/animation@1.0.0"
Badge = "dig1t/badge@1.0.0"
Cache = "dig1t/cache@1.0.0"
GamePass = "dig1t/gamepass@1.0.1"
Maid = "dig1t/maid@1.0.0"
Palette = "dig1t/palette@1.0.0"
Promise = "dig1t/promise@1.0.0"
Ragdoll = "dig1t/ragdoll@1.0.1"
Util = "dig1t/util@1.0.1"
```

## Module Examples

### Util
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require Util from your installation location
-- For this example we'll use ReplicatedStorage.Packages as Util's parent location
local Util = require(ReplicatedStorage.Packages.Util)

local touchPart: BasePart = workspace:WaitForChild("Plate")
local connection: RBXScriptConnection? -- onPlayerTouch returns RBXScriptConnection

connection = Util.onPlayerTouch(touchPart, function(player: Player)
	print(`{player.Name} touched the part!`)

	-- Disconnect the connection
	if connection then
		connection:Disconnect()
	end
end)
```

### Palette
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require Palette from your installation location
-- For this example we'll use ReplicatedStorage.Packages as Palettes's parent location
local Palette = require(ReplicatedStorage.Packages.Palette)

print(Palette.get("blue", 500))
```

### Promise

Method 1:
```lua
local Promise = require(ReplicatedStorage.Packages.Promise)

local myPromise: typeof(Promise.PromiseType) = Promise.new(function(resolve, reject)
	resolve("Hello World!")
end)
```

Method 2:
```lua
local Promise = require(ReplicatedStorage.Packages.Promise)

type PromiseType = typeof(Promise.PromiseType)

local myPromise: PromiseType = Promise.new(function(resolve, reject)
	resolve("Hello World!")
end)
```

### Maid

Method 1:
```lua
local Maid = require(ReplicatedStorage.Packages.Maid)

local myMaid: typeof(Maid.MaidType) = Maid.new()
```

Method 2:
```lua
local Maid = require(ReplicatedStorage.Packages.Maid)

type MaidType = typeof(Maid.MaidType)

local myMaid: MaidType = Maid.new()
```

### Cache

Method 1:
```lua
local Cache = require(ReplicatedStorage.Packages.Cache)

local myCache: typeof(Cache.CacheType) = Cache.new()
```

Method 2:
```lua
local Cache = require(ReplicatedStorage.Packages.Cache)

type CacheType = typeof(Cache.CacheType)

local myCache: CacheType = Cache.new()
```
