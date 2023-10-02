# dLib
Modules and Libraries for development in Roblox. _Feel free to read through the modules while documentation is written!_

# Installing
## wally
Add the below line to your wally.toml file
```toml
dLib = "dig1t/dlib@1.1.0"
```
## Roblox Studio
Download the rbxm file from the [releases](https://github.com/dig1t/dlib/releases) tab and insert it into ReplicatedStorage or your location of choice.

# Setup
```lua
-- Require dLib from your installation location
-- For this example we'll use ReplicatedStorage as dLib's parent location
-- and we'll import dLib's built in Palette module
local import = require(game:GetService("ReplicatedStorage"):WaitForChild("dLib")).import
```

# Usage
```lua
local Palette = import("Palette")

print(Palette("blue", 500))
```