-- cl_editor.lua
-- Client-side book editor.
-- Depends on cl_book.lua (loaded first) for shared globals:
--   ixBook_GetFont, ixBook_FONT_META, ixBook_DEF, ixBook_BookPalette,
--   ixBook_ParseToCommands, ixBook_CoverStyles, ixBook_OpenBookPanel

if SERVER then return end

-- ══════════════════════════════════════════════════════════════════
--  COLOR PRESETS
-- ══════════════════════════════════════════════════════════════════
local COLOR_PRESETS = {
    { name="Parchemin Classic", coverStyle="classic",
      coverColor={80,40,10}, textColor={240,220,180}, accentColor={140,100,50},
      pageColor={245,235,210}, bodyColor={40,30,20}, headColor={80,40,10},
      quoteBGColor={220,210,185}, quoteBarColor={140,100,50}, codeBGColor={200,190,165},
      codeTextColor={60,40,20}, hrColor={140,110,70}, tableHdrColor={180,150,100},
      tableLineColor={160,130,80}, navBtnColor={100,70,30}, navHoverColor={130,95,45},
      navTextColor={245,235,210}, chartBarColor={140,100,50}, chartGridColor={160,140,110} },
    { name="Océan Profond", coverStyle="dark",
      coverColor={10,20,50}, textColor={180,220,255}, accentColor={60,140,255},
      pageColor={230,240,255}, bodyColor={20,35,70}, headColor={40,100,200},
      quoteBGColor={210,225,250}, quoteBarColor={60,140,255}, codeBGColor={200,218,245},
      codeTextColor={20,40,90}, hrColor={80,130,220}, tableHdrColor={120,175,240},
      tableLineColor={100,155,220}, navBtnColor={20,45,100}, navHoverColor={40,75,160},
      navTextColor={200,230,255}, chartBarColor={60,140,255}, chartGridColor={140,170,220} },
    { name="Forêt Sombre", coverStyle="ornate",
      coverColor={15,40,20}, textColor={200,240,180}, accentColor={80,180,80},
      pageColor={230,245,220}, bodyColor={20,50,25}, headColor={40,120,50},
      quoteBGColor={210,235,200}, quoteBarColor={70,160,70}, codeBGColor={200,225,190},
      codeTextColor={20,60,25}, hrColor={80,150,70}, tableHdrColor={120,195,110},
      tableLineColor={100,170,90}, navBtnColor={20,60,25}, navHoverColor={35,95,40},
      navTextColor={210,245,195}, chartBarColor={80,180,80}, chartGridColor={130,180,120} },
    { name="Aurore Polaire", coverStyle="dark",
      coverColor={8,18,42}, textColor={205,245,255}, accentColor={70,220,200},
      pageColor={228,247,250}, bodyColor={18,42,52}, headColor={20,120,165},
      quoteBGColor={205,235,242}, quoteBarColor={55,170,180}, codeBGColor={188,222,232},
      codeTextColor={16,55,70}, hrColor={70,155,175}, tableHdrColor={115,195,215},
      tableLineColor={95,170,190}, navBtnColor={18,55,72}, navHoverColor={30,88,108},
      navTextColor={215,245,252}, chartBarColor={65,178,188}, chartGridColor={140,198,208} },
    { name="Crépuscule Violet", coverStyle="bordered",
      coverColor={30,15,60}, textColor={230,210,255}, accentColor={160,80,255},
      pageColor={240,230,255}, bodyColor={35,20,65}, headColor={120,60,210},
      quoteBGColor={225,210,250}, quoteBarColor={140,70,230}, codeBGColor={215,200,245},
      codeTextColor={40,20,80}, hrColor={140,80,220}, tableHdrColor={175,130,240},
      tableLineColor={155,110,220}, navBtnColor={35,15,70}, navHoverColor={60,30,120},
      navTextColor={235,215,255}, chartBarColor={150,80,255}, chartGridColor={175,145,230} },
    { name="Sable Ancien", coverStyle="stamp",
      coverColor={54,36,14}, textColor={250,230,190}, accentColor={198,132,62},
      pageColor={250,242,220}, bodyColor={58,40,20}, headColor={145,92,44},
      quoteBGColor={238,223,192}, quoteBarColor={182,118,58}, codeBGColor={230,213,178},
      codeTextColor={62,43,19}, hrColor={174,122,70}, tableHdrColor={205,160,98},
      tableLineColor={186,142,84}, navBtnColor={70,44,18}, navHoverColor={108,68,30},
      navTextColor={248,232,198}, chartBarColor={188,126,70}, chartGridColor={188,160,118} },
    { name="Acier Industriel", coverStyle="minimal",
      coverColor={30,32,36}, textColor={210,215,220}, accentColor={100,180,200},
      pageColor={228,232,238}, bodyColor={28,32,40}, headColor={60,130,170},
      quoteBGColor={210,218,228}, quoteBarColor={80,160,190}, codeBGColor={200,210,222},
      codeTextColor={25,35,50}, hrColor={90,150,180}, tableHdrColor={140,185,210},
      tableLineColor={120,165,195}, navBtnColor={28,35,48}, navHoverColor={50,65,90},
      navTextColor={215,225,235}, chartBarColor={90,170,200}, chartGridColor={155,178,200} },
    { name="Sakura Rose", coverStyle="parchment",
      coverColor={60,20,30}, textColor={255,220,230}, accentColor={230,120,160},
      pageColor={255,240,245}, bodyColor={70,25,40}, headColor={200,80,120},
      quoteBGColor={250,225,235}, quoteBarColor={220,110,150}, codeBGColor={245,215,225},
      codeTextColor={75,25,45}, hrColor={210,120,155}, tableHdrColor={235,165,195},
      tableLineColor={220,145,175}, navBtnColor={70,20,35}, navHoverColor={115,40,65},
      navTextColor={255,230,240}, chartBarColor={225,110,155}, chartGridColor={210,165,185} },
}

