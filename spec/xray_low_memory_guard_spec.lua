-- spec/xray_low_memory_guard_spec.lua
-- Unit tests for Low-Memory Detection and Safety Guards
require("spec.spec_helper")
local utils = require("xray_utils")

describe("Low-Memory Detection & Guards", function()
    it("parses modern Linux /proc/meminfo with MemAvailable", function()
        local tmp = "/tmp/test_meminfo_modern.txt"
        local f = io.open(tmp, "w")
        assert.is_not_nil(f)
        f:write([[
MemTotal:         512000 kB
MemFree:           10240 kB
MemAvailable:      45000 kB
Buffers:            4096 kB
Cached:            30000 kB
]])
        f:close()

        local mem = utils:getMemoryInfo(tmp)
        assert.is_not_nil(mem)
        assert.are.equal(512000, mem.total_kb)
        assert.are.equal(45000, mem.available_kb)
        assert.are.equal(10240, mem.free_kb)

        local is_low, avail = utils:isLowMemory(30 * 1024, tmp)
        assert.is_false(is_low)
        assert.are.equal(45000, avail)

        local is_low_strict = utils:isLowMemory(50 * 1024, tmp)
        assert.is_true(is_low_strict)

        os.remove(tmp)
    end)

    it("calculates fallback available memory on legacy Kindle Linux 3.0 kernels", function()
        local tmp = "/tmp/test_meminfo_kindle.txt"
        local f = io.open(tmp, "w")
        assert.is_not_nil(f)
        f:write([[
MemTotal:         247852 kB
MemFree:            3584 kB
Buffers:            1024 kB
Cached:            12288 kB
SwapTotal:             0 kB
SwapFree:              0 kB
]])
        f:close()

        local mem = utils:getMemoryInfo(tmp)
        assert.is_not_nil(mem)
        assert.are.equal(247852, mem.total_kb)
        -- Fallback: 3584 + 1024 + 12288 = 16896 kB (~16.5 MB)
        assert.are.equal(16896, mem.available_kb)

        local is_low, avail, total = utils:isLowMemory(30 * 1024, tmp)
        assert.is_true(is_low)
        assert.are.equal(16896, avail)
        assert.are.equal(247852, total)

        os.remove(tmp)
    end)

    it("handles non-existent meminfo paths gracefully", function()
        local mem = utils:getMemoryInfo("/nonexistent_path_to_meminfo")
        assert.is_nil(mem)

        local is_low, avail = utils:isLowMemory(30 * 1024, "/nonexistent_path_to_meminfo")
        assert.is_false(is_low)
        assert.is_nil(avail)
    end)
end)
