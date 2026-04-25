PLUGIN.name        = "Books"
PLUGIN.author      = "Sunshi"
PLUGIN.description = "Adds readable book items with Markdown rendering."


if SERVER then
    util.AddNetworkString("ix_books_open")
    util.AddNetworkString("ix_books_spawn")
    util.AddNetworkString("ix_books_edit")
    util.AddNetworkString("ix_books_edit_submit")
end

ix.command.Add("BookEditor", {
    description = "Open the book editor.",
    adminOnly   = true,
    arguments   = {},
    OnRun = function(self, client)
        client:ConCommand("ix_book_editor")
    end
})

ix.command.Add("BookArchives", {
    description = "Open the archived books manager.",
    adminOnly = true,
    OnRun = function(self, client)
        net.Start("ixBooksArchiveOpenMenu")
        net.Send(client)
    end
})


function PLUGIN:CanTransferItem(item, currentInv, oldInv)
    if item.category == "Books" && item.data && item.data.isFrozen == true then return false end
end


if SERVER then

    -- Helper to read a color from net (flag + rgb)
    local function NetReadColor()
        local flag = net.ReadUInt(8)
        local r, g, b = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
        if flag == 0 then return nil end
        return { r, g, b }
    end

    -- Helper to read a full book config from net
    local function NetReadBookCfg()
        local cfg = {}
        cfg.bookTitle         = net.ReadString()
        cfg.bookAuthor        = net.ReadString()
        cfg.bookContent       = net.ReadString()
        cfg.bookCoverStyle    = net.ReadString()
        cfg.bookDualPage      = net.ReadBool()
        cfg.bookTitleFont     = net.ReadString()
        cfg.bookTitleFontSize = net.ReadUInt(8)
        cfg.bookCoverImageURL = net.ReadString()
        cfg.bookModel         = net.ReadString()

        if cfg.bookTitleFontSize < 8 then cfg.bookTitleFontSize = 26 end
        if cfg.bookTitleFont     == "" then cfg.bookTitleFont = "Roboto" end
        if cfg.bookCoverImageURL == "" then cfg.bookCoverImageURL = nil  end
        if cfg.bookModel         == "" then cfg.bookModel = nil end

        cfg.bookCoverColor      = NetReadColor()
        cfg.bookTextColor       = NetReadColor()
        cfg.bookAccentColor     = NetReadColor()
        cfg.bookPageColor       = NetReadColor()
        cfg.bookBodyColor       = NetReadColor()
        cfg.bookHeadColor       = NetReadColor()
        cfg.bookQuoteBGColor    = NetReadColor()
        cfg.bookQuoteBarColor   = NetReadColor()
        cfg.bookCodeBGColor     = NetReadColor()
        cfg.bookCodeTextColor   = NetReadColor()
        cfg.bookHrColor         = NetReadColor()
        cfg.bookTableHdrColor   = NetReadColor()
        cfg.bookTableLineColor  = NetReadColor()
        cfg.bookNavBtnColor     = NetReadColor()
        cfg.bookNavHoverColor   = NetReadColor()
        cfg.bookNavTextColor    = NetReadColor()
        cfg.bookChartBarColor   = NetReadColor()
        cfg.bookChartGridColor  = NetReadColor()
        return cfg
    end

    net.Receive("ix_books_spawn", function(_, client)
        if not client:IsAdmin() then
            ix.util.NotifyLocalized("ixbook_admin_only", client)
            return
        end

        local cfg  = NetReadBookCfg()
        local char = client:GetCharacter()
        if not char then return end
        local inv = char:GetInventory()
        if not inv then return end

        -- Copy all book fields as item data
        local data = {}
        for k, v in pairs(cfg) do
            data[k] = v
        end

        inv:Add("book_blank", 1, data)
        ix.util.NotifyLocalized("ixbook_bookgived", client)
    end)

    net.Receive("ix_books_edit_submit", function(_, client)

        if not client:IsAdmin() then
            ix.util.NotifyLocalized("ixbook_admin_only", client)
            return
        end

        local itemID = net.ReadUInt(32)
        local cfg    = NetReadBookCfg()

        -- Find the item in the character's inventory
        local char = client:GetCharacter()
        if not char then return end
        local inv = char:GetInventory()
        if not inv then return end

        local item = ix.item.instances[itemID]
        if not item then return end

        -- Security: make sure the item is in this player's inventory
        if item.invID ~= inv:GetID() then
            ix.util.NotifyLocalized("ixbook_edit_own_inventory_only", client)
            return
        end

        for k, v in pairs(cfg) do
            item:SetData(k, v)
        end

        if cfg.bookModel and cfg.bookModel ~= "" then
            item.model = cfg.bookModel
            local ent = item.GetEntity and item:GetEntity() or nil
            if IsValid(ent) and util.IsValidModel(cfg.bookModel) then
                ent:SetModel(cfg.bookModel)
            end
        end

        ix.util.NotifyLocalized("ixbook_updated", client)
    end)



    AddCSLuaFile("cl_book.lua")
    AddCSLuaFile("cl_editor.lua")
    AddCSLuaFile("sh_archive.lua")
    include("sh_archive.lua")
else
    include("cl_book.lua")
    include("cl_editor.lua")
    include("sh_archive.lua")
end

