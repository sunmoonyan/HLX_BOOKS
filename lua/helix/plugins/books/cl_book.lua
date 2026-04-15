-- cl_book.lua
-- Client-side: fonts, palette helpers, Markdown parser, book panel renderer.
-- Receives ix_books_open net message and opens the reading panel.

if SERVER then return end

-- ══════════════════════════════════════════════════════════════════
--  FONT REGISTRY
-- ══════════════════════════════════════════════════════════════════
local _fontCache = {}

local function SafeName(s)
    return tostring(s):gsub("[^%w]", "_")
end

local function GetFont(family, size, bold)
    family = family or "Roboto"
    size   = math.floor(size or 14)
    bold   = bold and true or false
    local key = SafeName(family) .. "_" .. size .. "_" .. (bold and "B" or "N")
    if not _fontCache[key] then
        local name = "ixBook_f_" .. key
        surface.CreateFont(name, {
            font      = family,
            size      = size,
            weight    = bold and 800 or 400,
            antialias = true,
            extended  = true,
        })
        _fontCache[key] = name
    end
    return _fontCache[key]
end

surface.CreateFont("ixBook_Body",     { font="Roboto",      size=14, weight=400, antialias=true, extended=true })
surface.CreateFont("ixBook_Bold",     { font="Roboto",      size=14, weight=800, antialias=true, extended=true })
surface.CreateFont("ixBook_H1",       { font="Roboto",      size=22, weight=800, antialias=true, extended=true })
surface.CreateFont("ixBook_H2",       { font="Roboto",      size=18, weight=800, antialias=true, extended=true })
surface.CreateFont("ixBook_H3",       { font="Roboto",      size=15, weight=800, antialias=true, extended=true })
surface.CreateFont("ixBook_Code",     { font="Courier New", size=13, weight=400, antialias=true })
surface.CreateFont("ixBook_Author",   { font="Roboto",      size=13, weight=400, antialias=true, extended=true })
surface.CreateFont("ixBook_PageNum",  { font="Roboto",      size=12, weight=300, antialias=true, extended=true })
surface.CreateFont("ixBook_EditorBtn",{ font="Roboto",      size=13, weight=600, antialias=true, extended=true })
surface.CreateFont("ixBook_EditorLbl",{ font="Roboto",      size=12, weight=400, antialias=true, extended=true })

local FONT_META = {
    ixBook_Body    = { "Roboto",      14, false },
    ixBook_Bold    = { "Roboto",      14, true  },
    ixBook_H1      = { "Roboto",      22, true  },
    ixBook_H2      = { "Roboto",      18, true  },
    ixBook_H3      = { "Roboto",      15, true  },
    ixBook_Code    = { "Courier New", 13, false },
    ixBook_Author  = { "Roboto",      13, false },
    ixBook_PageNum = { "Roboto",      12, false },
}

-- Expose globally so cl_editor.lua can use them
_G.ixBook_GetFont    = GetFont
_G.ixBook_FONT_META  = FONT_META

-- ══════════════════════════════════════════════════════════════════
--  DEFAULT PALETTE
-- ══════════════════════════════════════════════════════════════════
local DEF = {
    pageBG    = Color(245,235,210),
    shadow    = Color(0,0,0,60),
    body      = Color(40,30,20),
    heading   = Color(80,40,10),
    quoteBG   = Color(220,210,185),
    quoteBar  = Color(140,100,50),
    codeBG    = Color(200,190,165),
    codeText  = Color(60,40,20),
    hr        = Color(140,110,70),
    tableHdr  = Color(180,150,100),
    tableLine = Color(160,130,80),
    navBtn    = Color(100,70,30,200),
    navHover  = Color(130,95,45,230),
    navText   = Color(245,235,210),
    coverBG   = Color(80,40,10),
    coverText = Color(240,220,180),
    accent    = Color(140,100,50),
    chartBar  = Color(100,140,190),
    chartGrid = Color(160,140,110),
    link      = Color(60,110,200),
}
_G.ixBook_DEF = DEF

local NAMED_COLORS = {
    red    = Color(200,60,50),   blue   = Color(60,110,200),
    green  = Color(60,160,80),   yellow = Color(200,180,50),
    orange = Color(210,120,40),  purple = Color(140,70,180),
    white  = Color(240,235,220), grey   = Color(140,130,120),
    gray   = Color(140,130,120), gold   = Color(210,175,60),
    cyan   = Color(60,190,200),  black  = Color(20,20,20),
}

-- ══════════════════════════════════════════════════════════════════
--  SOUNDS
-- ══════════════════════════════════════════════════════════════════
local function PlayPageSound()
    surface.PlaySound("ui/buttonclick.wav")
end

-- ══════════════════════════════════════════════════════════════════
--  IMAGE CACHE
-- ══════════════════════════════════════════════════════════════════
local _imgCache = {}

local function GetImage(src)
    if _imgCache[src] then return _imgCache[src] end
    if src:match("^https?://") then
        _imgCache[src] = Material("vgui/white")
        http.Fetch(src, function(body)
            local fname = "ixbook_" .. util.CRC(src) .. ".png"
            file.Write(fname, body)
            _imgCache[src] = Material("data/" .. fname, "noclamp smooth")
        end, function(err)
            print("[ix_books] image error:", err)
        end)
    else
        _imgCache[src] = Material(src, "noclamp smooth")
    end
    return _imgCache[src]
end

