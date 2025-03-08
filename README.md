# roblox-modules Modules

roblox-modules is a collection of modules and libraries for development in Roblox.

[![CI](https://github.com/dig1t/roblox-modules/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dig1t/roblox-modules/actions/workflows/ci.yml)

## Installing Modules (wally)
**Available modules:**
```toml
Animation = "dig1t/animation@1.0.6"
Badge = "dig1t/badge@1.0.4"
Cache = "dig1t/cache@1.0.8"
GamePass = "dig1t/gamepass@1.0.8"
Maid = "dig1t/maid@1.0.6"
Palette = "dig1t/palette@1.0.0"
ProfileDB = "dig1t/profiledb@1.0.0"
Promise = "dig1t/promise@1.1.2"
Ragdoll = "dig1t/ragdoll@1.0.4"
ReactUtil = "dig1t/react-util@1.0.6"
Replica = "dig1t/replica@1.0.0"
Signal = "dig1t/signal@1.0.0"
State = "dig1t/state@1.1.0"
Trash = "dig1t/trash@1.0.0"
Util = "dig1t/util@1.0.13"
```

Use version ^1.0 on any module to use its latest version.

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

local myPromise: Promise.PromiseType = Promise.new(function(resolve, reject)
	resolve("Hello World!")
end)
```

Method 2:
```lua
local Promise = require(ReplicatedStorage.Packages.Promise)

type PromiseType = Promise.PromiseType

local myPromise: PromiseType = Promise.new(function(resolve, reject)
	resolve("Hello World!")
end)
```

### Maid

Method 1:
```lua
local Maid = require(ReplicatedStorage.Packages.Maid)

local myMaid: Maid.MaidType = Maid.new()
```

Method 2:
```lua
local Maid = require(ReplicatedStorage.Packages.Maid)

type MaidType = Maid.MaidType

local myMaid: MaidType = Maid.new()
```

### Cache

Method 1:
```lua
local Cache = require(ReplicatedStorage.Packages.Cache)

local myCache: Cache.CacheType = Cache.new()
```

Method 2:
```lua
local Cache = require(ReplicatedStorage.Packages.Cache)

type CacheType = Cache.CacheType

local myCache: CacheType = Cache.new()
```
