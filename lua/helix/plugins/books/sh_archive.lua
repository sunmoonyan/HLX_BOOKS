local PLUGIN = PLUGIN

ixBooksArchive = ixBooksArchive or {}

local FIELDS = {
    "bookTitle","bookAuthor","bookContent","bookCoverStyle","bookDualPage",
    "bookTitleFont","bookTitleFontSize","bookCoverImageURL","bookModel",
    "bookCoverColor","bookTextColor","bookAccentColor","bookPageColor",
    "bookBodyColor","bookHeadColor","bookQuoteBGColor","bookQuoteBarColor",
    "bookCodeBGColor","bookCodeTextColor","bookHrColor","bookTableHdrColor",
    "bookTableLineColor","bookNavBtnColor","bookNavHoverColor","bookNavTextColor",
    "bookChartBarColor","bookChartGridColor",
}

if SERVER then
    util.AddNetworkString("ixBooksArchiveSync")
    util.AddNetworkString("ixBooksArchiveRequest")
    util.AddNetworkString("ixBooksArchiveSubmit")
    util.AddNetworkString("ixBooksArchiveAction")
    util.AddNetworkString("ixBooksArchiveEdit")
    util.AddNetworkString("ixBooksArchiveSubmitEdited")
    util.AddNetworkString("ixBooksArchiveOpenMenu")
end

local function IsArchivedItemID(uniqueID)
    local item = ix.item.list[uniqueID]
    return item and item.isArchivedBook == true
end

local function NormalizeArchiveID(rawID, title, author)
    local id = tostring(rawID or "")
    id = id:lower():gsub("^%s+", ""):gsub("%s+$", "")

    if id == "" then
        local t = tostring(title or "book"):lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
        local a = tostring(author or "unknown"):lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
        id = "ixbooks_" .. (t ~= "" and t or "book") .. "_" .. (a ~= "" and a or "unknown")
    end

    id = id:gsub("[^%w_]", "_"):gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if id == "" then id = "ixbooks_book_unknown" end
    return id
end

local function WriteColor(tbl)
    if tbl and tbl[1] then
        net.WriteUInt(1, 8)
        net.WriteUInt(tbl[1], 8)
        net.WriteUInt(tbl[2], 8)
        net.WriteUInt(tbl[3], 8)
    else
        net.WriteUInt(0, 8)
        net.WriteUInt(0, 8)
        net.WriteUInt(0, 8)
        net.WriteUInt(0, 8)
    end
end

local function ReadColor()
    local flag = net.ReadUInt(8)
    local r = net.ReadUInt(8)
    local g = net.ReadUInt(8)
    local b = net.ReadUInt(8)
    if flag == 0 then return nil end
    return {r, g, b}
end

local function WriteArchiveBookPayload(uniqueID, cfg)
    net.WriteString(uniqueID or "")
    net.WriteString(cfg.bookTitle or "")
    net.WriteString(cfg.bookAuthor or "")
    net.WriteString(cfg.bookContent or "")
    net.WriteString(cfg.bookCoverStyle or "classic")
    net.WriteBool(cfg.bookDualPage and true or false)
    net.WriteString(cfg.bookTitleFont or "Roboto")
    net.WriteUInt(math.Clamp(math.floor(tonumber(cfg.bookTitleFontSize) or 26), 8, 48), 8)
    net.WriteString(cfg.bookCoverImageURL or "")
    net.WriteString(cfg.bookModel or "")
    WriteColor(cfg.bookCoverColor)
    WriteColor(cfg.bookTextColor)
    WriteColor(cfg.bookAccentColor)
    WriteColor(cfg.bookPageColor)
    WriteColor(cfg.bookBodyColor)
    WriteColor(cfg.bookHeadColor)
    WriteColor(cfg.bookQuoteBGColor)
    WriteColor(cfg.bookQuoteBarColor)
    WriteColor(cfg.bookCodeBGColor)
    WriteColor(cfg.bookCodeTextColor)
    WriteColor(cfg.bookHrColor)
    WriteColor(cfg.bookTableHdrColor)
    WriteColor(cfg.bookTableLineColor)
    WriteColor(cfg.bookNavBtnColor)
    WriteColor(cfg.bookNavHoverColor)
    WriteColor(cfg.bookNavTextColor)
    WriteColor(cfg.bookChartBarColor)
    WriteColor(cfg.bookChartGridColor)
end

