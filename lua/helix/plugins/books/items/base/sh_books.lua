-- items/sh_book_base.lua
-- Base item inherited by every book.  Never give this directly.

ITEM.name        = "Book"
ITEM.description = "A readable book."
ITEM.category    = "Books"
ITEM.model       = "models/props_junk/garbage_newspaper002a.mdl"
ITEM.width       = 1
ITEM.height      = 1

ITEM.bookTitle   = "Untitled"
ITEM.bookAuthor  = "Unknown"
ITEM.bookContent = ""

ITEM.bookCoverStyle    = "classic"
ITEM.bookDualPage      = false
ITEM.bookTitleFont     = "Georgia"
ITEM.bookTitleFontSize = 26
ITEM.bookCoverImageURL = nil
ITEM.bookModel         = nil  

ITEM.bookCoverColor     = nil
ITEM.bookTextColor      = nil
ITEM.bookAccentColor    = nil
ITEM.bookPageColor      = nil
ITEM.bookBodyColor      = nil
ITEM.bookHeadColor      = nil
ITEM.bookQuoteBGColor   = nil
ITEM.bookQuoteBarColor  = nil
ITEM.bookCodeBGColor    = nil
ITEM.bookCodeTextColor  = nil
ITEM.bookHrColor        = nil
ITEM.bookTableHdrColor  = nil
ITEM.bookTableLineColor = nil
ITEM.bookNavBtnColor    = nil
ITEM.bookNavHoverColor  = nil
ITEM.bookNavTextColor   = nil
ITEM.bookChartBarColor  = nil
ITEM.bookChartGridColor = nil


local function SafeString(v, fallback)
    if v == nil then return fallback end
    v = tostring(v)
    if v == "" then return fallback end
    return v
end

local function SafeBool(v, fallback)
    if v == nil then return fallback end
    return v and true or false
end

local function SafeUInt(v, fallback, min, max)
    local n = math.floor(tonumber(v) or fallback or 0)
    return math.Clamp(n, min or 0, max or 255)
end

local function SafeColorTable(tbl)
    if not istable(tbl) then return nil end
    if tbl[1] == nil or tbl[2] == nil or tbl[3] == nil then return nil end
    return {
        SafeUInt(tbl[1],0,0,255),
        SafeUInt(tbl[2],0,0,255),
        SafeUInt(tbl[3],0,0,255)
    }
end

local function WriteColor(tbl)
    tbl = SafeColorTable(tbl)
    if tbl then
        net.WriteUInt(1,8)
        net.WriteUInt(tbl[1],8); net.WriteUInt(tbl[2],8); net.WriteUInt(tbl[3],8)
    else
        net.WriteUInt(0,8)
        net.WriteUInt(0,8); net.WriteUInt(0,8); net.WriteUInt(0,8)
    end
end

-- ══════════════════════════════════════════════════════════════════
--  GETTERS
--  Priority: item data (set per-instance by editor) → ITEM field → fallback
-- ══════════════════════════════════════════════════════════════════
function ITEM:GetBookField(key, fallback)
    return self:GetData(key, self[key] ~= nil and self[key] or fallback)
end

function ITEM:GetBookTitle()
    return SafeString(self:GetBookField("bookTitle", "Untitled"), "Untitled")
end
function ITEM:GetBookAuthor()
    return SafeString(self:GetBookField("bookAuthor", "Unknown"), "Unknown")
end
function ITEM:GetBookContent()
    return SafeString(self:GetBookField("bookContent", ""), "")
end
function ITEM:GetBookCoverStyle()
    return SafeString(self:GetBookField("bookCoverStyle", "classic"), "classic")
end
function ITEM:GetBookDualPage()
    return SafeBool(self:GetBookField("bookDualPage", false), false)
end
function ITEM:GetBookTitleFont()
    return SafeString(self:GetBookField("bookTitleFont", "Georgia"), "Georgia")
end
function ITEM:GetBookTitleFontSize()
    return SafeUInt(self:GetBookField("bookTitleFontSize", 26), 26, 8, 48)
end
function ITEM:GetBookCoverImageURL()
    local url = SafeString(self:GetBookField("bookCoverImageURL", ""), "")
    url = string.Trim(url)
    return url ~= "" and url or ""
