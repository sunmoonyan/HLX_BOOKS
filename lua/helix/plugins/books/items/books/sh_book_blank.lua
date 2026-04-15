-- items/books/sh_book_editor_spawn.lua
-- Item generated when a player spawns a book from the in-game editor.

ITEM.name        = "Blank Book"
ITEM.description = "A blank book."
ITEM.category    = "Books"
ITEM.base        = "base_books"
ITEM.model       = "models/props_lab/binderredlabel.mdl"
ITEM.width       = 1
ITEM.height      = 1

ITEM.bookCoverStyle = "classic"
ITEM.bookTitleFont  = "Roboto"
ITEM.bookDualPage   = false
ITEM.bookTitleFontSize = 26

function ITEM:GetName()
    return self:GetData("bookTitle", self.bookTitle or "Untitled")
end

function ITEM:GetDescription()
    return "by " .. self:GetData("bookAuthor", self.bookAuthor or "Unknown")
end

ITEM.functions = ITEM.functions or {}

