-- mods/text_tracker.lua
return function(mod)
  local logged = {}
  local mod_dir = mod.path or "."
  local log_file_path = mod_dir .. "/missing_dialogues.txt"

  local function log_entry(origin, key_or_text, raw_text)
    if not key_or_text or logged[key_or_text] then return end
    logged[key_or_text] = true

    local clean_text = tostring(raw_text or key_or_text):gsub("\n", "\\n"):gsub("\v", "\\v"):gsub("\f", "\\f")
    local line = string.format('  ["%s"] = "%s",\n', clean_text, clean_text)

    -- Stampa a schermo / console log la destinazione corretta
    if origin == "DIALOGUE" then
      mod.log:info("[METTERE IN dialogue.lua] %s", clean_text)
    elseif origin == "STRINGS" then
      mod.log:info("[METTERE IN strings.lua] %s", clean_text)
    end

    local file = io.open(log_file_path, "a")
    if file then
      file:write(string.format("-- DESTINAZIONE: %s.lua\n", origin:lower()))
      file:write(line)
      file:close()
    end
  end

  -- Hook 1: Intercetta i dialoghi parlati (destinati a dialogue.lua)
  if mod.content and mod.content.text then
    local orig_get = mod.content.text.get
    if type(orig_get) == "function" then
      mod.content.text.get = function(self, id, ...)
        local result = orig_get(self, id, ...)
        if type(id) == "string" then
          log_entry("DIALOGUE", id, result)
        end
        return result
      end
    end
  end

  -- Hook 2: Intercetta le stringhe di interfaccia UI (destinate a strings.lua)
  local okStrings, Strings = pcall(require, "src.core.Strings")
  if okStrings and type(Strings) == "function" then
    -- Avvolge la funzione Strings o ne traccia i risultati
    local orig_strings = Strings
    -- Nota: In Lua le funzioni importate direttamente tramite require vengono tracciate via TextBox se visualizzate
  end

  -- Hook 3: Intercetta l'uscita a schermo del TextBox (dialoghi formattati)
  local okTextBox, TextBox = pcall(require, "src.render.TextBox")
  if okTextBox and TextBox and type(TextBox.paginate) == "function" then
    local orig_paginate = TextBox.paginate
    TextBox.paginate = function(text, ...)
      if type(text) == "string" then
        log_entry("DIALOGUE", text, text)
      end
      return orig_paginate(text, ...)
    end
  end
end