-- ══════════════════════════════════════════════════════════════════
--  INLINE TOKENISER
-- ══════════════════════════════════════════════════════════════════
local function Tokenise(text, baseFontName, baseColor, pal)
    pal = pal or DEF
    local meta   = FONT_META[baseFontName] or FONT_META["ixBook_Body"]
    local tokens = {}

    local colorStack = { baseColor or pal.body }
    local fontStack  = { { meta[1], meta[2], meta[3] } }
    local linkStack  = { { false, "" } }

    local function curColor() return colorStack[#colorStack] end
    local function curFont()  return fontStack[#fontStack] end
    local function curLink()  return linkStack[#linkStack] end

    local function emitPlain(txt)
        if not txt or txt == "" then return end
        local f   = curFont(); local lnk = curLink()
        table.insert(tokens, { text=txt, font=GetFont(f[1],f[2],f[3]), color=curColor(), iscode=false, islink=lnk[1], url=lnk[2] })
    end

    local function emitBold(txt)
        if not txt or txt == "" then return end
        local f   = curFont(); local lnk = curLink()
        table.insert(tokens, { text=txt, font=GetFont(f[1],f[2],true), color=curColor(), iscode=false, islink=lnk[1], url=lnk[2] })
    end

    local function emitCode(txt)
        if not txt or txt == "" then return end
        table.insert(tokens, { text=txt, font="ixBook_Code", color=pal.codeText, iscode=true, islink=false, url="" })
    end

    local function earliest(str, pos)
        local best_s, best_e, best_type, best_cap = nil, nil, nil, nil
        local function try(pattern, typ)
            local s, e, cap = str:find(pattern, pos)
            if s and (not best_s or s < best_s) then
                best_s, best_e, best_type, best_cap = s, e, typ, cap
            end
        end
        try("%[/color%]",         "endcolor")
        try("%[/font%]",          "endfont")
        try("%[/link%]",          "endlink")
        try("%[color:([^%]]+)%]", "startcolor")
        try("%[font:([^%]]+)%]",  "startfont")
        try("%[link:([^%]]+)%]",  "startlink")
        try("%*([^%*\n]+)%*",     "bold")
        try("`(.-)`",             "code")
        return best_s, best_e, best_type, best_cap
    end

    local pos = 1
    local len = #text
    while pos <= len do
        local s, e, typ, cap = earliest(text, pos)
        if not s then emitPlain(text:sub(pos)); break end
        if s > pos then emitPlain(text:sub(pos, s-1)) end
        if     typ == "endcolor"   then if #colorStack > 1 then table.remove(colorStack) end; pos = e+1
        elseif typ == "endfont"    then if #fontStack  > 1 then table.remove(fontStack)  end; pos = e+1
        elseif typ == "endlink"    then
            if #linkStack  > 1 then table.remove(linkStack)  end
            if #colorStack > 1 then table.remove(colorStack) end
            pos = e+1
        elseif typ == "startcolor" then
            local col = NAMED_COLORS[cap:lower()]
            if not col then
                local r,g,b = cap:match("^#(%x%x)(%x%x)(%x%x)$")
                if r then col = Color(tonumber(r,16),tonumber(g,16),tonumber(b,16)) end
            end
            table.insert(colorStack, col or curColor()); pos = e+1
        elseif typ == "startfont"  then
            local f = curFont()
            table.insert(fontStack, { cap, f[2], f[3] }); pos = e+1
        elseif typ == "startlink"  then
            table.insert(linkStack,  { true, cap })
            table.insert(colorStack, pal.link); pos = e+1
        elseif typ == "bold"       then emitBold(cap); pos = e+1
        elseif typ == "code"       then emitCode(cap); pos = e+1
        else pos = pos + 1
        end
    end
    return tokens
end

local function Strip(t)
    t = t:gsub("%[/?color[^%]]*%]",""):gsub("%[/?font[^%]]*%]","")
          :gsub("%[/?link[^%]]*%]",""):gsub("%*([^%*\n]+)%*","%1"):gsub("`(.-)`","%1")
    return t
end

local function DrawTokens(tokens, x, y, codeBG, linkStore, linkColor)
    linkColor = linkColor or DEF.link
    local cx = x
    for _, tok in ipairs(tokens) do
        surface.SetFont(tok.font)
        local tw, th = surface.GetTextSize(tok.text)
        if tok.iscode then draw.RoundedBox(2, cx-2, y-1, tw+4, th+2, codeBG) end
        if tok.islink then
            surface.SetDrawColor(linkColor)
            surface.DrawLine(cx, y+th, cx+tw, y+th)
            if linkStore then table.insert(linkStore, { cx, y, cx+tw, y+th+1, tok.url }) end
        end
        draw.SimpleText(tok.text, tok.font, cx, y, tok.color)
        cx = cx + tw
    end
    return cx - x
end

local function WrapLine(raw, baseFontName, baseColor, maxW, pal)
    pal = pal or DEF
    local words = {}
    for w in raw:gmatch("%S+") do table.insert(words, w) end
    if #words == 0 then return { Tokenise("", baseFontName, baseColor, pal) } end
    local lines = {}
    local cur   = ""
    surface.SetFont(baseFontName or "ixBook_Body")
    for _, w in ipairs(words) do
        local test = cur == "" and w or (cur .. " " .. w)
        if surface.GetTextSize(Strip(test)) > maxW and cur ~= "" then
            table.insert(lines, cur); cur = w
        else
            cur = test
        end
    end
    if cur ~= "" then table.insert(lines, cur) end
    local out = {}
    for _, l in ipairs(lines) do table.insert(out, Tokenise(l, baseFontName, baseColor, pal)) end
    return out
end

-- ══════════════════════════════════════════════════════════════════
--  PALETTE BUILDER
-- ══════════════════════════════════════════════════════════════════
local function BookPalette(cfg)
    cfg = cfg or {}
    local function rc(t, def)
        if t and t[1] then return Color(t[1], t[2], t[3]) end
        return def
    end
    return {
        pageBG      = rc(cfg.pageColor,      DEF.pageBG),
        body        = rc(cfg.bodyColor,      DEF.body),
        heading     = rc(cfg.headColor,      DEF.heading),
        accent      = rc(cfg.accentColor,    DEF.accent),
        quoteBG     = rc(cfg.quoteBGColor,   DEF.quoteBG),
        quoteBar    = rc(cfg.quoteBarColor,  DEF.quoteBar),
        codeBG      = rc(cfg.codeBGColor,    DEF.codeBG),
        codeText    = rc(cfg.codeTextColor,  DEF.codeText),
        hr          = rc(cfg.hrColor,        DEF.hr),
        tableHdr    = rc(cfg.tableHdrColor,  DEF.tableHdr),
        tableLine   = rc(cfg.tableLineColor, DEF.tableLine),
        navBtn      = rc(cfg.navBtnColor,    DEF.navBtn),
        navHover    = rc(cfg.navHoverColor,  DEF.navHover),
        navText     = rc(cfg.navTextColor,   DEF.navText),
        coverBG     = rc(cfg.coverColor,     DEF.coverBG),
        coverText   = rc(cfg.textColor,      DEF.coverText),
        coverAccent = rc(cfg.accentColor,    DEF.accent),
        chartBar    = rc(cfg.chartBarColor,  DEF.chartBar),
        chartGrid   = rc(cfg.chartGridColor, DEF.chartGrid),
        link        = DEF.link,
        shadow      = DEF.shadow,
    }
end
_G.ixBook_BookPalette = BookPalette

-- ══════════════════════════════════════════════════════════════════
--  HEADING PARSER
-- ══════════════════════════════════════════════════════════════════
local function MatchHeadingLine(line)
    local count = 0
    for i = 1, #line do
        if line:sub(i,i) == "#" then count = count + 1 else break end
    end
    if count == 0 or count > 6 then return nil end
    local rest = line:sub(count+1)
    if rest:sub(1,1) ~= " " then return nil end
    local body = rest:match("^%s*(.-)%s*$")
    if not body or body == "" then return nil end
    return { type="h", lv=count, text=body }
end

-- ══════════════════════════════════════════════════════════════════
--  COPY BUTTON STORE
--  We collect copy button hotspots during paint, then check them in
--  OnMousePressed so code blocks can be copied without needing to
--  create real child panels inside a custom DPanel.
-- ══════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════
--  MARKDOWN → DRAW-COMMAND LIST
-- ══════════════════════════════════════════════════════════════════
local function ParseToCommands(raw, contentW, palIn)
    local pal   = palIn or DEF
    local cmds  = {}
    local lineH = 18

    local function add(h, fn)  table.insert(cmds, { h=h, fn=fn }) end
    local function blank(h)    add(h or 9, function() end) end

    local blocks = {}
    local inCode = false
    local codeBuf= {}

    for line in (raw.."\n"):gmatch("([^\n]*)\n") do
        line = line:gsub("\r","")
        if inCode then
            if line:match("^```") then
                table.insert(blocks, { type="codeblock", lines=codeBuf })
                codeBuf = {}; inCode = false
            else
                table.insert(codeBuf, line)
            end
        elseif line:match("^```") then
            inCode = true
        elseif line:match("^%[img:") then
            local inner = line:match("^%[img:(.-)%]$") or line:match("^%[img:(.*)$") or ""
            local url, dims = inner:match("^(.-)|(%d+x%d+)$")
            url = url or inner
            local iw, ih = 200, 120
            if dims then
                local a,b = dims:match("(%d+)x(%d+)")
                iw, ih = tonumber(a) or 200, tonumber(b) or 120
            end
            table.insert(blocks, { type="image", url=url, iw=iw, ih=ih })
        elseif line:match("^%[chart:") then
            local spec = line:match("^%[chart:(.-)%]$") or line:match("^%[chart:(.+)")
            table.insert(blocks, { type="chart", spec=spec })
        elseif line:match("^%-%-%-+$") then
            table.insert(blocks, { type="hr" })
        else
            local hb = MatchHeadingLine(line)
            if hb then
                table.insert(blocks, hb)
            elseif line:match("^>%s?") then
                local qt   = line:match("^>%s?(.*)")
                local prev = blocks[#blocks]
                if prev and prev.type=="quote" then table.insert(prev.lines, qt)
                else table.insert(blocks, { type="quote", lines={qt} }) end
            elseif line:match("^|") and line:match("|$") and not line:match("^|%s*%-") then
                local cells = {}
                for cell in line:gmatch("|([^|]+)") do
                    table.insert(cells, cell:match("^%s*(.-)%s*$"))
                end
                local prev = blocks[#blocks]
                if prev and prev.type=="table" then table.insert(prev.rows, { cells=cells })
                else table.insert(blocks, { type="table", rows={{ cells=cells, isHdr=true }} }) end
            elseif line:match("^[%-%*%+]%s") then
                local t    = line:match("^[%-%*%+]%s(.*)")
                local prev = blocks[#blocks]
                if prev and prev.type=="ul" then table.insert(prev.items, t)
                else table.insert(blocks, { type="ul", items={t} }) end
            elseif line:match("^%d+%.%s") then
                local t    = line:match("^%d+%.%s(.*)")
                local prev = blocks[#blocks]
                if prev and prev.type=="ol" then table.insert(prev.items, t)
                else table.insert(blocks, { type="ol", items={t} }) end
            elseif line:match("^%s*$") then
                table.insert(blocks, { type="blank" })
            else
                table.insert(blocks, { type="p", text=line })
            end
        end
    end

    for _, blk in ipairs(blocks) do
        local bt = blk.type

        if bt=="blank" then
            blank()

        elseif bt=="hr" then
            add(14, function(x,y,C)
                surface.SetDrawColor(C.hr)
                surface.DrawLine(x, y+6, x+contentW, y+6)
            end)

        elseif bt=="h" then
            local lv    = blk.lv
            local fname = lv==1 and "ixBook_H1" or lv==2 and "ixBook_H2" or "ixBook_H3"
            local cText = blk.text; local cFN = fname
            local wrapped = WrapLine(cText, cFN, pal.heading, contentW, pal)
            for _, tl in ipairs(wrapped) do
                local ctl = tl
                add(lv==1 and 26 or lv==2 and 20 or 16, function(x,y,C,ls) DrawTokens(ctl,x,y,C.codeBG,ls,C.link) end)
            end
            if lv <= 2 then
                add(3, function(x,y,C)
                    surface.SetDrawColor(C.accent)
                    surface.DrawRect(x,y,contentW,1)
                end)
            end
            blank(6)

        elseif bt=="p" then
            local wrapped = WrapLine(blk.text, "ixBook_Body", pal.body, contentW, pal)
            for _, tl in ipairs(wrapped) do
                local ctl = tl
                add(lineH, function(x,y,C,ls) DrawTokens(ctl,x,y,C.codeBG,ls,C.link) end)
            end
            blank(3)

        elseif bt=="quote" then
            local cLines  = blk.lines
            local totalH  = #cLines * lineH + 10
            add(totalH+4, function(x,y,C,ls)
                draw.RoundedBox(2,x,y,contentW,totalH,C.quoteBG)
                surface.SetDrawColor(C.quoteBar)
                surface.DrawRect(x,y,4,totalH)
                for li, ql in ipairs(cLines) do
                    local toks = Tokenise(ql,"ixBook_Body",C.body,C)
                    DrawTokens(toks, x+12, y+4+(li-1)*lineH, C.codeBG, ls, C.link)
                end
            end)

        elseif bt=="ul" then
            for _, item in ipairs(blk.items) do
                local wrapped = WrapLine(item,"ixBook_Body",pal.body,contentW-16,pal)
                for li, tl in ipairs(wrapped) do
                    local ctl = tl; local cLi = li
                    add(lineH, function(x,y,C,ls)
                        if cLi==1 then draw.SimpleText("•","ixBook_Body",x+4,y,C.heading) end
                        DrawTokens(ctl,x+16,y,C.codeBG,ls,C.link)
                    end)
                end
            end
            blank(4)

        elseif bt=="ol" then
            for idx, item in ipairs(blk.items) do
                local wrapped = WrapLine(item,"ixBook_Body",pal.body,contentW-22,pal)
                for li, tl in ipairs(wrapped) do
                    local ctl = tl; local cLi = li; local cIdx = idx
                    add(lineH, function(x,y,C,ls)
                        if cLi==1 then draw.SimpleText(cIdx..".","ixBook_Bold",x+4,y,C.heading) end
                        DrawTokens(ctl,x+22,y,C.codeBG,ls,C.link)
                    end)
                end
            end
            blank(4)

        elseif bt=="codeblock" then
            -- ── Code block with copy button ───────────────────────
            local cLines   = blk.lines
            local codeText = table.concat(cLines, "\n")
            local cbH      = #cLines * 16 + 10
            local COPY_W, COPY_H = 52, 16
            -- copyZones is populated per-frame and read in OnMousePressed
            add(cbH+4, function(x,y,C,_,copyZones)
                draw.RoundedBox(4, x, y, contentW, cbH, C.codeBG)
                for li, cl in ipairs(cLines) do
                    draw.SimpleText(cl, "ixBook_Code", x+8, y+4+(li-1)*16, C.codeText)
                end
                -- Copy button (top-right of block)
                local bx = x + contentW - COPY_W - 4
                local by = y + 4
                local isHov = false
                -- We store the zone for hit-testing; hovered state is resolved in the Think hook
                if copyZones then
                    table.insert(copyZones, { bx=bx, by=by, bw=COPY_W, bh=COPY_H, text=codeText })
                    -- Check hover from stored mouse pos (set in Think)
                    local mx = ixBook_CopyMouseX or -9999
                    local my = ixBook_CopyMouseY or -9999
                    if mx >= bx and mx <= bx+COPY_W and my >= by and my <= by+COPY_H then
                        isHov = true
                    end
                end
                local btnCol = isHov and C.accent or Color(60,60,60,180)
                draw.RoundedBox(3, bx, by, COPY_W, COPY_H, btnCol)
                draw.SimpleText("Copy","ixBook_PageNum",bx+COPY_W/2,by+COPY_H/2,Color(240,240,240),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            end)
            blank(4)

        elseif bt=="table" then
            local colW = {}
            surface.SetFont("ixBook_Body")
            for _, row in ipairs(blk.rows) do
                for ci, cell in ipairs(row.cells) do
                    local tw = surface.GetTextSize(Strip(cell)) + 16
                    colW[ci] = math.max(colW[ci] or 0, tw)
                end
            end
            local tot = 0
            for _, w in ipairs(colW) do tot = tot + w end
            local sc = math.min(1, contentW / math.max(tot, 1))
            for i, w in ipairs(colW) do colW[i] = math.floor(w * sc) end
            local rH = lineH + 6
            local tH = #blk.rows * rH + 4
            local cR = blk.rows; local cCW = colW; local cRH = rH
            add(tH, function(x,y,C,ls)
                for ri, row in ipairs(cR) do
                    local ry = y + (ri-1)*cRH
                    if row.isHdr then draw.RoundedBox(0,x,ry,contentW,cRH,C.tableHdr) end
                    surface.SetDrawColor(C.tableLine)
                    surface.DrawLine(x, ry+cRH, x+contentW, ry+cRH)
                    local cx2 = x
                    for ci, cell in ipairs(row.cells) do
                        local cw  = cCW[ci] or 60
                        local fn  = row.isHdr and "ixBook_Bold" or "ixBook_Body"
                        local toks = Tokenise(cell,fn,C.body,C)
                        DrawTokens(toks, cx2+4, ry+4, C.codeBG, ls, C.link)
                        surface.SetDrawColor(C.tableLine)
                        surface.DrawLine(cx2+cw, ry, cx2+cw, ry+cRH)
                        cx2 = cx2 + cw
                    end
                end
            end)
            blank(4)

        elseif bt=="image" then
            local cURL = blk.url
            local cIW  = math.min(blk.iw, contentW)
            local cIH  = blk.ih
            add(cIH+8, function(x,y,C)
                local mat = GetImage(cURL)
                if mat and not mat:IsError() then
                    surface.SetDrawColor(255,255,255,255)
                    surface.SetMaterial(mat)
                    surface.DrawTexturedRect(x+(contentW-cIW)/2, y, cIW, cIH)
                else
                    draw.RoundedBox(4,x,y,contentW,cIH,C.quoteBG)
                    draw.SimpleText("[img: "..cURL.."]","ixBook_Code",x+contentW/2,y+cIH/2,C.body,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                end
            end)
            blank(4)

        elseif bt=="chart" then
            local cSpec  = blk.spec
            local chartH = 120
            add(chartH+10, function(x,y,C)
                local kind, data = cSpec:match("^(%w+)|(.+)$")
                kind = kind or "bar"; data = data or cSpec
                local entries = {}
                for pair in data:gmatch("[^,]+") do
                    local lbl, val = pair:match("^(.-):(%-?%d+%.?%d*)$")
                    if lbl and val then table.insert(entries, { label=lbl, val=tonumber(val) }) end
                end
                if #entries == 0 then
                    draw.SimpleText("[chart: bad spec]","ixBook_Code",x+4,y+4,C.body); return
                end
                local maxV = 0
                for _, e in ipairs(entries) do if e.val > maxV then maxV = e.val end end
                if maxV == 0 then maxV = 1 end
                local cw = contentW; local ch = chartH; local baseY = y+ch-20
                surface.SetDrawColor(C.chartGrid)
                for gi = 0, 4 do surface.DrawLine(x+16,y+(ch-20)*gi/4,x+cw,y+(ch-20)*gi/4) end
                surface.SetDrawColor(C.body)
                surface.DrawLine(x+16,y,x+16,baseY+1)
                surface.DrawLine(x+16,baseY,x+cw,baseY)
                if kind == "bar" then
                    local bW = math.floor((cw-20)/#entries) - 4
                    for ei, e in ipairs(entries) do
                        local bx = x+16+(ei-1)*(bW+4)+2
                        local bh = math.floor((e.val/maxV)*(ch-22))
                        draw.RoundedBox(2, bx, baseY-bh, bW, bh, C.chartBar)
                        draw.SimpleText(tostring(e.val),"ixBook_PageNum",bx+bW/2,baseY-bh-12,C.heading,TEXT_ALIGN_CENTER)
                        draw.SimpleText(e.label,"ixBook_PageNum",bx+bW/2,baseY+4,C.body,TEXT_ALIGN_CENTER)
                    end
                elseif kind == "line" then
                    local pts = {}
                    for ei, e in ipairs(entries) do
                        local px = x+16+(ei-1)*((cw-16)/math.max(#entries-1,1))
                        local py = baseY - math.floor((e.val/maxV)*(ch-22))
                        table.insert(pts, {px,py})
                        draw.SimpleText(e.label,"ixBook_PageNum",px,baseY+4,C.body,TEXT_ALIGN_CENTER)
                        draw.SimpleText(tostring(e.val),"ixBook_PageNum",px,py-12,C.heading,TEXT_ALIGN_CENTER)
                    end
                    surface.SetDrawColor(C.chartBar)
                    for i = 2, #pts do surface.DrawLine(pts[i-1][1],pts[i-1][2],pts[i][1],pts[i][2]) end
                    for _, pt in ipairs(pts) do draw.RoundedBox(3,pt[1]-3,pt[2]-3,6,6,C.chartBar) end
                end
            end)
            blank(4)
        end
    end

    return cmds
end
_G.ixBook_ParseToCommands = ParseToCommands

-- ══════════════════════════════════════════════════════════════════
--  PAGINATOR
-- ══════════════════════════════════════════════════════════════════
local function Paginate(cmds, usableH, dual)
    local pages = { "cover" }
    if not dual then
        local cur = {}; local used = 0
        table.insert(pages, cur)
        for _, cmd in ipairs(cmds) do
            if used + cmd.h > usableH and used > 0 then
                cur = {}; used = 0; table.insert(pages, cur)
            end
            table.insert(cur, cmd); used = used + cmd.h
        end
    else
        local cols = {}; local curCol = {}; local colUsed = 0
        table.insert(cols, curCol)
        for _, cmd in ipairs(cmds) do
            if colUsed + cmd.h > usableH and colUsed > 0 then
                curCol = {}; colUsed = 0; table.insert(cols, curCol)
            end
            table.insert(curCol, cmd); colUsed = colUsed + cmd.h
        end
        local i = 1
        while i <= #cols do
            table.insert(pages, { left=cols[i], right=cols[i+1] or {} })
            i = i + 2
        end
    end
    return pages
end

-- ══════════════════════════════════════════════════════════════════
--  COVER STYLES
-- ══════════════════════════════════════════════════════════════════
local CoverStyles = {}
_G.ixBook_CoverStyles = CoverStyles

local function DrawCoverBase(w, h, cCover, coverImageURL)
    draw.RoundedBox(4, 0, 0, w, h, cCover)
    local url = coverImageURL and coverImageURL:match("^%s*(.-)%s*$") or ""
    if url ~= "" then
        local mat = GetImage(url)
        if mat and not mat:IsError() and mat ~= Material("vgui/white") then
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(0, 0, w, h)
            return true
        end
        draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,60))
        draw.SimpleText("Loading image...", "ixBook_Author", w/2, h/2, Color(200,200,200,180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end
    return false
end

CoverStyles["classic"] = function(w,h,pad,title,tFont,author,cCover,cText,cAccent,coverImageURL)
    if DrawCoverBase(w,h,cCover,coverImageURL) then return end
    surface.SetDrawColor(cAccent)
    surface.DrawRect(pad,pad,w-pad*2,2); surface.DrawRect(pad,pad+7,w-pad*2,1)
    surface.DrawRect(pad,h-pad-8,w-pad*2,1); surface.DrawRect(pad,h-pad-1,w-pad*2,2)
    draw.SimpleText(title,tFont,w/2,h/2-28,cText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText("by "..author,"ixBook_Author",w/2,h/2+16,Color(cText.r,cText.g,cText.b,170),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

CoverStyles["bordered"] = function(w,h,pad,title,tFont,author,cCover,cText,cAccent,coverImageURL)
    if DrawCoverBase(w,h,cCover,coverImageURL) then return end
    local m = pad-6
    surface.SetDrawColor(cAccent)
    surface.DrawOutlinedRect(m,m,w-m*2,h-m*2,2)
    surface.DrawOutlinedRect(m+6,m+6,w-(m+6)*2,h-(m+6)*2,1)
    local arm = 12
    for _, cx in ipairs({m+3,w-m-3}) do
        for _, cy in ipairs({m+3,h-m-3}) do
            local sx=(cx<w/2) and 1 or -1; local sy=(cy<h/2) and 1 or -1
            surface.DrawRect(cx,cy-1,arm*sx,2); surface.DrawRect(cx-1,cy,2,arm*sy)
        end
    end
    draw.SimpleText(title,tFont,w/2,h/2-28,cText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText("by "..author,"ixBook_Author",w/2,h/2+16,Color(cText.r,cText.g,cText.b,170),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

CoverStyles["minimal"] = function(w,h,pad,title,tFont,author,cCover,cText,cAccent,coverImageURL)
    if DrawCoverBase(w,h,cCover,coverImageURL) then return end
    local ty=h/2-28; local ay=h/2+16; local lw=w*0.55; local lx=(w-lw)/2
    surface.SetDrawColor(cAccent)
    surface.DrawRect(lx,ty-14,lw,1); surface.DrawRect(lx,ay+22,lw,1)
    draw.SimpleText(title,tFont,w/2,ty,cText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText("by "..author,"ixBook_Author",w/2,ay,Color(cText.r,cText.g,cText.b,170),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

CoverStyles["ornate"] = function(w,h,pad,title,tFont,author,cCover,cText,cAccent,coverImageURL)
    if DrawCoverBase(w,h,cCover,coverImageURL) then return end
    surface.SetDrawColor(cAccent)
    local f = pad+4; surface.DrawOutlinedRect(f,f,w-f*2,h-f*2,1)
    local arm,thick = 18,3
    for _, cx in ipairs({f,w-f}) do
        for _, cy in ipairs({f,h-f}) do
            local sx=(cx<=w/2) and 1 or -1; local sy=(cy<=h/2) and 1 or -1
            surface.DrawRect(cx,cy-math.floor(thick/2),arm*sx,thick)
            surface.DrawRect(cx-math.floor(thick/2),cy,thick,arm*sy)
        end
    end
    local ty=h/2-28; local ay=h/2+16; local rw=w-pad*3
    surface.DrawRect(pad*1.5,ty-16,rw,1); surface.DrawRect(pad*1.5,ay+22,rw,1)
    draw.SimpleText(title,tFont,w/2,ty,cText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText("by "..author,"ixBook_Author",w/2,ay,Color(cText.r,cText.g,cText.b,170),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

CoverStyles["stamp"] = function(w,h,pad,title,tFont,author,cCover,cText,cAccent,coverImageURL)
    if DrawCoverBase(w,h,cCover,coverImageURL) then return end
    local bw=w-pad*2.5; local bh=90; local bx=(w-bw)/2; local by=h/2-bh/2-10
    draw.RoundedBox(2,bx,by,bw,bh,Color(cAccent.r,cAccent.g,cAccent.b,40))
    surface.SetDrawColor(cAccent)
    surface.DrawOutlinedRect(bx,by,bw,bh,3); surface.DrawOutlinedRect(bx+5,by+5,bw-10,bh-10,1)
    draw.RoundedBox(0,bx+3,by+3,bw-6,16,Color(cAccent.r,cAccent.g,cAccent.b,80))
    draw.SimpleText(title,tFont,w/2,by+bh/2-10,cText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText("by "..author,"ixBook_Author",w/2,by+bh+14,Color(cText.r,cText.g,cText.b,170),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

CoverStyles["parchment"] = function(w,h,pad,title,tFont,author,cCover,cText,cAccent,coverImageURL)
    if DrawCoverBase(w,h,cCover,coverImageURL) then return end
    draw.RoundedBox(0,0,0,w,h*0.12,Color(0,0,0,30))
    draw.RoundedBox(0,0,h*0.88,w,h*0.12,Color(0,0,0,30))
    surface.SetDrawColor(cAccent)
    surface.DrawRect(pad,pad+2,w-pad*2,1); surface.DrawRect(pad,h-pad-3,w-pad*2,1)
    draw.SimpleText(title,tFont,w/2,h/2-40,cText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText("by "..author,"ixBook_Author",w/2,h/2-10,Color(cText.r,cText.g,cText.b,170),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

CoverStyles["dark"] = function(w,h,pad,title,tFont,author,cCover,cText,cAccent,coverImageURL)
    if DrawCoverBase(w,h,cCover,coverImageURL) then return end
    draw.RoundedBox(4,0,0,w,h,Color(0,0,0,40))
    surface.SetDrawColor(Color(cAccent.r,cAccent.g,cAccent.b,60))
    for i = -h, w+h, 24 do surface.DrawLine(i,0,i+h,h) end
    surface.SetDrawColor(cAccent)
    surface.DrawOutlinedRect(pad-4,pad-4,w-(pad-4)*2,h-(pad-4)*2,1)
    draw.SimpleText(title,tFont,w/2,h/2-28,cText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText("by "..author,"ixBook_Author",w/2,h/2+16,Color(cText.r,cText.g,cText.b,170),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

-- ══════════════════════════════════════════════════════════════════
--  BOOK PANEL FACTORY
-- ══════════════════════════════════════════════════════════════════
local function OpenBookPanel(cfg)
    if IsValid(ix.bookPanel) then ix.bookPanel:Remove() end

    local title         = cfg.title          or "Untitled"
    local author        = cfg.author         or "Unknown"
    local content       = cfg.content        or ""
    local coverStyle    = cfg.coverStyle      or "classic"
    local dual          = cfg.dualPage        or false
    local coverImageURL = cfg.coverImageURL   or ""
    local titleSize     = math.Clamp(math.floor(tonumber(cfg.titleFontSize) or 26), 10, 48)
    local tFont         = GetFont(cfg.titleFont or "Roboto", titleSize, true)

    local C = BookPalette(cfg)

    local scrW, scrH = ScrW(), ScrH()
    local frame = vgui.Create("DFrame")
    frame:SetSize(scrW,scrH); frame:SetPos(0,0); frame:SetTitle("")
    frame:ShowCloseButton(false); frame:SetDraggable(false); frame:MakePopup()
    ix.bookPanel = frame
    function frame:Paint(w,h) draw.RoundedBox(0,0,0,w,h,Color(0,0,0,160)) end

    local singleW = math.min(500, scrW-80)
    local pageH   = math.min(680, scrH-80)
    local fullW   = dual and math.min(singleW*2+4, scrW-80) or singleW
    local padding = 28
    local usableH = pageH - padding*2 - 24
    local colW    = dual and math.floor((fullW-padding*3)/2) or (singleW-padding*2)
    local pageY   = (scrH - pageH) / 2

    local allCmds = ParseToCommands(content, colW, C)
    local pages   = Paginate(allCmds, usableH, dual)
    local totalP  = #pages
    local curPage = 1

    -- Stores link hotspots and copy-button zones, rebuilt every Paint
    local frameLinks = {}
    local frameCopyZones = {}

    local function CurrentPageW() return (dual and curPage > 1) and fullW or singleW end
    local function CurrentPageX() return (scrW - CurrentPageW()) / 2 end

    local pagePnl = vgui.Create("DPanel", frame)

    local function UpdatePanelSize()
        pagePnl:SetSize(CurrentPageW(), pageH)
        pagePnl:SetPos(CurrentPageX(), pageY)
    end
    UpdatePanelSize()

    local function DrawCol(cmds, x0, y0, ls, cz)
        local yOff = y0
        for _, cmd in ipairs(cmds) do
            cmd.fn(x0, yOff, C, ls, cz)
            yOff = yOff + cmd.h
        end
    end

    function pagePnl:Paint(w,h)
        draw.RoundedBox(6, 4, 4, w, h, DEF.shadow)
        draw.RoundedBox(4, 0, 0, w, h, C.pageBG)
        frameLinks     = {}
        frameCopyZones = {}

        if curPage == 1 then
            local sfn = CoverStyles[coverStyle] or CoverStyles["classic"]
            sfn(w, h, padding, title, tFont, author, C.coverBG, C.coverText, C.coverAccent, coverImageURL)
            return
        end

        local pg = pages[curPage]
        if not pg then return end

        local x0, y0 = padding, padding
        if dual then
            DrawCol(pg.left  or {}, x0,          y0, frameLinks, frameCopyZones)
            DrawCol(pg.right or {}, w/2+padding, y0, frameLinks, frameCopyZones)
        else
            DrawCol(pg, x0, y0, frameLinks, frameCopyZones)
        end

        local lbl = string.format("— %d / %d —", curPage-1, totalP-1)
        draw.SimpleText(lbl, "ixBook_PageNum", w/2, h-padding+8, C.heading, TEXT_ALIGN_CENTER)
    end

    -- ── Mouse input: links + copy buttons ────────────────────────
    function pagePnl:OnMousePressed(mc)
        if mc ~= MOUSE_LEFT then return end
        local mx, my = gui.MousePos()
        local px, py = self:LocalToScreen(0,0)
        local lx, ly = mx - px, my - py

        -- Check copy zones first
        for _, zone in ipairs(frameCopyZones) do
            if lx >= zone.bx and lx <= zone.bx+zone.bw and ly >= zone.by and ly <= zone.by+zone.bh then
                SetClipboardText(zone.text)
                -- Flash feedback
                notification.AddLegacy(L("ixbook_code_copied"), NOTIFY_GENERIC, 1.5)
                surface.PlaySound("ui/buttonclick.wav")
                return
            end
        end

        -- Check links
        for _, lk in ipairs(frameLinks) do
            if lx >= lk[1] and lx <= lk[3] and ly >= lk[2] and ly <= lk[4] then
                gui.OpenURL(lk[5]); return
            end
        end
    end
    pagePnl:SetMouseInputEnabled(true)

    -- ── Track mouse position for hover state in code copy buttons ─
    hook.Add("Think","ixBook_MouseTrack", function()
        if not IsValid(frame) then hook.Remove("Think","ixBook_MouseTrack"); return end
        local mx, my = gui.MousePos()
        local px, py = pagePnl:LocalToScreen(0,0)
        ixBook_CopyMouseX = mx - px
        ixBook_CopyMouseY = my - py
    end)

    hook.Add("Think","ixBook_LinkCursor",function()
        if not IsValid(frame) then hook.Remove("Think","ixBook_LinkCursor"); return end
        local mx, my = gui.MousePos()
        local px, py = pagePnl:LocalToScreen(0,0)
        local pw, ph = pagePnl:GetSize()
        if mx<px or mx>px+pw or my<py or my>py+ph then return end
        local lx, ly = mx-px, my-py
        for _, zone in ipairs(frameCopyZones) do
            if lx >= zone.bx and lx <= zone.bx+zone.bw and ly >= zone.by and ly <= zone.by+zone.bh then
                pagePnl:SetCursor("hand"); return
            end
        end
        for _, lk in ipairs(frameLinks) do
            if lx>=lk[1] and lx<=lk[3] and ly>=lk[2] and ly<=lk[4] then
                pagePnl:SetCursor("hand"); return
            end
        end
        pagePnl:SetCursor("arrow")
    end)

    if dual then
        local spine = vgui.Create("DPanel", frame)
        spine:SetSize(4, pageH); spine:SetPos((scrW-fullW)/2 + fullW/2 - 2, pageY)
        function spine:Paint(w,h) if curPage ~= 1 then draw.RoundedBox(0,0,0,w,h,Color(0,0,0,60)) end end
    end

    local btnW, btnH = 36, 54

    local function RepositionButtons(btnPrev, btnNext, btnClose)
        local px = CurrentPageX(); local pw = CurrentPageW()
        if IsValid(btnPrev)  then btnPrev:SetPos(px - btnW - 8, pageY + pageH/2 - btnH/2) end
        if IsValid(btnNext)  then btnNext:SetPos(px + pw + 8,   pageY + pageH/2 - btnH/2) end
        if IsValid(btnClose) then btnClose:SetPos(px + pw - 30, pageY + 4) end
    end

    local btnPrev  = vgui.Create("DButton", frame)
    local btnNext  = vgui.Create("DButton", frame)
    local btnClose = vgui.Create("DButton", frame)

    btnPrev:SetSize(btnW,btnH);  btnPrev:SetText("")
    btnNext:SetSize(btnW,btnH);  btnNext:SetText("")
    btnClose:SetSize(20,20);     btnClose:SetText("")

    function btnPrev:Paint(w,h)
        if curPage==1 then return end
        local col = self:IsHovered() and C.navHover or C.navBtn
        draw.RoundedBox(4,0,0,w,h,col)
        draw.SimpleText("◀","ixBook_H2",w/2,h/2,C.navText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    function btnPrev:DoClick()
        if curPage > 1 then
            curPage = curPage - 1
            UpdatePanelSize(); RepositionButtons(btnPrev, btnNext, btnClose)
            PlayPageSound()
        end
    end

    function btnNext:Paint(w,h)
        if curPage==totalP then return end
        local col = self:IsHovered() and C.navHover or C.navBtn
        draw.RoundedBox(4,0,0,w,h,col)
        draw.SimpleText("▶","ixBook_H2",w/2,h/2,C.navText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    function btnNext:DoClick()
        if curPage < totalP then
            curPage = curPage + 1
            UpdatePanelSize(); RepositionButtons(btnPrev, btnNext, btnClose)
            PlayPageSound()
        end
    end

    function btnClose:Paint(w,h)
        local col = self:IsHovered() and Color(180,60,40,220) or Color(140,40,20,180)
        draw.RoundedBox(4,0,0,w,h,col)
        draw.SimpleText("✕","ixBook_Body",w/2,h/2,DEF.navText,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    function btnClose:DoClick() frame:Remove() end

    RepositionButtons(btnPrev, btnNext, btnClose)

    frame:SetKeyboardInputEnabled(true)
    function frame:OnKeyCodePressed(code)
        if code == KEY_LEFT or code == KEY_A then
            if curPage > 1 then curPage=curPage-1; UpdatePanelSize(); RepositionButtons(btnPrev,btnNext,btnClose); PlayPageSound() end
        elseif code == KEY_RIGHT or code == KEY_D then
            if curPage < totalP then curPage=curPage+1; UpdatePanelSize(); RepositionButtons(btnPrev,btnNext,btnClose); PlayPageSound() end
        elseif code == KEY_ESCAPE then
            self:Remove()
        end
    end

    function frame:OnRemoved()
        hook.Remove("Think","ixBook_LinkCursor")
        hook.Remove("Think","ixBook_MouseTrack")
        ixBook_CopyMouseX = nil
        ixBook_CopyMouseY = nil
    end
end
_G.ixBook_OpenBookPanel = OpenBookPanel

-- ══════════════════════════════════════════════════════════════════
--  NET RECEIVER: ix_books_open
-- ══════════════════════════════════════════════════════════════════
net.Receive("ix_books_open", function()
    local title         = net.ReadString()
    local author        = net.ReadString()
    local content       = net.ReadString()
    local coverStyle    = net.ReadString()
    local dualPage      = net.ReadBool()
    local titleFont     = net.ReadString()
    local titleFontSz   = net.ReadUInt(8)
    local coverImageURL = net.ReadString()
    if titleFontSz < 8 then titleFontSz = 26 end

    local function rc()
        local flag = net.ReadUInt(8)
        local r, g, b = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
        if flag == 0 then return nil end
        return { r, g, b }
    end

    OpenBookPanel({
        title           = title,
        author          = author,
        content         = content,
        coverStyle      = coverStyle,
        dualPage        = dualPage,
        titleFont       = (titleFont ~= "") and titleFont or nil,
        titleFontSize   = titleFontSz,
        coverImageURL   = coverImageURL ~= "" and coverImageURL or nil,
        coverColor      = rc(), textColor       = rc(), accentColor     = rc(),
        pageColor       = rc(), bodyColor       = rc(), headColor       = rc(),
        quoteBGColor    = rc(), quoteBarColor   = rc(), codeBGColor     = rc(),
        codeTextColor   = rc(), hrColor         = rc(), tableHdrColor   = rc(),
        tableLineColor  = rc(), navBtnColor     = rc(), navHoverColor   = rc(),
        navTextColor    = rc(), chartBarColor   = rc(), chartGridColor  = rc(),
    })
end)
