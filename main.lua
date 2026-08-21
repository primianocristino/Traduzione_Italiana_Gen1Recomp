-- TraduzioneItaliana_Gen1Recomp -- Author: Primiano Cristino
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

  -- ---- GESTIONE OPZIONI (Menu Impostazioni Mod) --------------------
  local compile = loadstring or load
  local source, err = mod:read("it_options.lua")
  if source then
    local chunk, err = compile(source, "@" .. mod.path .. "/it_options.lua")
    if chunk then
      local options = chunk()
      options.install(mod)
    else
      mod.log:error("Impossibile compilare it_options.lua: %s", tostring(err))
    end
  end
  
  if mod.options then
    mod.exports.lingua_mosse = mod.options:get("lingua_mosse")
    mod.exports.mostra_nemico = mod.options:get("mostra_nemico")
    mod.exports.prezzi_riga = mod.options:get("prezzi_riga")
    mod.exports.trainer_card = mod.options:get("trainer_card")
  else
    mod.exports.lingua_mosse = "italiano"
    mod.exports.mostra_nemico = true
    mod.exports.prezzi_riga = true
    mod.exports.trainer_card = true
  end

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

  -- ---- Font e Caratteri -------------------------------------------
  for id, page in pairs(catalog("font")) do
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
  counts.pokedex = each("pokedex_redblue", function(id, value) mod.content.text:override(id, value) end)
  counts.dialogue = each("dialogue", function(id, value) mod.content.text:override(id, value) end)
  counts.strings = each("strings", function(source, value) mod.content.strings:override(source, value) end)
  counts.species = each("species_names", function(id, value) mod.content.pokemon:patch(id, { name = value }) end)
  counts.items = each("item_names", function(id, value) mod.content.items:patch(id, { name = value }) end)
  counts.trainers = each("trainer_names", function(id, value) mod.content.trainers:patch(id, { name = value }) end)
  counts.dex_kinds = each("dex_kinds", function(id, value) mod.content.pokemon:patch(id, { dexEntry = { kind = value } }) end)
  counts.gyms = each("gym_text", function(id, value) mod.content.text:override(id, value) end)
  if mod.exports.lingua_mosse == "gen1" then
    counts.moves = each("move_names", function(id, value) mod.content.moves:patch(id, { name = value }) end)
  elseif mod.exports.lingua_mosse == "italiano" then
    counts.moves = each("move_names2", function(id, value) mod.content.moves:patch(id, { name = value }) end)
  elseif mod.exports.lingua_mosse == "inglese" then
    counts.moves = each("move_names3", function(id, value) mod.content.moves:patch(id, { name = value }) end)
  end

  if mod.exports.mostra_nemico then
    mod.content.strings:override("Enemy %s", "%s nemico")
    mod.content.strings:override("%s\nused %s!", "%s\nusa %s!")
  else
    mod.content.strings:override("Enemy %s", "%s")
    mod.content.strings:override("%s\nused %s!", "%s usa\n%s!")
  end

  -- ---- Traduzione Tipi e Stati ------------------------------------
  local okType, TypeChart = pcall(require, "src.battle.TypeChart")
  local by_english = {}
  
  counts.type_names = each("type_names", function(typeId, localized)
    if okType and TypeChart and type(TypeChart.displayName) == "function" then
      local canonical = TypeChart.displayName(typeId)
      if type(canonical) == "string" and canonical ~= "" and canonical ~= localized then
        by_english[canonical] = localized
      end
    end
  end)

  counts.status_labels = each("status_labels", function(statusId, localized)
    if okType and TypeChart and type(TypeChart.displayName) == "function" then
      local canonical = TypeChart.displayName(statusId)
      if type(canonical) == "string" and canonical ~= "" and canonical ~= localized then
        by_english[canonical] = localized
      end
    end
  end)

  if next(by_english) then
    local okFont, Font = pcall(require, "src.render.Font")
    if okFont and type(Font) == "table" then
      local function localize(text)
        if type(text) ~= "string" then return text end
        local localized = by_english[text]
        return type(localized) == "string" and localized or text
      end
      if type(Font.split) == "function" then
        local original_split = Font.split
        Font.split = function(text) return original_split(localize(text)) end
      end
      if type(Font.draw) == "function" then
        local original_draw = Font.draw
        Font.draw = function(text, x, y, ...) return original_draw(localize(text), x, y, ...) end
      end
    end
  end



