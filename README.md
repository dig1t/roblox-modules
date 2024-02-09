[![CI](https://github.com/dig1t/dlib/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dig1t/dlib/actions/workflows/ci.yml)

# dLib
Modules and Libraries for development in Roblox.

# Installing
## Installing with wally
Add the below line to your wally.toml file
```toml
dlib = "dig1t/dlib@1.2.7"
```
## Installing with Roblox Studio
Download the rbxl file from the [releases](https://github.com/dig1t/dlib/releases) tab.

Once the place file is open, you can find the package inside `ReplicatedStorage.Packages`.

### Usage
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require dLib from your installation location
-- For this example we'll use ReplicatedStorage as dLib's parent location
-- and we'll import dLib's built in Palette module
local dLib = require(ReplicatedStorage.dlib)
local Palette = dLib.Palette

print(Palette.get("blue", 500))
```

## Using built-in module types
dLib has a few built-in types that you can use to type your variables.

### Promises

Method 1:
```lua
local Promise = dLib.Promise

local myPromise: typeof(Promise.PromiseType) = Promise.new(function(resolve, reject)
	resolve("Hello World!")
end)
```

Method 2:
```lua
local Promise = dLib.Promise

type PromiseType = typeof(Promise.PromiseType)

local myPromise: PromiseType = Promise.new(function(resolve, reject)
	resolve("Hello World!")
end)
```

### Maids

Method 1:
```lua
local Maid = dLib.Maid

local myMaid: typeof(Maid.MaidType) = Maid.new()
```

Method 2:
```lua
local Maid = dLib.Maid

type MaidType = typeof(Maid.MaidType)

local myMaid: MaidType = Maid.new()
```

### Cache

Method 1:
```lua
local Cache = dLib.Cache

local myCache: typeof(Cache.CacheType) = Cache.new()
```

Method 2:
```lua
local Cache = dLib.Cache

type CacheType = typeof(Cache.CacheType)

local myCache: CacheType = Cache.new()
```

[Click here](https://dig1t.github.io/dlib/api/dLib) to learn how to import your first dLib module.