end
function ITEM:GetBookModel()
    local m = SafeString(self:GetBookField("bookModel", ""), "")
    return m ~= "" and m or nil
end
function ITEM:GetBookColor(key)
    return SafeColorTable(self:GetBookField(key, nil))
end

-- Inventory display name / description reflect book metadata
function ITEM:GetName()        return self:GetBookTitle() end
function ITEM:GetDescription() return "by " .. self:GetBookAuthor() end

-- ══════════════════════════════════════════════════════════════════
--  NET HELPER: write full book state to net (for ix_books_open)
-- ══════════════════════════════════════════════════════════════════
local function SendBookToClient(item, client)
    net.Start("ix_books_open")
        net.WriteString(item:GetBookTitle())
        net.WriteString(item:GetBookAuthor())
        net.WriteString(item:GetBookContent())
        net.WriteString(item:GetBookCoverStyle())
        net.WriteBool(item:GetBookDualPage())
        net.WriteString(item:GetBookTitleFont())
        net.WriteUInt(item:GetBookTitleFontSize(), 8)
        net.WriteString(item:GetBookCoverImageURL())
        WriteColor(item:GetBookColor("bookCoverColor"))
        WriteColor(item:GetBookColor("bookTextColor"))
        WriteColor(item:GetBookColor("bookAccentColor"))
        WriteColor(item:GetBookColor("bookPageColor"))
        WriteColor(item:GetBookColor("bookBodyColor"))
        WriteColor(item:GetBookColor("bookHeadColor"))
        WriteColor(item:GetBookColor("bookQuoteBGColor"))
        WriteColor(item:GetBookColor("bookQuoteBarColor"))
        WriteColor(item:GetBookColor("bookCodeBGColor"))
        WriteColor(item:GetBookColor("bookCodeTextColor"))
        WriteColor(item:GetBookColor("bookHrColor"))
        WriteColor(item:GetBookColor("bookTableHdrColor"))
        WriteColor(item:GetBookColor("bookTableLineColor"))
        WriteColor(item:GetBookColor("bookNavBtnColor"))
        WriteColor(item:GetBookColor("bookNavHoverColor"))
        WriteColor(item:GetBookColor("bookNavTextColor"))
        WriteColor(item:GetBookColor("bookChartBarColor"))
        WriteColor(item:GetBookColor("bookChartGridColor"))
    net.Send(client)
end

-- ══════════════════════════════════════════════════════════════════
--  NET HELPER: send full book state to editor (for ix_books_edit)
-- ══════════════════════════════════════════════════════════════════
local function SendBookToEditor(item, client)
    net.Start("ix_books_edit")
        net.WriteUInt(item.id, 32)
        net.WriteString(item:GetBookTitle())
        net.WriteString(item:GetBookAuthor())
        net.WriteString(item:GetBookContent())
        net.WriteString(item:GetBookCoverStyle())
        net.WriteBool(item:GetBookDualPage())
        net.WriteString(item:GetBookTitleFont())
        net.WriteUInt(item:GetBookTitleFontSize(), 8)
        net.WriteString(item:GetBookCoverImageURL())
        -- Also send model
        local m = item:GetBookModel() or item.model or ""
        net.WriteString(m)
        WriteColor(item:GetBookColor("bookCoverColor"))
        WriteColor(item:GetBookColor("bookTextColor"))
        WriteColor(item:GetBookColor("bookAccentColor"))
        WriteColor(item:GetBookColor("bookPageColor"))
        WriteColor(item:GetBookColor("bookBodyColor"))
        WriteColor(item:GetBookColor("bookHeadColor"))
        WriteColor(item:GetBookColor("bookQuoteBGColor"))
        WriteColor(item:GetBookColor("bookQuoteBarColor"))
        WriteColor(item:GetBookColor("bookCodeBGColor"))
        WriteColor(item:GetBookColor("bookCodeTextColor"))
        WriteColor(item:GetBookColor("bookHrColor"))
        WriteColor(item:GetBookColor("bookTableHdrColor"))
        WriteColor(item:GetBookColor("bookTableLineColor"))
        WriteColor(item:GetBookColor("bookNavBtnColor"))
        WriteColor(item:GetBookColor("bookNavHoverColor"))
        WriteColor(item:GetBookColor("bookNavTextColor"))
        WriteColor(item:GetBookColor("bookChartBarColor"))
        WriteColor(item:GetBookColor("bookChartGridColor"))
    net.Send(client)
