local Maid = require(script.Parent.Maid)
local Util = require(script.Parent.Util)

--[=[
	Cache class for storing data in a cache instance.

	Based off [node-cache](https://npmjs.com/package/node-cache).

	@class Cache
]=]
local Cache = {}
Cache.__index = Cache

export type Key = any

export type CacheObject = {
	key: Key,
	value: any,
	ttl: number?,
}

--[=[
	@within Cache
	@interface CacheOptions
	.defaultTTL? number -- The default time-to-live for a cache entry. Defaults to 6000.
	.checkInterval? number -- The interval in seconds to check for expired cache entries. Defaults to 600.
	.maxKeys? number -- The maximum amount of keys to store in the cache. 0 for unlimited. Defaults to 0.
]=]
export type CacheOptions = {
	defaultTTL: number?,
	checkInterval: number?,
	maxKeys: number?,
}

type CacheTypeOptions = {
	defaultTTL: number,
	checkInterval: number,
	maxKeys: number,
}

export type CacheType = typeof(setmetatable(
	{} :: {
		_cache: { [string]: CacheEntry },
		options: CacheTypeOptions,
		[any]: any,
	},
	Cache
))

--[=[
	@within Cache
	@interface CacheEntry
	.key Key -- The key of the cache entry.
	.value any -- The value of the cache entry.
	.expires number -- The unix timestamp of when the cache entry expires.
]=]
type CacheEntry = {
	key: Key,
	value: any,
	expires: number,
}

local defaultOptions: CacheTypeOptions = {
	defaultTTL = 6000,
	checkInterval = 600,
	maxKeys = 0,
}

--[=[
	Creates a new Cache instance.

	@param options? { defaultTTL: number? }
]=]
function Cache.new(options: CacheOptions?): CacheType
	assert(typeof(options) == "table" or options == nil, "options must be a table or nil")

	if options then
		assert(
			typeof(options.defaultTTL) == "number" or options.defaultTTL == nil,
			"options.defaultTTL must be a number or nil"
		)
	end

	local self = setmetatable({}, Cache) :: CacheType

	self._cache = {}
	self.options = options and Util.extend(options, defaultOptions) or defaultOptions

	self._maid = Maid.new()

	self._maid:Task(Util.interval(self.options.checkInterval, function()
		local timestamp: number = Util.unix()

		for key: Key, cacheEntry: CacheEntry in pairs(self._cache) do
			if cacheEntry.expires ~= 0 and cacheEntry.expires <= timestamp then
				self:Delete(key)
			end
		end

		return
	end))

	return self
end

--[=[
	### Store a key:

	Sets a `key` `value` pair. It is possible to define a ttl (in seconds). Returns `true` on success.

	```lua
	local obj = { my = "Special", variable = 42 }

	local success = myCache:Set( "myKey", obj, 10000 )
	-- true
	```
	> Note: If the key expires based on it's `ttl` it will be deleted entirely from the internal data object.

	@within Cache
	@method Set
	@param key string -- The key to set.
	@param value any -- The value to set.
	@param ttl number? -- The time-to-live for the cache entry. Defaults to the defaultTTL option. 0 for unlimited.
	@return boolean -- Whether or not the value was set.
]=]
function Cache.Set(self: CacheType, key: Key, value: any, ttl: number?): boolean
	local numberKeys: number = Util.tableLength(self:Keys())
	local maxKeys: number = self.options.maxKeys or 0

	if maxKeys > 0 and numberKeys >= maxKeys then
		return false
	end

	self._cache[key] = {
		key = key,
		value = value,
		expires = ttl
			or Util.unix() + (self.options.defaultTTL or defaultOptions.defaultTTL),
	} :: CacheEntry

	return true
end

--[=[
	### Store multiple keys:

	Sets multiple `key` `value` pairs. It is possible to define a `ttl` (in seconds). Returns `true` on success.

	```lua
	local obj = { my = "Special", variable = 42 }
	local obj2 = { my = "other special", variable = 1337 }

	local success = myCache:setMultiple({
		{ key = "myKey", value = obj, ttl = 10000 },
		{ key = "myKey2", value = obj2 }
	})
	-- true
	```

	@within Cache
	@method SetMultiple
	@param cacheObjects { CacheObject } -- The key to set.
	@return boolean -- Whether or not the value was set.
]=]
function Cache.SetMultiple(self: CacheType, cacheObjects: { CacheObject }): boolean
	for _, cacheObject: CacheObject in cacheObjects do
		local success: boolean? =
			self:Set(cacheObject.key, cacheObject.value, cacheObject.ttl)

		if success ~= true then
			return false
		end
	end

	return true
end

--[=[
	### Retrieve a key:

	Gets a saved `value` from the cache. Returns `nil` if not found or expired. If the `value` was found it returns the `value`.

	```lua
	local value = myCache:get("myKey")
	```

	@within Cache
	@method Get
	@param key Key -- The key to retrieve.
	@return CacheEntry? -- The value of the key.
]=]
function Cache.Get(self: CacheType, key: Key): CacheEntry?
	assert(typeof(key) == "string", "key must be a string")

	local cacheEntry = self._cache[key] :: CacheEntry?

	if cacheEntry and cacheEntry.expires > Util.unix() then
		return cacheEntry.value
	end

	return
end

--[=[
	### Take a key:

	Get the cached `value` and remove the `key` from the cache.
	Equivalent to calling `get(key)` + `delete(key)`.
	Useful for implementing `single use` mechanism, where once a value is read it will become obsolete.

	```lua
	myCache:Set("myKey", "myValue", 10000)
	myCache:Has("myKey") -- true
	local value = myCache:Take("myKey") -- "myValue"
	myCache:Has("myKey") -- false
	```

	@within Cache
	@method Take
	@param key Key -- The key to retrieve.
	@return CacheEntry? -- The value of the key.
]=]
function Cache.Take(self: CacheType, key: Key): CacheEntry?
	assert(typeof(key) == "string", "key must be a string")

	local cacheEntry = self._cache[key] :: CacheEntry?

	if cacheEntry and cacheEntry.expires > Util.unix() then
		self._cache[key] = nil

		return cacheEntry.value
	end

	return
end

--[=[
	### Retrieve multiple keys:

	Gets multiple saved values from the cache. Returns an empty table `{}` if not found or expired.

	If the values were found it returns a table with the `key` `value` pair(s).

	```lua
	local values = myCache:GetMultiple({ "myKey", "myKey2" })
	```

	@within Cache
	@method GetMultiple
	@param keys { Key } -- The keys to retrieve.
	@return { [Key]: any } -- The values of the keys.
]=]
function Cache.GetMultiple(self: CacheType, keys: { Key }): { [Key]: any }
	local values = {} :: { [string]: any }

	for _, key: Key in keys do
		values[key] = self:Get(key)
	end

	return values
end

--[=[
	Deletes a key. Returns the number of deleted entries. A delete will not fail if the key is not existing.

	```lua
	local deleted: number = myCache:Delete("myKey")
	```

	@within Cache
	@method Delete
	@param key Key -- The key to delete.
	@return number -- The number of deleted entries.
]=]
function Cache.Delete(self: CacheType, key: Key): number
	assert(key ~= nil, "Key is required")

	if self._cache[key] == nil then
		return 0
	end

	self._cache[key] = nil

	return 1
end

--[=[
	Deletes multiple keys. Returns the number of deleted entries. This will not fail if a key is not existing.

	```lua
	local deleted: number = myCache:MultipleDelete({ "myKey", "myKey2" })
	```

	@within Cache
	@method MultipleDelete
	@param keys { Key } -- The keys to delete.
	@return number -- The number of deleted entries.
]=]
function Cache.MultipleDelete(self: CacheType, keys: { Key }): number
	local deleted: number = 0

	for _, key: Key in keys do
		deleted += self:Delete(key)
	end

	return deleted
end

--[=[
	Updates the `ttl` of a key. Returns `true` on success.

	```lua
	local success = myCache:TTL("myKey", 10000)
	```

	@within Cache
	@method TTL
	@param key string -- The key to update.
	@param ttl number -- The time-to-live for the cache entry.
	@return boolean -- Whether or not the ttl was updated.
]=]
function Cache.TTL(self: CacheType, key: Key, ttl: number): boolean
	assert(key ~= nil, "Key is required")
	assert(typeof(ttl) == "number", "ttl must be a number")

	local cacheEntry = self._cache[key] :: CacheEntry?

	if cacheEntry then
		cacheEntry.expires = Util.unix() + ttl

		return true
	end

	return false
end

--[=[
	Returns the `ttl` of a key. Returns `nil` if not found or expired.

	```lua
	local ttl = myCache:GetTTL("myKey")
	```

	@within Cache
	@method GetTTL
	@param key string -- The key to retrieve.
	@return number? -- The time-to-live for the cache entry.
]=]
function Cache.GetTTL(self: CacheType, key: Key): number?
	assert(key ~= nil, "Key is required")

	local cacheEntry = self._cache[key] :: CacheEntry?

	if cacheEntry then
		return cacheEntry.expires - Util.unix()
	end

	return
end

--[=[
	Returns all keys in the cache.

	```lua
	local keys = myCache:Keys()
	```

	@within Cache
	@method Keys
	@return { Key } -- The keys in the cache.
]=]
function Cache.Keys(self: CacheType): { Key }
	local keys = {} :: { Key }

	for key: Key, _ in pairs(self._cache) do
		keys[#keys + 1] = key
	end

	return keys
end

--[=[
	Returns a boolean indicating whether an element with the specified key exists or not.

	```lua
	myCache:Has("myKey") -- true
	```

	@within Cache
	@method Has
	@param key string -- The key to check.
	@return boolean -- Whether or not the key exists.
]=]
function Cache.Has(self: CacheType, key: Key): boolean
	assert(key ~= nil, "Key is required")

	return self._cache[key] ~= nil
end

--- Clears the cache.
function Cache:Clear()
	self._cache = {}
end

--[=[
	Deletes all keys and values from the cache.

	Used for cleanup.

	```lua
	myCache:Destroy()
	```

	@within Cache
	@method Destroy
]=]
function Cache.Destroy(self: CacheType)
	self._cache = {}

	self._maid:Destroy()
	self._maid = nil
end

return Cache