function PLUGIN:_RegisterArchivedItem(uniqueID)
    local data = ixBooksArchive[uniqueID]
    if not data then return nil end

    local item = ix.item.list[uniqueID]
    if item and item.isArchivedBook ~= true then
        return nil
    end

    if not item then
        item = ix.item.Register(uniqueID, "base_books", false, nil, true)
        if not item then return nil end
    end

    item.name = data.bookTitle or "Untitled"
    item.description = "by " .. (data.bookAuthor or "Unknown")
    item.model = data.bookModel or "models/props_junk/garbage_newspaper002a.mdl"
    item.isArchivedBook = true
    item.archivedID = uniqueID
    item.isGenerated = true

    for _, key in ipairs(FIELDS) do
        item[key] = data[key]
    end

    return item
end

function PLUGIN:RegisterAllArchivedBooks()
    for uniqueID in pairs(ixBooksArchive) do
        self:_RegisterArchivedItem(uniqueID)
    end
end

if SERVER then
    local function SnapshotFromItem(item)
        local out = {}
        for _, k in ipairs(FIELDS) do
            local val = item.GetBookField and item:GetBookField(k, item[k]) or item[k]
            if val ~= nil then out[k] = val end
        end
        return out
    end

    local function ReadBookCfgFromNet()
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
        cfg.bookCoverColor     = ReadColor()
        cfg.bookTextColor      = ReadColor()
        cfg.bookAccentColor    = ReadColor()
        cfg.bookPageColor      = ReadColor()
        cfg.bookBodyColor      = ReadColor()
        cfg.bookHeadColor      = ReadColor()
        cfg.bookQuoteBGColor   = ReadColor()
        cfg.bookQuoteBarColor  = ReadColor()
        cfg.bookCodeBGColor    = ReadColor()
        cfg.bookCodeTextColor  = ReadColor()
        cfg.bookHrColor        = ReadColor()
        cfg.bookTableHdrColor  = ReadColor()
        cfg.bookTableLineColor = ReadColor()
        cfg.bookNavBtnColor    = ReadColor()
        cfg.bookNavHoverColor  = ReadColor()
        cfg.bookNavTextColor   = ReadColor()
        cfg.bookChartBarColor  = ReadColor()
        cfg.bookChartGridColor = ReadColor()
        return cfg
    end

    local function RemoveAllInstancesOfUniqueID(uniqueID)
        local removed = 0

        for _, ply in ipairs(player.GetAll()) do
            local char = ply:GetCharacter()
            local inv = char and char:GetInventory()
            if inv then
                for _, item in pairs(inv:GetItems(true)) do
                    if item.uniqueID == uniqueID then
                        item:Remove()
                        removed = removed + 1
                    end
                end
            end
        end

        for _, ent in ipairs(ents.GetAll()) do
            if not IsValid(ent) then continue end

            if ent:GetClass() == "ix_item" and ent.GetItemTable then
                local it = ent:GetItemTable()
                if it and it.uniqueID == uniqueID then
                    ent:Remove()
                    removed = removed + 1
                end
            end

            local inv = ent.GetInventory and ent:GetInventory()
            if inv then
                for _, item in pairs(inv:GetItems(true)) do
                    if item.uniqueID == uniqueID then
                        item:Remove()
                        removed = removed + 1
                    end
                end
            end
        end

        local esc = sql.SQLStr(uniqueID)
        local pre = sql.Query("SELECT COUNT(*) AS c FROM ix_items WHERE unique_id = " .. esc .. ";")
        local offline = (pre and pre[1] and tonumber(pre[1].c)) or 0
        if offline > 0 then
            sql.Query("DELETE FROM ix_items WHERE unique_id = " .. esc .. ";")
            removed = removed + offline
        end

        return removed
    end

    function PLUGIN:SaveData()
        self:SetData(ixBooksArchive)
    end

    function PLUGIN:LoadData()
        ixBooksArchive = self:GetData() or {}
        self:RegisterAllArchivedBooks()
        print("[ix_books] Loaded " .. table.Count(ixBooksArchive) .. " archived books.")
        timer.Simple(1, function()
            if IsValid(game.GetWorld()) then
                self:SyncArchivedBooks()
            end
        end)
    end

    function PLUGIN:SyncArchivedBooks(target)
        net.Start("ixBooksArchiveSync")
        net.WriteTable(ixBooksArchive)
        if IsValid(target) then net.Send(target) else net.Broadcast() end
    end

    function PLUGIN:PlayerInitialSpawn(client)
        timer.Simple(2, function()
            if IsValid(client) then
                self:SyncArchivedBooks(client)
            end
        end)
    end

    function ArchiveBook(item, client, requestedID)
        if not IsValid(client) or not item then return end

        local finalID = NormalizeArchiveID(
            requestedID,
            item.GetBookTitle and item:GetBookTitle() or item:GetData("bookTitle", item.bookTitle),
            item.GetBookAuthor and item:GetBookAuthor() or item:GetData("bookAuthor", item.bookAuthor)
        )

        local existing = ix.item.list[finalID]
        if existing and existing.isArchivedBook ~= true then
            ix.util.NotifyLocalized("ixbook_archive_id_conflict", client, finalID)
            return
        end

        ixBooksArchive[finalID] = SnapshotFromItem(item)
        PLUGIN:_RegisterArchivedItem(finalID)
        PLUGIN:SaveData()
        PLUGIN:SyncArchivedBooks()

        if existing and existing.isArchivedBook then
            ix.util.NotifyLocalized("ixbook_archive_replaced", client, finalID)
        else
            ix.util.NotifyLocalized("ixbook_archived", client, finalID)
        end
    end

    function UnarchiveBook(uniqueID, client)
        if not ixBooksArchive[uniqueID] then
            ix.util.NotifyLocalized("ixbook_archive_unknown", client, tostring(uniqueID))
            return
        end

        local removedCount = RemoveAllInstancesOfUniqueID(uniqueID)
        ixBooksArchive[uniqueID] = nil
        PLUGIN:SaveData()
        PLUGIN:SyncArchivedBooks()

        if IsArchivedItemID(uniqueID) then
            ix.item.list[uniqueID] = nil
        end

        ix.util.NotifyLocalized("ixbook_archive_removed", client, uniqueID)
        ix.util.NotifyLocalized("ixbook_archive_removed_count", client, tostring(removedCount))
    end

    net.Receive("ixBooksArchiveSubmit", function(_, client)
        if not IsValid(client) or not client:IsAdmin() then return end
        local itemID = net.ReadUInt(32)
        local requestedID = net.ReadString()
        local item = ix.item.instances[itemID]
        if not item then return end

        local char = client:GetCharacter()
        local inv = char and char:GetInventory()
        if not inv or item.invID ~= inv:GetID() then
            ix.util.NotifyLocalized("ixbook_archive_own_inventory_only", client)
            return
        end

        ArchiveBook(item, client, requestedID)
    end)

    net.Receive("ixBooksArchiveAction", function(_, client)
        if not IsValid(client) or not client:IsAdmin() then return end
        local action = net.ReadString()
        local uniqueID = net.ReadString()
        local data = ixBooksArchive[uniqueID]
        if not data then return end

        if action == "spawn" then
            local tr = client:GetEyeTraceNoCursor()
            ix.item.Spawn(uniqueID, tr.HitPos + Vector(0, 0, 8))
            ix.util.NotifyLocalized("ixbook_action_spawned", client, uniqueID)
        elseif action == "give" then
            local char = client:GetCharacter()
            local inv = char and char:GetInventory()
            if inv then
                inv:Add(uniqueID, 1)
                ix.util.NotifyLocalized("ixbook_action_given", client, uniqueID)
            end
        elseif action == "edit" then
            net.Start("ixBooksArchiveEdit")
            WriteArchiveBookPayload(uniqueID, data)
            net.Send(client)
        elseif action == "unarchive" then
            UnarchiveBook(uniqueID, client)
        end
    end)

    net.Receive("ixBooksArchiveSubmitEdited", function(_, client)
        if not IsValid(client) or not client:IsAdmin() then return end
        local uniqueID = net.ReadString()
        if not ixBooksArchive[uniqueID] then
            ix.util.NotifyLocalized("ixbook_archive_unknown", client, tostring(uniqueID))
            return
        end

        local existing = ix.item.list[uniqueID]
        if existing and existing.isArchivedBook ~= true then
            ix.util.NotifyLocalized("ixbook_archive_id_conflict", client, uniqueID)
            return
        end

        ixBooksArchive[uniqueID] = ReadBookCfgFromNet()
        PLUGIN:_RegisterArchivedItem(uniqueID)
        PLUGIN:SaveData()
        PLUGIN:SyncArchivedBooks()
        ix.util.NotifyLocalized("ixbook_archive_updated", client, uniqueID)
    end)
else
    net.Receive("ixBooksArchiveSync", function()
        ixBooksArchive = net.ReadTable() or {}

        for uniqueID, itemTable in pairs(ix.item.list) do
            if itemTable and itemTable.isArchivedBook then
                ix.item.list[uniqueID] = nil
            end
        end

        PLUGIN:RegisterAllArchivedBooks()
        RunConsoleCommand("spawnmenu_reload")
    end)
end