-- ---- Intercettazione RAM e Traduzione Città nei Dialoghi ----
  local okTB, TextBox = pcall(require, "src.render.TextBox")
  if okTB and type(TextBox) == "table" and type(TextBox.paginate) == "function" then
    local orig_paginate = TextBox.paginate
    local city_replacements = catalog("city_names")

    TextBox.paginate = function(text, ...)
      if type(text) == "string" then
        for eng, ita in pairs(city_replacements) do
          text = text:gsub(eng, ita)
        end
      end
      return orig_paginate(text, ...)
    end
  end

  -- ---- FIX INVERSIONE STATISTICHE (Senza Crash) ----
  local Strings = require("src.core.Strings")

  if type(Strings) == "table" then
    local mt = getmetatable(Strings) or {}
    local orig_call = mt.__call

    if orig_call then
      mt.__call = function(self, key, arg1, arg2, ...)
        -- Se la chiave riguarda le statistiche e abbiamo entrambi gli argomenti
        if type(key) == "string" and (key:find("rose") or key:find("fell")) and arg1 ~= nil and arg2 ~= nil then
          -- Inverte arg1 (Pokémon) con arg2 (Statistica)
          return orig_call(self, key, arg2, arg1, ...)
        end
        return orig_call(self, key, arg1, arg2, ...)
      end
    end
  end

  -- ---- Pokémon Giallo ---------------------------------------------
  local okGame, GameVersion = pcall(require, "src.core.GameVersion")
  local yellow_game_version = okGame and type(GameVersion) == "table"
      and type(GameVersion.isYellow) == "function"
      and GameVersion.isYellow()
  if yellow_game_version then
    each("dialogue_yellow", function(id, value) mod.content.text:override(id, value) end)
    each("pokedex_yellow", function(id, value) mod.content.text:override(id, value) end)
  end

  -- ---- Griglia Nomi ------------------------------------------------
  local grid = catalog("naming")
  if grid.upper or grid.lower then
    mod.hooks:wrap("ui.naming.grid", function(base, ctx)
      local want = ctx and ctx.lower and grid.lower or grid.upper
      return want or base
    end)
  end

  -- ---- Literal Handlers --------------------------------------------
  local literal_body = mod:read("lang/literal_handlers.lua")
  if literal_body then
    local chunk, err = loadstring(literal_body, "lang/literal_handlers.lua")
    if not chunk then error(err) end
    local setup = chunk()
    if type(setup) ~= "function" then error("literal_handlers.lua deve restituire una funzione") end
    setup(mod)
  end

  -- ---- UI: Menu Lotta ----------------------------------------------
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
      Font.draw(Strings("STRUM."), 56, 128); Font.draw(Strings("FUGA"), 112, 128)
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
        Font.draw(Strings("STRUM."), 56, 128); Font.draw(Strings("FUGA"), 112, 128)
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

  -- ---- UI: Liste e Inventario ------------------------------------
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
        local offset = mod.exports.prezzi_riga and 8 or 0
        Font.draw(item.right, 160 - 8 - Font.width(item.right), y + offset)
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
  local oldTrainerCardDraw = TrainerCard.draw
  function TrainerCard:draw()
    if not mod.exports.trainer_card then
        return oldTrainerCardDraw(self)
    end

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
    Font.draw(Strings("MEDAGLIE"), 48, 73)
    if self.circle then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(self.circle, 36, 72)
      love.graphics.draw(self.circle, 116, 72)
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

  -- ---- UI: Sottomenu Pokémon --------------------------------------
  mod.hooks:wrap("ui.party.submenu", function(next, game, items, mon, ctx)
    local result = next(game, items, mon, ctx)
    if type(result) == "table" then
        for _, item in ipairs(result) do
            if item.action == "switch" then
                item.label = "ORDINA"
            end
        end
    end
    return result
  end)

  -- ---- UI: Fix Schermata del Titolo --------------------------------
  local TitleState = require("src.ui.TitleState")
  local oldTitleDraw = TitleState.draw
  TitleState.draw = function(self)
    oldTitleDraw(self)
    if self.version and not self.yellowLayout and self.phase ~= "drop" and self.phase ~= "settle" then
      local iw, ih = self.version:getDimensions()
      local rx = self.ribbonOffset or 0
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 40 + rx, 64, 104, 8)
      if self.blue then
        love.graphics.draw(self.version, love.graphics.newQuad(88, 0, 72, 8, iw, ih), 48 + rx, 64)
      else
        love.graphics.draw(self.version, love.graphics.newQuad(0, 0, 88, 8, iw, ih), 40 + rx, 64)
      end
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  local oldNew = TitleState.new
  TitleState.new = function(game, opts)
    local self = oldNew(game, opts)
    if self.yellow then
      local ok, logo = pcall(love.graphics.newImage, mod.assets:path("assets/title/yellow_logo.png"))
      if ok and logo then
        logo:setFilter("nearest", "nearest")
        self.logo = logo
      end
      local ok2, bubble = pcall(love.graphics.newImage, mod.assets:path("assets/title/pika_bubble.png"))
      if ok2 and bubble then
        bubble:setFilter("nearest", "nearest")
        self.yellowBubble = bubble
      end
    end
    return self
  end

  -- ---- UI: Fix Casinò ----------------------------------------------
  local originalFontDraw = Font.draw
  local originalFontDrawBox = Font.drawBox

  Font.draw = function(text, x, y, ...)
      if text == Strings("MONEY") and x == 96 and y == 16 then
          x = 88
      elseif text == Strings("COIN") and x == 96 and y == 32 then
          x = 88
      end
      return originalFontDraw(text, x, y, ...)
  end

  Font.drawBox = function(x, y, w, h, ...)
      if x == 11 and y == 0 and w == 9 and h == 7 then
          w = 10
          x = 10
      end
      return originalFontDrawBox(x, y, w, h, ...)
  end

  -- ---- Caricamento Mod Esterne & Tracker ---------------------------
  loadScript("mods/text_tracker.lua")
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