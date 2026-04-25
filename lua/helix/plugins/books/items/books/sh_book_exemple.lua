
ITEM.name        = "Book Example"
ITEM.description = "Complete example of how to write ix_books items."
ITEM.category    = "Books"
ITEM.model       = "models/props_lab/binderredlabel.mdl"
ITEM.skin        = 2
ITEM.width       = 1
ITEM.height      = 1

-- ── Book metadata ─────────────────────────────────────────────────────────────
ITEM.bookTitle   = "Book Example"
ITEM.bookAuthor  = "Sunshi"

-- ── Layout / cover ────────────────────────────────────────────────────────────
ITEM.bookCoverStyle    = "dark"
ITEM.bookTitleFont     = "Georgia"
ITEM.bookTitleFontSize = 28
ITEM.bookDualPage      = false


ITEM.bookCoverImageURL = ""

-- ── Palette ───────────────────────────────────────────────────────────────────
ITEM.bookCoverColor     = { 55,  75,  35  }
ITEM.bookTextColor      = { 230, 245, 215 }
ITEM.bookAccentColor    = { 140, 185, 90  }
ITEM.bookPageColor      = { 248, 245, 228 }
ITEM.bookBodyColor      = { 40,  50,  25  }
ITEM.bookHeadColor      = { 60,  100, 35  }
ITEM.bookQuoteBGColor   = { 225, 235, 205 }
ITEM.bookQuoteBarColor  = { 100, 155, 60  }
ITEM.bookCodeBGColor    = { 215, 225, 195 }
ITEM.bookCodeTextColor  = { 40,  65,  20  }
ITEM.bookHrColor        = { 110, 155, 70  }
ITEM.bookTableHdrColor  = { 175, 210, 130 }
ITEM.bookTableLineColor = { 150, 185, 105 }
ITEM.bookNavBtnColor    = { 50,  85,  30  }
ITEM.bookNavHoverColor  = { 70,  115, 45  }
ITEM.bookNavTextColor   = { 230, 245, 210 }
ITEM.bookChartBarColor  = { 90,  155, 55  }
ITEM.bookChartGridColor = { 170, 200, 140 }

-- ── Book content ──────────────────────────────────────────────────────────────
ITEM.bookContent = [[
# Book Example

This is a demonstration book for the **ix_books** system.

---

## 1) Basic formatting

You can write normal text, **bold text**, *italic text*, and even mix them.

### Colored text

> [color:green]Nature does not hurry, yet everything is accomplished.[/color]

The [color:red]**Bloodleaf**[/color] (*Rubrum folium*) is one of the most striking species
of the outer reaches. It is known for its [color:red]vivid crimson veins[/color]
that contrast against a [color:green]deep green[/color] surface.

You can also use:
- [color:orange]orange[/color]
- [color:blue]blue[/color]
- [color:purple]purple[/color]
- [color:red]red[/color]
- [color:green]green[/color]

---

## 2) Quotes

> The outer reaches teach patience to those willing to observe.
>  
> "...if anyone is listening... we're at grid reference **Delta-Nine**...
> please... *please* respond..."

---

## 3) Code examples

Below are some basic item fields:

ITEM.name = "My Book"
ITEM.description = "Short tooltip."
ITEM.model = "models/props_junk/garbage_newspaper002a.mdl"
ITEM.skin = 0
ITEM.width = 1
ITEM.height = 1

ITEM.bookTitle = "My Book Title"
ITEM.bookAuthor = "Author Name"
ITEM.bookContent = "Your content here"


---

## 4) Tables

| Species          | Height (cm) | Toxicity | Rarity |
|------------------|-------------|----------|--------|
| R. folium major  | 12-18       | [color:orange]Moderate[/color] | [color:orange]Uncommon[/color] |
| R. folium minor  | 4-8         | [color:green]Low[/color] | [color:green]Common[/color] |
| R. folium aurum  | 20-30       | [color:red]High[/color] | [color:red]Rare[/color] |
| C. viridis       | 60-90       | [color:green]None[/color] | [color:green]Common[/color] |
| M. nocturna      | 8-14        | [color:red]**Fatal**[/color] | [color:purple]Very Rare[/color] |

---

## 5) Charts

### Line chart
[chart:line|Spring:12,Summer:38,Autumn:55,Winter:8]

### Bar chart
[chart:bar|Clara:85,Osbourne:60,Unknown:40]

You can use charts to represent:
- progression
- reputation
- danger levels
- seasonal activity
- lore data

---

## 6) Images

Remote image:
[img:https://i.ibb.co/6xXfh8D/image.png|320x120]

Local material / HUD icon:
[img:hud/jail.png|120x120]

---

## 7) Notes for creators

If you are making your own book item, the most important fields are:

If you want custom colors, you can define:
]]