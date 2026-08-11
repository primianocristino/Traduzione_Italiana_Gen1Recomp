-- pokemon_red_italiano: a translation of the game into italian.
return function(mod)
  local function catalog(name)
    local rel = "lang/" .. name .. ".lua"
    local body = mod:read(rel)
    if not body then return {} end
    local chunk, err = loadstring(body, rel)
    if not chunk then
      mod.log:warn("%s has a syntax error: %s", rel, tostring(err))
      return {}
    end
    local ok, table_ = pcall(chunk)
    if not ok or type(table_) ~= "table" then
      mod.log:warn("%s did not return a table: %s", rel, tostring(table_))
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

  -- ---- glyphs -------------------------------------------------------
  for id, page in pairs(catalog("font")) do
    mod.content.font:register(id, page)
  end
  for seq, code in pairs(catalog("charmap")) do
    mod.content.font:register("charmap:" .. seq, { seq = seq, code = code })
  end

  -- ---- text ---------------------------------------------------------
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

  -- ---- name entry ---------------------------------------------------
  local grid = catalog("naming")
  if grid.upper then
    mod.hooks:on("ui.naming.grid", function(base, ctx)
      local want = ctx.lower and grid.lower or grid.upper
      return want or base
    end)
  end

  -- ---- caricamento mod esterne ---------------------------------------
  loadScript("mods/nuzlocke.lua")
  loadScript("mods/example_mew_starter.lua")
  loadScript("mods/dramatic_shape.lua")
  loadScript("mods/translation_debug.lua")
  loadScript("mods/CryReplacementMod.lua")
  loadScript("mods/MusicReplacementMod.lua")
  loadScript("mods/android_voxel_fix.lua")
  -- ---- ready event ---------------------------------------------------
  mod.events:on("game.ready", function()
    local total = 0
    for _, n in pairs(counts) do total = total + n end
    mod.log:info("Italiano: %d strings translated", total)
  end)
end