local EDITOR_COLOR_FIELDS = {
    { "Cover BG",       "coverColor" },   { "Cover Text",     "textColor"      },
    { "Accent",         "accentColor" },  { "Page BG",        "pageColor"      },
    { "Body Text",      "bodyColor" },    { "Headings",       "headColor"      },
    { "Quote BG",       "quoteBGColor" }, { "Quote Bar",      "quoteBarColor"  },
    { "Code BG",        "codeBGColor" },  { "Code Text",      "codeTextColor"  },
    { "H-Rule",         "hrColor" },      { "Table Header",   "tableHdrColor"  },
    { "Table Borders",  "tableLineColor"},{ "Nav Button",     "navBtnColor"    },
    { "Nav Hover",      "navHoverColor" },{ "Nav Arrows",     "navTextColor"   },
    { "Chart Bar/Line", "chartBarColor" },{ "Chart Grid",     "chartGridColor" },
}

local EDITOR_DEFAULT_RGB = {
    coverColor={20,25,45}, textColor={220,235,255}, accentColor={90,160,255},
    pageColor={235,240,252}, bodyColor={25,30,55}, headColor={70,110,190},
    quoteBGColor={215,225,245}, quoteBarColor={95,145,235}, codeBGColor={210,220,240},
    codeTextColor={30,45,80}, hrColor={120,145,190}, tableHdrColor={155,185,235},
    tableLineColor={130,160,210}, navBtnColor={30,45,80}, navHoverColor={55,75,120},
    navTextColor={225,235,255}, chartBarColor={90,150,240}, chartGridColor={175,190,225},
}

-- ── Available book models ─────────────────────────────────────────
local BOOK_MODELS = {
    { label="Binder Blue",         model="models/props_lab/binderblue.mdl" },
    { label="Binder Blue Label",   model="models/props_lab/binderbluelabel.mdl" },
    { label="Binder Gray Label A", model="models/props_lab/bindergraylabel01a.mdl" },
    { label="Binder Green",        model="models/props_lab/bindergreen.mdl" },
    { label="Binder Gray Label B", model="models/props_lab/bindergraylabel01b.mdl" },
    { label="Binder Green Label",  model="models/props_lab/bindergreenlabel.mdl" },
    { label="Binder Red Label",    model="models/props_lab/binderredlabel.mdl" },
    { label="Clipboard",           model="models/props_lab/clipboard.mdl" },
    { label="Newspaper",           model="models/props_junk/garbage_newspaper001a.mdl" },
}

-- ══════════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════════
local function strTrim(s)
    if not s then return "" end
    return (tostring(s):gsub("^%s+",""):gsub("%s+$",""))
end

local function NetWriteColor(tbl)
    if tbl and tbl[1] then
        net.WriteUInt(1, 8)
        net.WriteUInt(tbl[1], 8); net.WriteUInt(tbl[2], 8); net.WriteUInt(tbl[3], 8)
    else
        net.WriteUInt(0, 8)
        net.WriteUInt(0, 8); net.WriteUInt(0, 8); net.WriteUInt(0, 8)
    end
end