end


ITEM.functions = ITEM.functions or {}

ITEM.OnEntityTakeDamage = function(self, entity, damageInfo)
    if self.data.isFrozen == true then
        return false -- annule les dégâts si frozen
    end
    -- sinon on ne retourne rien → les dégâts s'appliquent normalement
end
ITEM.functions.Read = {
    name  = "Read",
    icon  = "icon16/book.png",
    OnRun = function(item)
        local client = item.player
        if not IsValid(client) then return false end
        SendBookToClient(item, client)
        return false
    end,
}

ITEM.functions.Edit = {
    name     = "Edit Book",
    icon     = "icon16/pencil.png",
    adminOnly = true,
    OnCanRun = function(item)
        local client = item.player
        return IsValid(client) and client:IsAdmin()
    end,
    OnRun = function(item)
        local client = item.player
        local char = client:GetCharacter()
        if not char then return end
        local inv = char:GetInventory()
        if not inv then return end

        if item.invID ~= inv:GetID() then
            ix.util.NotifyLocalized("ixbook_edit_own_inventory_only", client)
            return
        end
        local client = item.player
        if not IsValid(client) then return false end
        if not client:IsAdmin() then
            ix.util.NotifyLocalized("ixbook_admin_only", client)
            return false
        end
        SendBookToEditor(item, client)
        return false
    end,
}

ITEM.functions.Freeze = {
    name     = "Freeze/UnFreeze",
    icon     = "icon16/shield.png",
    adminOnly = true,

    OnCanRun = function(item)
        local client = item.player
        return IsValid(client) and client:IsAdmin()
    end,

    OnRun = function(item)
        local client = item.player
        if not IsValid(client) or not client:IsAdmin() then return false end

        if item.data.isFrozen then
            item:SetData("isFrozen", false)
            ix.util.NotifyLocalized("ixbook_unfreeze", client)
        else
            item:SetData("isFrozen", true)
            ix.util.NotifyLocalized("ixbook_freeze", client)
        end
        return false
    end,
}


ITEM.functions.Archive = {
    name     = "Archive",
    icon     = "icon16/database_save.png",
    adminOnly = true,
    OnCanRun = function(item)
        local client = item.player
        return IsValid(client) and client:IsAdmin()
    end,
    OnRun = function(item)
        local client = item.player
        if not IsValid(client) then return false end
        if not client:IsAdmin() then
            ix.util.NotifyLocalized("ixbook_admin_only", client)
            return false
        end

        local itemID   = item.id

        local item   = ix.item.instances[itemID]
        if not item then return end

        local char = client:GetCharacter()
        if not char then return end
        local inv = char:GetInventory()
        if not inv then return end

        if item.invID ~= inv:GetID() then
            ix.util.NotifyLocalized("ixbook_archive_own_inventory_only", client)
            return false
        end

        local title = string.lower(item:GetBookTitle() or "book"):gsub("[^%w]+", "_"):gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", "")
        local author = string.lower(item:GetBookAuthor() or "unknown"):gsub("[^%w]+", "_"):gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", "")
        local defaultID = "ixbooks_" .. (title ~= "" and title or "book") .. "_" .. (author ~= "" and author or "unknown")

        net.Start("ixBooksArchiveRequest")
            net.WriteUInt(item.id, 32)
            net.WriteString(defaultID)
        net.Send(client)

        return false
    end,
}


ITEM.functions.Unarchive = {
    name     = "UnArchive",
    icon     = "icon16/database_delete.png",
    adminOnly = true,

    OnCanRun = function(item)
        local client = item.player
        return item.isArchivedBook == true and IsValid(client) and client:IsAdmin()
    end,
    OnRun = function(item)
        local client = item.player
        if not IsValid(client) then return false end
        if not client:IsAdmin() then
            ix.util.NotifyLocalized("ixbook_admin_only", client)
            return false
        end
        if not item.isArchivedBook then
            ix.util.NotifyLocalized("ixbook_not_archived", client)
            return false
        end

        local uniqueid = item.archivedID

        UnarchiveBook(uniqueid, client)

        return false
    end,
}
