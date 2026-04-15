# 📚 HLX_BOOKS — Readable Books for Helix 

## ✨ Features
·	Markdown rendering — Full inline parser supporting headings (#, ##, ###), bold (*text*), inline code (`code`), blockquotes, horizontal rules, tables, and code blocks.
·	Inline markup tags — Custom tag syntax for colored text ([color:red]), custom fonts ([font:Courier New]), and clickable links ([link:https://...]).
·	Bar charts — Render simple bar/line charts directly inside book content.
·	Cover styles — Multiple built-in cover styles: classic, dark, ornate, bordered, stamp, minimal, parchment.
·	Dual-page mode — Optional two-column layout for wider displays.
·	Full color theming — 18 individually configurable color slots (page background, headings, quotes, code blocks, navigation, charts, and more).
·	8 preset themes — Parchemin Classic, Océan Profond, Forêt Sombre, Aurore Polaire, Crépuscule Violet, Sable Ancien, Acier Industriel, Sakura Rose.
·	Visual book editor — In-game VGUI editor for admins with live preview, color pickers, model selector, and preset loader.
·	Book archive — Persistent server-side archive of book definitions. Archived books become permanent item types that can be spawned or given by admins.
·	Archive manager — Admin panel to browse, spawn, give, edit, and delete archived books.
·	Keyboard navigation — Arrow keys and A/D to turn pages; Escape to close.
·	Clickable links & copy buttons — URLs open in the overlay browser; code blocks have a copy-to-clipboard button.
·	URL images — Cover and inline images loaded from HTTP URLs with local caching.

## Exemple

![alt text](https://i.ibb.co/Tx8vcFPR/Screenshot-From-2026-04-08-17-07-11.png)

## 🗄️ Book Archive
The archive allows admins to permanently register books as server-side item types.
1.	Hold a book item in your inventory.
2.	Right-click → Archive Book (or use the editor's archive button).
3.	Choose a unique archive ID (auto-generated from title + author if left blank).
4.	The book becomes a permanent item type, synced to all clients.
