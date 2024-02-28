--!strict

local Players = game:GetService("Players")

local TableUtil = require(script.Parent.TableUtil)

return function()
	describe("Extend", function()
		it("should deep merge", function(context)
			local testCase = {
				foo = {
					bar = "baz",
					qux = "quux",
				},
				qux = "quux",
			}

			local testCase2 = {
				foo = {
					bar = "qux",
				},
				qux = "quux",
			}

			-- This should only shallow merge
			local result = TableUtil.extend(testCase, testCase2)

			expect(result.foo.qux).to.be.a("nil") -- qux will not be merged because it's a shallow merge and testCase2.foo.qux is nil

			-- This should deep merge
			local result2 = TableUtil.extend(true, testCase, testCase2)

			expect(result2.foo.qux).to.equal("quux") -- qux will be merged because it's a deep merge, regardless if testCase2.foo.qux is nil
		end)

		it("should not deep merge if the first argument is a table", function(context)
			local testCase = {
				foo = {
					bar = "baz",
					qux = "quux",
				},
				qux = "quux",
			}

			local testCase2 = {
				foo = {
					bar = "qux",
				},
				qux = "quux",
			}

			local result = TableUtil.extend(testCase, testCase2)

			expect(result.foo.bar).to.equal("qux")
		end)
	end)
end
