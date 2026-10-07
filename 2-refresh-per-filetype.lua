-- 2-refresh-per-filetype.lua
-- Remembers the "Full refresh rate" setting per file extension
-- (cbz, epub, pdf, ...) and re-applies it whenever a file of that type opens.

local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")
local ReaderUI = require("apps/reader/readerui")
local UIManager = require("ui/uimanager")
local util = require("util")

local store = LuaSettings:open(DataStorage:getSettingsDir() .. "/refresh_per_filetype.lua")

local current_ext = nil -- extension of the document currently open (nil in File Manager)
local applying = false  -- true while we restore a value, so we don't re-save it

local function getExt(file)
    local ext = util.getFileNameSuffix(file or "")
    return ext and ext ~= "" and ext:lower() or nil
end

-- True only while a reader instance with a loaded document really exists
local function readerIsOpen()
    local ui = ReaderUI.instance
    return ui ~= nil and ui.document ~= nil
end

-- Save every change the user makes while a document is open.
-- Extra arguments are forwarded untouched in case KOReader adds new ones.
local orig_setRefreshRate = UIManager.setRefreshRate
function UIManager:setRefreshRate(rate, night_rate, ...)
    orig_setRefreshRate(self, rate, night_rate, ...)
    if applying or not current_ext or not readerIsOpen() then return end
    local entry = store:readSetting(current_ext) or {}
    if rate ~= nil then entry.day = rate end
    if night_rate ~= nil then entry.night = night_rate end
    store:saveSetting(current_ext, entry)
    store:flush()
end

-- Restore the saved value when a document of that type opens
local orig_init = ReaderUI.init
function ReaderUI:init()
    current_ext = self.document and getExt(self.document.file) or nil
    local entry = current_ext and store:readSetting(current_ext)
    if entry then
        applying = true
        UIManager:setRefreshRate(entry.day, entry.night)
        applying = false
    elseif current_ext then
        -- First time we see this type: snapshot the current value so it stays stable
        local day, night = UIManager:getRefreshRate()
        store:saveSetting(current_ext, { day = day, night = night })
        store:flush()
    end
    return orig_init(self)
end

-- Stop saving per-type once the reader is closed
if ReaderUI.onClose then
    local orig_onClose = ReaderUI.onClose
    function ReaderUI:onClose(...)
        current_ext = nil
        return orig_onClose(self, ...)
    end
end