-- Write a full book config over the network (used by both Spawn and EditSubmit)
local function NetWriteBookCfg(cfg)
    net.WriteString(cfg.bookTitle    or cfg.title    or "")
    net.WriteString(cfg.bookAuthor   or cfg.author   or "")
    net.WriteString(cfg.bookContent  or cfg.content  or "")
    net.WriteString(cfg.bookCoverStyle or cfg.coverStyle or "classic")
    net.WriteBool(cfg.bookDualPage   or cfg.dualPage  or false)
    net.WriteString(cfg.bookTitleFont or cfg.titleFont or "Roboto")
    net.WriteUInt(math.Clamp(math.floor(tonumber(cfg.bookTitleFontSize or cfg.titleFontSize) or 26),8,48), 8)
    net.WriteString(cfg.bookCoverImageURL or cfg.coverImageURL or "")
    net.WriteString(cfg.bookModel or cfg.model or "")
    NetWriteColor(cfg.coverColor     or cfg.bookCoverColor)
    NetWriteColor(cfg.textColor      or cfg.bookTextColor)
    NetWriteColor(cfg.accentColor    or cfg.bookAccentColor)
    NetWriteColor(cfg.pageColor      or cfg.bookPageColor)
    NetWriteColor(cfg.bodyColor      or cfg.bookBodyColor)
    NetWriteColor(cfg.headColor      or cfg.bookHeadColor)
    NetWriteColor(cfg.quoteBGColor   or cfg.bookQuoteBGColor)
    NetWriteColor(cfg.quoteBarColor  or cfg.bookQuoteBarColor)
    NetWriteColor(cfg.codeBGColor    or cfg.bookCodeBGColor)
    NetWriteColor(cfg.codeTextColor  or cfg.bookCodeTextColor)
    NetWriteColor(cfg.hrColor        or cfg.bookHrColor)
    NetWriteColor(cfg.tableHdrColor  or cfg.bookTableHdrColor)
    NetWriteColor(cfg.tableLineColor or cfg.bookTableLineColor)
    NetWriteColor(cfg.navBtnColor    or cfg.bookNavBtnColor)
    NetWriteColor(cfg.navHoverColor  or cfg.bookNavHoverColor)
    NetWriteColor(cfg.navTextColor   or cfg.bookNavTextColor)
    NetWriteColor(cfg.chartBarColor  or cfg.bookChartBarColor)
    NetWriteColor(cfg.chartGridColor or cfg.bookChartGridColor)
end

-- ══════════════════════════════════════════════════════════════════
--  MINI COLOR PICKER WIDGET
-- ══════════════════════════════════════════════════════════════════
local function CreateColorPicker(parent, initialRGB, onChange)
    initialRGB = initialRGB or { 128, 128, 128 }
    local curR, curG, curB = initialRGB[1], initialRGB[2], initialRGB[3]

    local swatch = vgui.Create("DButton", parent)
    swatch:SetText(""); swatch:SetSize(24, 22)

    function swatch:GetRGB()  return { curR, curG, curB } end
    function swatch:SetRGB(nr, ng, nb)
        curR, curG, curB = nr, ng, nb
        if onChange then onChange({ curR, curG, curB }) end
    end
    function swatch:Paint(w, h)
        draw.RoundedBox(3, 0, 0, w, h, Color(curR, curG, curB, 255))
        surface.SetDrawColor(Color(255,255,255,60))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    function swatch:DoClick()
        if IsValid(self._picker) then self._picker:Remove(); self._picker = nil; return end
        local mixer = vgui.Create("DColorMixer")
        mixer:SetSize(220, 200); mixer:SetPos(0, 0)
        mixer:SetAlphaBar(false); mixer:SetPalette(false)
        mixer:SetColor(Color(curR, curG, curB, 255))
        local popup = vgui.Create("DFrame")
        popup:SetSize(230, 230); popup:SetTitle("Pick Color")
        popup:SetDeleteOnClose(true); popup:Center(); popup:MakePopup()
        popup:ShowCloseButton(true)
        mixer:SetParent(popup); mixer:SetPos(5, 30)
        function mixer:ValueChanged(col)
            curR = col.r; curG = col.g; curB = col.b
            if onChange then onChange({ curR, curG, curB }) end
        end
        self._picker = popup
        function popup:OnRemoved() swatch._picker = nil end
    end
    return swatch
end

-- ══════════════════════════════════════════════════════════════════
--  PREVIEW COVER HEIGHT
-- ══════════════════════════════════════════════════════════════════
local function EditorCoverPreviewHeight(panelW)
    panelW = math.max(200, panelW - 28)
    return math.Clamp(math.floor(panelW * 1.42), 280, 540)
end

