local uname = vim.loop.os_uname()
io.write(("[mason-sync] platform: %s %s\n"):format(uname.sysname, uname.machine))

local arch_map = { x86_64 = "x64", aarch64 = "arm64" }
local arch = arch_map[uname.machine] or uname.machine
local target = ("linux_%s_gnu"):format(arch)
io.write(("[mason-sync] target: %s\n"):format(target))

local config_dir = vim.fn.stdpath("config")
local f = io.open(config_dir .. "/lua/plugins.lua", "r")
if not f then
    io.write("[mason-sync] plugins.lua not found\n")
    vim.cmd("qa!")
    return
end

local content = f:read("*a")
f:close()

local ensure_block = content:match("ensure_installed%s*=%s*(%b{})")
if not ensure_block then
    io.write("[mason-sync] no ensure_installed block found\n")
    vim.cmd("qa!")
    return
end

local packages = {}
for name in ensure_block:gmatch('"([^"]+)"') do
    table.insert(packages, name)
end

if #packages == 0 then
    vim.cmd("qa!")
    return
end

io.write(("[mason-sync] packages: %s\n"):format(table.concat(packages, ", ")))

local registry = require("mason-registry")

io.write("[mason-sync] refreshing registry...\n")
local refreshed = false
registry.refresh(function()
    refreshed = true
end)

local ok = vim.wait(60000, function() return refreshed end, 500)
if not ok then
    io.write("[mason-sync] ERROR: registry refresh timed out\n")
    vim.cmd("qa!")
    return
end
io.write("[mason-sync] registry refreshed\n")

local handles = {}
local skipped = {}
local errors = {}
for _, name in ipairs(packages) do
    local pok, pkg = pcall(registry.get_package, name)
    if not pok then
        table.insert(skipped, name)
    elseif not pkg:is_installed() then
        local handle = pkg:install({ target = target })
        errors[name] = {}
        handle:on("stderr", function(chunk)
            table.insert(errors[name], chunk)
        end)
        table.insert(handles, { name = name, handle = handle })
    end
end

if #skipped > 0 then
    io.write("[mason-sync] not in registry: " .. table.concat(skipped, ", ") .. "\n")
end

io.write(("[mason-sync] installing %d packages...\n"):format(#handles))

vim.wait(600000, function()
    for _, h in ipairs(handles) do
        if not h.handle:is_closed() then
            return false
        end
    end
    return true
end, 5000)

local installed = {}
local failed = {}
for _, h in ipairs(handles) do
    local pok, pkg = pcall(registry.get_package, h.name)
    if pok and pkg:is_installed() then
        table.insert(installed, h.name)
    else
        table.insert(failed, h.name)
    end
end

if #installed > 0 then
    io.write("[mason-sync] installed: " .. table.concat(installed, ", ") .. "\n")
end
if #failed > 0 then
    io.write("[mason-sync] failed: " .. table.concat(failed, ", ") .. "\n")
    for _, name in ipairs(failed) do
        local stderr = table.concat(errors[name] or {}, "")
        if stderr ~= "" then
            io.write(("[mason-sync]   %s: %s\n"):format(name, vim.trim(stderr)))
        end
    end
end

vim.cmd("qa!")
