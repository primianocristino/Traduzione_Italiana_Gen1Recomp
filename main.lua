-- pokemon_red_italiano: Traduzione italiana di Pokémon Rosso
local BattleState = require("src.battle.BattleState")
local Font = require("src.render.Font")
local Strings = require("src.core.Strings")
local TypeChart = require("src.battle.TypeChart")
local ListMenu = require("src.ui.ListMenu")
local MoveLearnMenu = require("src.ui.MoveLearnMenu")
local Theme = require("src.ui.Theme")
local TrainerCard = require("src.ui.TrainerCard")
local Badges = require("src.inventory.Badges")

return function(mod)

  -- Funzione per leggere i file di catalogo dalla cartella lang/
  local function catalog(name)
    local rel = "lang/" .. name .. ".lua"
    local body = mod:read(rel)
    if not body then return {} end
    local chunk, err = loadstring(body, rel)
    if not chunk then
      mod.log:warn("%s ha un errore di sintassi: %s", rel, tostring(err))
      return {}
    end
    local ok, table_ = pcall(chunk)
    if not ok or type(table_) ~= "table" then
      mod.log:warn("%s non ha restituito una tabella: %s", rel, tostring(table_))
      return {}
    end
    return table_
  end

  -- Funzione per caricare script esterni
  local function loadScript(path)
    local body = mod:read(path)
    if not body then 
      mod.log:warn("Impossibile leggere lo script: %s", path)
      return 
    end
    local chunk, err = loadstring(body, path)
    if not chunk then
      mod.log:warn("%s ha un errore di sintassi: %s", path, tostring(err))
      return
    end
    local ok, fn = pcall(chunk)
    if ok and type(fn) == "function" then
      fn(mod)
    else
      mod.log:warn("%s non ha restituito una funzione valida", path)
    end
  end

  -- Applica le traduzioni ignorando le chiavi vuote
  local function each(name, apply)
    local n = 0
    for key, value in pairs(catalog(name)) do
      if type(value) == "string" and value ~= "" then
        apply(key, value)
        n = n + 1
      end
    end
    return n
  end

  -- ---- Font e Caratteri (Glyphs) -----------------------------------
  for id, page in pairs(catalog("font")) do
    -- Risolve il percorso dell'immagine rispetto alla cartella della mod
    if type(page) == "table" and type(page.image) == "string" and mod:read(page.image) then
      page.image = mod.assets:path(page.image)
    end
    mod.content.font:register(id, page)
  end

  for seq, code in pairs(catalog("charmap")) do
    mod.content.font:register("charmap:" .. seq, { seq = seq, code = code })
  end

  -- ---- Testi e Tabelle ---------------------------------------------
  local counts = {}
  counts.dialogue = each("dialogue", function(id, value)
    mod.content.text:override(id, value)
  end)
  counts.strings = each("strings", function(source, value)
    mod.content.strings:override(source, value)
  end)
  counts.species = each("species_names", function(id, value)
    mod.content.pokemon:patch(id, { name = value })
  end)
  counts.moves = each("move_names", function(id, value)
    mod.content.moves:patch(id, { name = value })
  end)
  counts.items = each("item_names", function(id, value)
    mod.content.items:patch(id, { name = value })
  end)
  counts.trainers = each("trainer_names", function(id, value)
    mod.content.trainers:patch(id, { name = value })
  end)
  counts.statuses = each("status_labels", function(id, value)
    mod.content.statuses:patch(id, { label = value })
  end)

  -- ---- Griglia inserimento Nome ------------------------------------
  local grid = catalog("naming")
  if grid.upper or grid.lower then
    mod.hooks:wrap("ui.naming.grid", function(base, ctx)
      local want = ctx and ctx.lower and grid.lower or grid.upper
      return want or base
    end)
  end

  -- ---- Literal Handlers (Dinamici) ---------------------------------
  local literal_body = mod:read("lang/literal_handlers.lua")
  if literal_body then
    local chunk, err = loadstring(literal_body, "lang/literal_handlers.lua")
    if not chunk then error(err) end
    local setup = chunk()
    if type(setup) ~= "function" then error("literal_handlers.lua deve restituire una funzione") end
    setup(mod)
  end

  -- ---- UI: Menu di Lotta -------------------------------------------
  BattleState.drawTextArea = function(self)
    love.graphics.setColor(0, 0, 0, 1)
    if self.phase == "messages" and (self.current or self.animPlaying) then
      if self.scrollPx and self.scrollPx > 0 then
        self.scrollPx = self.scrollPx - 2
        if self.scrollPx <= 0 then self.scrollPx = nil end
      end
      local off = self.scrollPx or 0
      local ys = { 112, 128 }
      for li, line in ipairs(self.shown or {}) do
        local y = (ys[li] or 128) + off
        for i = 1, #line do
          Font.drawCode(line[i], 8 + (i - 1) * 8, y)
        end
      end
      if (self.msgWaiting or self.msgPrompt) and self.frame % 60 < 30 then
        Font.drawCode(0xEE, (0 + 20 - 2) * 8, (12 + 6 - 1) * 8 - 4)
      end
    elseif self.phase == "menu" and self.demo then
      Font.drawBox(5, 12, 15, 6)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw(Strings("LOTTA"), 56, 112)
      Font.drawCode(0xE1, 112, 112); Font.drawCode(0xE2, 120, 112)
      Font.draw(Strings("ZAINO"), 56, 128); Font.draw(Strings("FUGA"), 112, 128)
      Font.drawCode(0xED, 48, (self.demoTimer or 0) <= 80 and 112 or 128)
    elseif self.phase == "menu" then
      local col = (self.menuIndex - 1) % 2
      local row = math.floor((self.menuIndex - 1) / 2)
      if self.safari then
        Font.drawBox(0, 12, 20, 6)
        Font.draw(Strings("SAFARI BALL"), 16, 112); Font.draw(Strings("ESCA"), 112, 112)
        Font.draw(Strings("SASSI"), 16, 128); Font.draw(Strings("FUGA"), 112, 128)
        Font.drawCode(0xED, (col == 0 and 8 or 104), 112 + row * 16)
      else
        Font.drawBox(5, 12, 15, 6)
        Font.draw(Strings("LOTTA"), 56, 112)
        Font.drawCode(0xE1, 112, 112); Font.drawCode(0xE2, 120, 112)
        Font.draw(Strings("ZAINO"), 56, 128); Font.draw(Strings("FUGA"), 112, 128)
        Font.drawCode(0xED, (col == 0 and 48 or 104), 112 + row * 16)
      end
    elseif self.phase == "moveSelect" then
      Font.drawBox(0, 8, 11, 5)
      Font.drawBox(0, 12, 20, 6)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 32, 96, 8, 8)
      love.graphics.rectangle("fill", 80, 96, 8, 8)
      Font.drawCode(Font.BORDER.h, 32, 96)
      Font.drawCode(Font.BORDER.br, 80, 96)
      love.graphics.setColor(0, 0, 0, 1)
      for i, mv in ipairs(self.player.curMoves) do
        local def = self.data.moves[mv.id]
        Font.draw(def and def.name or tostring(mv.id), 16, 96 + i * 8)
      end
      Font.drawCode((self.moveSwapIndex == self.moveIndex) and 0xEC or 0xED, 08, 96 + self.moveIndex * 8)
      if self.moveSwapIndex and self.moveSwapIndex ~= self.moveIndex then
        Font.drawCode(0xEC, 08, 96 + self.moveSwapIndex * 8)
      end
      local sel = self.player.curMoves[self.moveIndex]
      if sel then
        local def = self.data.moves[sel.id]
        if self.player.disabledSlot == self.moveIndex then
          Font.draw(Strings("disattivata!"), 8, 80)
        elseif def then
          Font.draw(Strings("TIPO/"), 8, 72)
          Font.draw(def.type and TypeChart.displayName(def.type) or "", 16, 80)
          local maxPP = def.pp + (sel.ppUps or 0) * math.floor(def.pp / 5)
          Font.draw(("%2d/%2d"):format(sel.pp, maxPP), 40, 88)
        end
      end
    elseif self.phase == "mimicSelect" then
      Font.drawBox(0, 7, 20, 6)
      love.graphics.setColor(0, 0, 0, 1)
      for i, m in ipairs(self.mimicMoves) do
        Font.draw(self.data.moves[m.id].name, 16, (7 + i) * 8)
      end
      Font.drawCode(0xED, 8, (7 + self.mimicIndex) * 8)
    end
  end

  -- ---- UI: Allineamento Liste e Inventario -------------------------
  function ListMenu:draw() 
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 160, 144)
    love.graphics.setColor(0, 0, 0, 1)
    Font.draw(Strings(self.title), 8, 4)
    if #self.items == 0 then
      Font.draw(Strings("Niente qui."), 16, 64)
    end
    for row = 1, self.rows do
      local i = self.scroll + row
      local item = self.items[i]
      if not item then break end
      local y = 8 + row * 16
      Font.draw(item.label, 16, y)
      if item.ball then
        local bx = 16 + Font.width(item.label) + 8 + 3
        local by = y + 3
        love.graphics.circle("fill", bx, by, 3.5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", bx - 3.5, by - 0.5, 7, 1)
        love.graphics.circle("fill", bx, by, 1.2)
        love.graphics.setColor(0, 0, 0, 1)
      end
      if item.right then
        Font.draw(item.right, 160 - 8 - Font.width(item.right), y + 8)
      end
      if i == self.index then
        Font.drawCode((self.swapIndex == i or self.hollowIndex == i)
                      and Theme.cursorHollow or Theme.cursor, 8, y)
      end
      if self.swapIndex == i and i ~= self.index then
        Font.drawCode(Theme.cursorHollow, 8, y)
      end
    end
    if self.dialogue then
      Font.drawBox(11, 0, 9, 3)
      love.graphics.setColor(0, 0, 0, 1)
      local money = ("¥%d"):format(self.money and self.money() or 0)
      Font.draw(money, 152 - Font.width(money), 8)
    end
    if self.dialogue or (self.messageBox and self.footer) then
      Font.drawBox(0, 12, 20, 6)
      love.graphics.setColor(0, 0, 0, 1)
      if self.footer then
        local flat = {}
        for _, page in ipairs(require("src.render.TextBox").paginate(self.footer)) do
          for _, line in ipairs(page) do flat[#flat + 1] = line end
        end
        local y = 112
        for i = math.max(1, #flat - 1), #flat do
          Font.draw(flat[i], 8, y)
          y = y + 16
        end
      end
    elseif self.footer then
      local flat = {}
      for _, page in ipairs(require("src.render.TextBox").paginate(self.footer)) do
        for _, line in ipairs(page) do flat[#flat + 1] = line end
      end
      local y = (#flat >= 2) and 120 or 136
      for i = math.max(1, #flat - 1), #flat do
        Font.draw(flat[i], 8, y)
        y = y + 16
      end
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  -- ---- UI: Apprendimento Mosse ------------------------------------
  local CURSOR = 0xED
  function MoveLearnMenu:draw()
    if not self.selecting then return end
    Font.drawBox(0, 5, 20, 7)
    love.graphics.setColor(0, 0, 0, 1)
    for i, mv in ipairs(self.mon.moves) do
      Font.draw(self.game.data.moves[mv.id].name, 16, (5 + i) * 8)
    end
    Font.draw(Strings("ANNULLA"), 16, (6 + #self.mon.moves) * 8)
    Font.drawCode(CURSOR, 08, (5 + self.index) * 8)
    Font.drawBox(0, 12, 20, 6)
    Font.draw(Strings("Quale mossa deve"), 8, 14 * 8)
    Font.draw(Strings("essere dimenticata?"), 8, 16 * 8)
    love.graphics.setColor(1, 1, 1, 1)
  end

  -- ---- UI: Scheda Allenatore --------------------------------------
  function TrainerCard:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 160, 144)
    local save = self.game.save

    self:frameBox(0, 0, 20, 8)
    if self.pic then
      love.graphics.draw(self.pic, 104, 4)
    end
    love.graphics.setColor(0, 0, 0, 1)
    Font.draw(Strings("NOME/%s", save.player.name or "RED"), 16, 12)
    Font.draw(Strings("SOLDI/"), 16, 25)
    Font.draw(("¥%d"):format(save.money or 0), 48, 33)

    local t = math.floor(save.playTime or 0)
    Font.draw(Strings("TEMPO/"), 16, 42)
    Font.draw(("%3d:%02d"):format(
      math.floor(t / 3600),
      math.floor(t / 60) % 60
    ), 48, 50)

    self:frameBox(0, 8, 20, 3)
    love.graphics.setColor(0, 0, 0, 1)
    Font.draw(Strings("MEDAGLIE"), 40, 73)
    if self.circle then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(self.circle, 32, 72)
      love.graphics.draw(self.circle, 112, 72)
      love.graphics.setColor(0, 0, 0, 1)
    end

    self:frameBox(0, 11, 20, 7)
    local badges = Badges.list(self.game.data)
    for i = 1, #badges do
      local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
      local tx, ty = 16 + col * 32, 95 + row * 22
      if self.nums and self.nums.quads[i - 1] then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.nums.img, self.nums.quads[i - 1], tx, ty)
      end
      if self.faces and self.faces.quads[i - 1] then
        love.graphics.setColor(1, 1, 1, 1)
        local owned = save.inventory[Badges.itemFor(badges[i])]
        local sheet = owned and self.badges or self.faces
        love.graphics.draw(sheet.img, sheet.quads[i - 1], tx + 8, ty + 2)
      end
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  -- ---- Caricamento Mod Esterne ------------------------------------
  loadScript("mods/nuzlocke.lua")
  loadScript("mods/example_mew_starter.lua")
  loadScript("mods/dramatic_shape.lua")
  loadScript("mods/CryReplacementMod.lua")
  loadScript("mods/MusicReplacementMod.lua")

  -- ---- Evento Ready -----------------------------------------------
  mod.events:on("game.ready", function()
    local total = 0
    for _, n in pairs(counts) do total = total + n end
    mod.log:info("Italiano: %d stringhe tradotte", total)
  end)

end