-- ══════════════════════════════════════════════════════════════════
--  EDITOR OPEN FUNCTION
--  editItemID: if non-nil, we're editing an existing item (admin)
-- ══════════════════════════════════════════════════════════════════
local function OpenEditor(iCfg, editItemID, archiveID)
    if IsValid(ix.bookEditor) then ix.bookEditor:Remove() end

    -- Normalize input config so both spawn-new and edit-existing work
    iCfg = iCfg or {}
    local iTitle      = iCfg.bookTitle    or iCfg.title    or ""
    local iAuthor     = iCfg.bookAuthor   or iCfg.author   or ""
    local iContent    = iCfg.bookContent  or iCfg.content  or ""
    local iCoverStyle = iCfg.bookCoverStyle or iCfg.coverStyle or "classic"
    local iDual       = iCfg.bookDualPage or iCfg.dualPage or false
    local iFont       = iCfg.bookTitleFont or iCfg.titleFont or "Roboto"
    local iFontSz     = tonumber(iCfg.bookTitleFontSize or iCfg.titleFontSize) or 26
    local iCoverImg   = iCfg.bookCoverImageURL or iCfg.coverImageURL or ""
    local iModel      = iCfg.bookModel or iCfg.model or BOOK_MODELS[1].model

    local scrW, scrH = ScrW(), ScrH()

    local frame = vgui.Create("DFrame")
    frame:SetSize(math.min(1100, scrW-40), math.min(720, scrH-40))
    frame:Center()
    local titleStr = editItemID and "Edit Book (ID: "..editItemID..")" or "Book Editor"
    frame:SetTitle(titleStr)
    frame:MakePopup(); frame:SetSizable(false); frame:SetDraggable(true)
    ix.bookEditor = frame

    local fw, fh = frame:GetSize()
    local MARGIN    = 6
    local TOOLBAR_H = 32
    local BTN_H     = 24
    local BTN_ROW_Y = fh - BTN_H - MARGIN*2 - 2
    local CONTENT_Y = 24 + TOOLBAR_H + MARGIN*2
    local CONTENT_H = BTN_ROW_Y - CONTENT_Y - MARGIN
    local USABLE_W  = fw - MARGIN*2
    local LEFT_W    = math.floor(USABLE_W * 0.67) - MARGIN
    local PREV_X    = MARGIN + LEFT_W + MARGIN
    local PREV_W    = fw - PREV_X - MARGIN

    -- ── Toolbar ───────────────────────────────────────────────────
    local toolbar = vgui.Create("DPanel", frame)
    toolbar:SetPos(MARGIN, 24+MARGIN); toolbar:SetSize(fw-MARGIN*2, TOOLBAR_H)

    local textEntry  -- forward declared
    local toolX = 4
    local snippets = {
        { "# H1",     "\n# Heading\n" },        { "## H2",    "\n## Heading\n" },
        { "### H3",   "\n### Heading\n" },       { "*Bold*",   "*bold text*" },
        { "> Quote",  "> Your quote here\n" },   { "```Code```","```\ncode here\n```\n" },
        { "- List",   "- Item 1\n- Item 2\n" },  { "Table",    "| Col A | Col B |\n| Val 1 | Val 2 |\n" },
        { "[color]",  "[color:red]text[/color]" },{ "[font]",   "[font:Arial]text[/font]" },
        { "[link]",   "[link:https://example.com]label[/link]" },
        { "[img]",    "[img:https://example.com/img.png|320x120]\n" },
        { "[chart]",  "[chart:bar|A:30,B:70,C:50]\n" },
        { "[graph]",  "[chart:line|A:30,B:70,C:50]\n" },
        { "---",      "\n---\n" },
    }
    for _, snip in ipairs(snippets) do
        local s = snip
        local btn = vgui.Create("DButton", toolbar)
        btn:SetSize(64,22); btn:SetPos(toolX,5); btn:SetText("")
        btn._rawText = s[1]
        function btn:Paint(w,h)
            derma.SkinHook("Paint","Button",self,w,h)
            draw.SimpleText(self._rawText or "","DermaDefault",w/2,h/2,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        end
        function btn:DoClick()
            if IsValid(textEntry) then textEntry:SetValue(textEntry:GetValue()..s[2]) end
        end
        toolX = toolX + 68
    end

    -- ── Left scroll ───────────────────────────────────────────────
    local leftScroll = vgui.Create("DScrollPanel", frame)
    leftScroll:SetPos(MARGIN, CONTENT_Y); leftScroll:SetSize(LEFT_W, CONTENT_H)
    local inner  = leftScroll:GetCanvas()
    local ly     = 4
    local innerW = LEFT_W - 20

    local function Lbl(txt)
        local l = vgui.Create("DLabel", inner)
        l:SetPos(4,ly); l:SetSize(innerW-8,16); l:SetText(txt)
        l:SetFont("ixBook_EditorLbl"); l:SetTextColor(Color(220,220,220))
        ly = ly + 18; return l
    end
    local function Inp(ph, h)
        h = h or 24
        local inp = vgui.Create("DTextEntry", inner)
        inp:SetPos(4,ly); inp:SetSize(innerW-8,h); inp:SetPlaceholderText(ph)
        ly = ly + h + 4; return inp
    end
    local function Sep()
        local p = vgui.Create("DPanel", inner)
        p:SetPos(4,ly); p:SetSize(innerW-8,1); ly = ly+5; return p
    end

    Lbl("Title:")
    local inpT = Inp("Book title...")
    inpT:SetValue(iTitle)

    Lbl("Author:")
    local inpA = Inp("Author name...")
    inpA:SetValue(iAuthor)

    Lbl("Cover Image URL (optional):")
    local inpCoverImg = Inp("https://... or material path")
    inpCoverImg:SetValue(iCoverImg)
    ly = ly + 2

    Sep()

    -- ── Model picker ──────────────────────────────────────────────
    Lbl("Item Model:")
    local comboModel = vgui.Create("DComboBox", inner)
    comboModel:SetPos(4,ly); comboModel:SetSize(innerW-8,22)
    local selectedModelIdx = 1
    for i, m in ipairs(BOOK_MODELS) do
        comboModel:AddChoice(m.label, m.model)
        if m.model == iModel then selectedModelIdx = i end
    end
    comboModel:ChooseOptionID(selectedModelIdx)
    ly = ly + 28

    Sep()

    Lbl("Cover Style:")
    local comboStyle = vgui.Create("DComboBox", inner)
    comboStyle:SetPos(4,ly); comboStyle:SetSize(innerW-8,22)
    local styleList = { "classic","bordered","minimal","ornate","stamp","parchment","dark" }
    local selectedStyleIdx = 1
    for i, st in ipairs(styleList) do
        comboStyle:AddChoice(st, st)
        if st == iCoverStyle then selectedStyleIdx = i end
    end
    comboStyle:ChooseOptionID(selectedStyleIdx)
    ly = ly + 28

    local chkDual = vgui.Create("DCheckBoxLabel", inner)
    chkDual:SetPos(4,ly); chkDual:SetText("Dual page (two columns)")
    chkDual:SetTextColor(Color(220,220,220)); chkDual:SetValue(iDual)
    chkDual:SizeToContents(); ly = ly + 28

    Lbl("Cover Title Font:")
    local inpFont = Inp("Roboto")
    inpFont:SetValue(iFont)

    Lbl("Cover Title Size:")
    local sldSize = vgui.Create("DNumSlider", inner)
    sldSize:SetPos(4,ly); sldSize:SetSize(innerW-8,22); sldSize:SetText("")
    sldSize:SetMinMax(10,48); sldSize:SetDecimals(0); sldSize:SetValue(iFontSz)
    ly = ly + 32

    Sep()

    -- ── Color system ──────────────────────────────────────────────
    local colorValues   = {}
    local colorSwatches = {}

    -- Initialize with incoming config or defaults
    for _, row in ipairs(EDITOR_COLOR_FIELDS) do
        local key  = row[2]
        local incoming = iCfg["book"..key:sub(1,1):upper()..key:sub(2)]
                      or iCfg[key]
        if incoming and incoming[1] then
            colorValues[key] = { incoming[1], incoming[2], incoming[3] }
        else
            local def = EDITOR_DEFAULT_RGB[key]
            colorValues[key] = def and { def[1],def[2],def[3] } or { 128,128,128 }
        end
    end

    Lbl("Color Presets:")
    for pi, preset in ipairs(COLOR_PRESETS) do
        local btn = vgui.Create("DButton", inner)
        btn:SetSize(math.floor((innerW-12)/2), 20)
        local col = (pi-1) % 2
        btn:SetPos(4 + col*(math.floor((innerW-12)/2)+4), ly)
        btn:SetText(preset.name); btn:SetFont("ixBook_EditorLbl")
        local p = preset
        function btn:DoClick()
            for _, row in ipairs(EDITOR_COLOR_FIELDS) do
                local key = row[2]; local val = p[key]
                if val and colorSwatches[key] then
                    colorValues[key] = { val[1],val[2],val[3] }
                    colorSwatches[key]:SetRGB(val[1],val[2],val[3])
                end
            end
            if p.coverStyle then
                for i, st in ipairs(styleList) do
                    if st == p.coverStyle then comboStyle:ChooseOptionID(i); break end
                end
            end
        end
        if col == 1 then ly = ly + 24 end
    end
    if #COLOR_PRESETS % 2 ~= 0 then ly = ly + 24 end
    ly = ly + 6

    Sep()

    Lbl("Colors:")
    local colPickerW = math.floor((innerW-20)/2)
    local colPickerH = 22
    for i, row in ipairs(EDITOR_COLOR_FIELDS) do
        local key  = row[2]
        local def  = colorValues[key] or { 128,128,128 }
        local lbl  = vgui.Create("DLabel", inner)
        lbl:SetFont("ixBook_EditorLbl"); lbl:SetTextColor(Color(200,200,200))
        lbl:SetText(row[1])
        local col  = (i-1) % 2
        local rowY = ly + math.floor((i-1)/2) * (colPickerH+18)
        lbl:SetPos(4 + col*(colPickerW+10), rowY); lbl:SetSize(colPickerW,14)
        local sw = CreateColorPicker(inner, def, function(rgb) colorValues[key] = rgb end)
        sw:SetPos(4 + col*(colPickerW+10), rowY+14); sw:SetWide(colPickerW)
        colorSwatches[key] = sw
    end
    ly = ly + math.ceil(#EDITOR_COLOR_FIELDS/2) * (colPickerH+18) + 8

    Sep()

    Lbl("Content (Markdown):")
    textEntry = vgui.Create("DTextEntry", inner)
    textEntry:SetPos(4,ly); textEntry:SetSize(innerW-8,320)
    textEntry:SetMultiline(true); textEntry:SetFont("ixBook_Code")
    textEntry:SetValue(iContent)
    ly = ly + 328

    inner:SetTall(math.max(ly+8, 500))

    -- ── Build config from editor state ────────────────────────────
    local function GetEditorBookCfg()
        local style = "classic"
        local id = comboStyle:GetSelectedID()
        if id and id > 0 then
            local d = comboStyle:GetOptionData(id)
            if d then style = d end
        end
        local mdl = BOOK_MODELS[1].model
        local mid = comboModel:GetSelectedID()
        if mid and mid > 0 then
            local md = comboModel:GetOptionData(mid)
            if md then mdl = md end
        end
        local cfg = {
            title           = inpT:GetValue(),
            author          = inpA:GetValue(),
            content         = textEntry:GetValue(),
            coverStyle      = style,
            dualPage        = chkDual:GetChecked(),
            titleFont       = inpFont:GetValue() ~= "" and inpFont:GetValue() or "Roboto",
            titleFontSize   = math.floor(sldSize:GetValue()),
            coverImageURL   = strTrim(inpCoverImg:GetValue()),
            model           = mdl,
        }
        for _, row in ipairs(EDITOR_COLOR_FIELDS) do
            cfg[row[2]] = colorValues[row[2]]
        end
        return cfg
    end

    -- ── Live preview ──────────────────────────────────────────────
    local pvPnl = vgui.Create("DPanel", frame)
    pvPnl:SetPos(PREV_X, CONTENT_Y); pvPnl:SetSize(PREV_W, CONTENT_H)
    pvPnl:SetMouseInputEnabled(true)

    local innerPrev = vgui.Create("DPanel", pvPnl)
    innerPrev:SetPaintBackground(false); innerPrev:SetMouseInputEnabled(false)

    local pvCmds          = {}
    local pvScroll        = 0
    local pvCW            = PREV_W - 30
    local pvPal           = ixBook_BookPalette({})
    local pvTotalContentH = 0

    local function Rebuild()
        local cfg = GetEditorBookCfg()
        pvPal  = ixBook_BookPalette(cfg)
        pvCmds = ixBook_ParseToCommands(textEntry:GetValue(), pvCW, pvPal)
        local ch = EditorCoverPreviewHeight(PREV_W)
        pvTotalContentH = 8 + ch + 8
        for _, c in ipairs(pvCmds) do pvTotalContentH = pvTotalContentH + c.h end
        local maxS = math.max(0, pvTotalContentH - pvPnl:GetTall())
        if pvScroll > maxS then pvScroll = maxS end
        innerPrev:SetTall(math.max(pvTotalContentH,1))
    end

    function innerPrev:Paint(iw, ih)
        local cfg    = GetEditorBookCfg()
        local pal    = pvPal
        local coverH = EditorCoverPreviewHeight(iw)
        local sfn    = ixBook_CoverStyles[cfg.coverStyle] or ixBook_CoverStyles["classic"]
        local tSz    = math.Clamp(math.floor(tonumber(cfg.titleFontSize) or 26),10,48)
        local tF     = ixBook_GetFont(cfg.titleFont, tSz, true)
        local mat    = Matrix()
        mat:SetTranslation(Vector(0,8,0))
        cam.PushModelMatrix(mat)
        sfn(iw, coverH, 14, cfg.title, tF, cfg.author, pal.coverBG, pal.coverText, pal.coverAccent, cfg.coverImageURL)
        local yOff = coverH + 8
        for _, cmd in ipairs(pvCmds) do
            cmd.fn(14, yOff, pal, nil, nil)
            yOff = yOff + cmd.h
        end
        cam.PopModelMatrix()
    end

    function pvPnl:Paint(w,h)
        draw.RoundedBox(2, 0, 0, w, h, pvPal.pageBG)
        surface.SetDrawColor(Color(80,80,80,120))
        surface.DrawOutlinedRect(0,0,w,h,1)
    end
    function pvPnl:Think()
        innerPrev:SetWide(self:GetWide())
        innerPrev:SetPos(0, -pvScroll)
    end
    function pvPnl:OnMouseWheeled(d)
        local maxS = math.max(0, pvTotalContentH - self:GetTall())
        pvScroll = math.Clamp(pvScroll - d*30, 0, maxS)
        return true
    end

    local last = 0
    hook.Add("Think","ixBook_EditorRebuild",function()
        if not IsValid(frame) then hook.Remove("Think","ixBook_EditorRebuild"); return end
        if CurTime()-last > 0.2 then Rebuild(); last = CurTime() end
    end)
    function frame:OnRemoved() hook.Remove("Think","ixBook_EditorRebuild") end
    function textEntry:OnTextChanged() Rebuild() end
    function comboStyle:OnSelect()     Rebuild() end
    function sldSize:OnValueChanged()  Rebuild() end

    -- ── Bottom buttons ────────────────────────────────────────────
    local function MakeBtn(lbl, x, bw, fn)
        local b = vgui.Create("DButton", frame)
        b:SetPos(x, BTN_ROW_Y); b:SetSize(bw, BTN_H); b:SetText(lbl)
        b.DoClick = fn; return b
    end

    MakeBtn(L("ixbook_btn_preview"), MARGIN, 110, function()
        local cfg = GetEditorBookCfg()
        -- Map editor cfg keys to OpenBookPanel keys
        ixBook_OpenBookPanel({
            title         = cfg.title,
            author        = cfg.author,
            content       = cfg.content,
            coverStyle    = cfg.coverStyle,
            dualPage      = cfg.dualPage,
            titleFont     = cfg.titleFont,
            titleFontSize = cfg.titleFontSize,
            coverImageURL = cfg.coverImageURL,
            coverColor    = cfg.coverColor,     textColor      = cfg.textColor,
            accentColor   = cfg.accentColor,    pageColor      = cfg.pageColor,
            bodyColor     = cfg.bodyColor,      headColor      = cfg.headColor,
            quoteBGColor  = cfg.quoteBGColor,   quoteBarColor  = cfg.quoteBarColor,
            codeBGColor   = cfg.codeBGColor,    codeTextColor  = cfg.codeTextColor,
            hrColor       = cfg.hrColor,        tableHdrColor  = cfg.tableHdrColor,
            tableLineColor= cfg.tableLineColor, navBtnColor    = cfg.navBtnColor,
            navHoverColor = cfg.navHoverColor,  navTextColor   = cfg.navTextColor,
            chartBarColor = cfg.chartBarColor,  chartGridColor = cfg.chartGridColor,
        })
    end)

    if editItemID then
        -- Edit mode: submit changes to existing item
        MakeBtn(L("ixbook_btn_save_changes"), MARGIN+114, 130, function()
            local cfg = GetEditorBookCfg()
            net.Start("ix_books_edit_submit")
                net.WriteUInt(editItemID, 32)
                NetWriteBookCfg(cfg)
            net.SendToServer()
            frame:Remove()
        end)
    elseif archiveID then
        MakeBtn(L("ixbook_btn_save_archived"), MARGIN+114, 160, function()
            local cfg = GetEditorBookCfg()
            net.Start("ixBooksArchiveSubmitEdited")
                net.WriteString(archiveID)
                NetWriteBookCfg(cfg)
            net.SendToServer()
            frame:Remove()
        end)
    else
        -- New book: spawn into inventory
        MakeBtn(L("ixbook_btn_spawn_inventory"), MARGIN+114, 150, function()
            local cfg = GetEditorBookCfg()
            net.Start("ix_books_spawn")
                NetWriteBookCfg(cfg)
            net.SendToServer()
        end)
    end

    MakeBtn(L("ixbook_btn_copy_content"), MARGIN + ((editItemID or archiveID) and 278 or 268), 120, function()
        SetClipboardText(textEntry:GetValue())
        notification.AddLegacy(L("ixbook_content_copied"), NOTIFY_GENERIC, 1.5)
    end)

    MakeBtn(L("ixbook_btn_close"), fw - MARGIN - 80, 80, function()
        frame:Remove()
    end)

    Rebuild()
end
_G.ixBook_OpenEditor = OpenEditor

-- ══════════════════════════════════════════════════════════════════
--  CONSOLE COMMAND: open blank editor (admin only)
-- ══════════════════════════════════════════════════════════════════
concommand.Add("ix_book_editor", function()
    if not LocalPlayer():IsAdmin() then
        notification.AddLegacy(L("ixbook_admin_only"), NOTIFY_ERROR, 3)
        return
    end
    OpenEditor({}, nil)
end)

-- ══════════════════════════════════════════════════════════════════
--  NET: Open editor pre-filled with item data (from item action)
-- ══════════════════════════════════════════════════════════════════
net.Receive("ix_books_edit", function()
    local itemID = net.ReadUInt(32)

    -- Read all book fields from net
    local function rc()
        local flag = net.ReadUInt(8)
        local r, g, b = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
        if flag == 0 then return nil end
        return { r, g, b }
    end

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

    cfg.coverColor      = rc(); cfg.textColor       = rc(); cfg.accentColor     = rc()
    cfg.pageColor       = rc(); cfg.bodyColor       = rc(); cfg.headColor       = rc()
    cfg.quoteBGColor    = rc(); cfg.quoteBarColor   = rc(); cfg.codeBGColor     = rc()
    cfg.codeTextColor   = rc(); cfg.hrColor         = rc(); cfg.tableHdrColor   = rc()
    cfg.tableLineColor  = rc(); cfg.navBtnColor     = rc(); cfg.navHoverColor   = rc()
    cfg.navTextColor    = rc(); cfg.chartBarColor   = rc(); cfg.chartGridColor  = rc()

    OpenEditor(cfg, itemID)
end)

-- ══════════════════════════════════════════════════════════════════
--  ARCHIVE POPUP
-- ══════════════════════════════════════════════════════════════════
local function OpenArchiveIDPrompt(itemID, defaultID)
    local fr = vgui.Create("DFrame")
    fr:SetSize(420, 140)
    fr:Center()
    fr:SetTitle(L("ixbook_archive_book_title"))
    fr:MakePopup()

    local lbl = vgui.Create("DLabel", fr)
    lbl:SetPos(16, 36)
    lbl:SetSize(390, 20)
    lbl:SetText(L("ixbook_archive_choose_id"))

    local entry = vgui.Create("DTextEntry", fr)
    entry:SetPos(16, 60)
    entry:SetSize(388, 26)
    entry:SetValue(defaultID or "")
    entry:RequestFocus()

    local btn = vgui.Create("DButton", fr)
    btn:SetPos(16, 98)
    btn:SetSize(388, 28)
    btn:SetText(L("ixbook_archive_action"))
    btn.DoClick = function()
        local chosen = string.Trim(entry:GetValue() or "")
        net.Start("ixBooksArchiveSubmit")
            net.WriteUInt(itemID, 32)
            net.WriteString(chosen)
        net.SendToServer()
        fr:Remove()
    end
end

net.Receive("ixBooksArchiveRequest", function()
    local itemID = net.ReadUInt(32)
    local defaultID = net.ReadString()
    OpenArchiveIDPrompt(itemID, defaultID)
end)

-- ══════════════════════════════════════════════════════════════════
--  ARCHIVE MANAGER MENU
-- ══════════════════════════════════════════════════════════════════
local function OpenArchiveManager()
    if not LocalPlayer():IsAdmin() then return end

    local fr = vgui.Create("DFrame")
    fr:SetSize(820, 540)
    fr:Center()
    fr:SetTitle(L("ixbook_archive_manager_title"))
    fr:MakePopup()

    local list = vgui.Create("DListView", fr)
    list:SetPos(10, 30)
    list:SetSize(800, 420)
    list:AddColumn(L("ixbook_col_archive_id"))
    list:AddColumn(L("ixbook_col_title"))
    list:AddColumn(L("ixbook_col_author"))

    for uniqueid, data in SortedPairs(ixBooksArchive or {}) do
        list:AddLine(
            uniqueid,
            data.bookTitle or "Untitled",
            data.bookAuthor or "Unknown"
        )
    end

    local selectedID = nil
    function list:OnRowSelected(_, row)
        selectedID = row:GetColumnText(1)
    end

    local function MakeBtn(lbl, x, fn)
        local b = vgui.Create("DButton", fr)
        b:SetPos(x, 465)
        b:SetSize(150, 28)
        b:SetText(lbl)
        b.DoClick = fn
        return b
    end

    local function SendAction(action)
        if not selectedID then
            notification.AddLegacy(L("ixbook_select_archive_first"), NOTIFY_ERROR, 2)
            return
        end

        if action == "unarchive" then
            Derma_Query(
                L("ixbook_unarchive_confirm_body"),
                L("ixbook_unarchive_confirm_title"),
                L("ixbook_unarchive_confirm_yes"),
                function()
                    net.Start("ixBooksArchiveAction")
                        net.WriteString(action)
                        net.WriteString(selectedID)
                    net.SendToServer()
                    timer.Simple(0.2, function()
                        if IsValid(fr) then fr:Remove() end
                    end)
                end,
                L("ixbook_unarchive_confirm_no"),
                function() end
            )
            return
        end

        net.Start("ixBooksArchiveAction")
            net.WriteString(action)
            net.WriteString(selectedID)
        net.SendToServer()
    end

    MakeBtn(L("ixbook_action_spawn_ground"), 10, function() SendAction("spawn") end)
    MakeBtn(L("ixbook_action_give_me"),      170, function() SendAction("give") end)
    MakeBtn(L("ixbook_action_edit"),         330, function() SendAction("edit") end)
    MakeBtn(L("ixbook_action_unarchive"),    490, function() SendAction("unarchive") end)
    MakeBtn(L("ixbook_action_refresh"),      650, function()
        list:Clear()
        for uniqueid, data in SortedPairs(ixBooksArchive or {}) do
            list:AddLine(uniqueid, data.bookTitle or "Untitled", data.bookAuthor or "Unknown")
        end
    end)
end

net.Receive("ixBooksArchiveOpenMenu", function()
    OpenArchiveManager()
end)

-- ══════════════════════════════════════════════════════════════════
--  OPEN EDITOR FOR ARCHIVED BOOK
-- ══════════════════════════════════════════════════════════════════
net.Receive("ixBooksArchiveEdit", function()
    local archiveID = net.ReadString()

    local function rc()
        local flag = net.ReadUInt(8)
        local r, g, b = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
        if flag == 0 then return nil end
        return { r, g, b }
    end

    local cfg = {
        bookTitle         = net.ReadString(),
        bookAuthor        = net.ReadString(),
        bookContent       = net.ReadString(),
        bookCoverStyle    = net.ReadString(),
        bookDualPage      = net.ReadBool(),
        bookTitleFont     = net.ReadString(),
        bookTitleFontSize = net.ReadUInt(8),
        bookCoverImageURL = net.ReadString(),
        bookModel         = net.ReadString(),
        bookCoverColor    = rc(),
        bookTextColor     = rc(),
        bookAccentColor   = rc(),
        bookPageColor     = rc(),
        bookBodyColor     = rc(),
        bookHeadColor     = rc(),
        bookQuoteBGColor  = rc(),
        bookQuoteBarColor = rc(),
        bookCodeBGColor   = rc(),
        bookCodeTextColor = rc(),
        bookHrColor       = rc(),
        bookTableHdrColor = rc(),
        bookTableLineColor= rc(),
        bookNavBtnColor   = rc(),
        bookNavHoverColor = rc(),
        bookNavTextColor  = rc(),
        bookChartBarColor = rc(),
        bookChartGridColor= rc(),
    }

    OpenEditor(cfg, nil, archiveID)
end)