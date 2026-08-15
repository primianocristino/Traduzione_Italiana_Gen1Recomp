-- debug_text.lua - Inspector / Debugger dei dialoghi a schermo
return function(mod)
  local TextBox = require("src.render.TextBox")
  local Font = require("src.render.Font")
  
  -- Tabella in memoria per evitare di loggare 100 volte lo stesso dialogo
  local logged_keys = {}
  local current_active_key = nil

  -- Funzione per salvare le chiavi su file fisico
  local function log_missing_key(key, text)
    if logged_keys[key] then return end
    logged_keys[key] = true

    -- Format LUA pronto da copiare/incollare in dialogue.lua
    local formatted_text = tostring(text):gsub("\n", "\\n"):gsub("\v", "\\v"):gsub("\f", "\\f")
    local line = string.format('  ["%s"] = "%s",\n', key, formatted_text)

    -- Logga sulla console di LÖVE / Recompilation
    mod.log:info("[TEXT_DEBUG] CHIAVE TROVATA: %s", key)
    print("--------------------------------------------------")
    print(line)
    print("--------------------------------------------------")

    -- Salva nel file missing_dialogues.txt della cartella dati Love2D
    local ok, err = pcall(function()
      love.filesystem.append("missing_dialogues.txt", line)
    end)
  end

  -- 1. HOOK SUL RECUPERO CHIAVI (Intercetta ogni testo richiesto)
  if mod.content and mod.content.text then
    local old_get = mod.content.text.get
    mod.content.text.get = function(self, id, ...)
      local result = old_get(self, id, ...)
      if id and type(id) == "string" then
        current_active_key = id
        log_missing_key(id, result)
      end
      return result
    end
  end

  -- 2. HOOK SUL RENDERER DEL TEXTBOX (Mostra la Chiave in overlay a schermo)
  if TextBox and TextBox.draw then
    local old_draw = TextBox.draw
    TextBox.draw = function(self, ...)
      old_draw(self, ...)
      
      -- Se c'è una chiave attiva nel dialogo corrente, la disegna sopra la finestra
      if current_active_key then
        love.graphics.setColor(1, 0, 0, 1) -- Testo Rosso
        Font.draw(tostring(current_active_key), 8, 104)
        love.graphics.setColor(1, 1, 1, 1)
      end
    end
  end

  mod.log:info(" Debugger dei dialoghi attivato con successo!")
end