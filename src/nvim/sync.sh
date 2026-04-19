#!/bin/sh
set -e

NVIM_BIN="$1"
SYNC_LUA="$2"

NVIM_CONFIG="$("${NVIM_BIN}" --headless -u NONE -c 'lua io.write(vim.fn.stdpath("config"))' -c qa 2>&1)"
PLUGINS_LUA="${NVIM_CONFIG}/lua/plugins.lua"

# patch plugins.lua to avoid errors when installing packages via mason
sed -i 's/registry\.get_package(package):install()/local _ok, _pkg = pcall(registry.get_package, package); if _ok then _pkg:install() end/' "${PLUGINS_LUA}"

# install plugins and sync mason packages
"${NVIM_BIN}" --headless -c 'Lazy! sync' -c qa
"${NVIM_BIN}" --headless -c "luafile ${SYNC_LUA}"
