local SCREEN_ID = "VersioneItalianaOptions"

local M = {}

function M.install(mod)

  -- ==========================================
  -- Opzioni persistenti
  -- ==========================================

  mod.options:define({
    {
      key = "lingua_mosse",
      type = "choice",
      default = "gen1",
      choices = {
        { "GEN1", "gen1" },
        { "ITALIANO", "italiano" },
        { "INGLESE", "inglese" },
      },
    },

    {
      key = "mostra_nemico",
      type = "choice",
      default = false,
      choices = {
        { "SÌ", true },
        { "NO", false },
      },
    },

    {
      key = "prezzi_riga",
      type = "choice",
      default = true,
      choices = {
        { "RIGA SOTTO", true },
        { "STESSA RIGA", false },
      },
    },

    {
      key = "trainer_card",
      type = "choice",
      default = true,
      choices = {
        { "CORRETTA", true },
        { "ORIGINALE", false },
      },
    },
  })

  -- ==========================================
  -- Funzioni per le opzioni
  -- ==========================================

  local function getOption(game, key)
    local options = game.save and game.save.options

    local bucket = options
      and options.modOptions
      and options.modOptions[mod.id]

    if bucket and bucket[key] ~= nil then
      return bucket[key]
    end

    return mod.options:get(key)
  end

  local function setOption(game, key, value)
    game.save.options.modOptions =
      game.save.options.modOptions or {}

    game.save.options.modOptions[mod.id] =
      game.save.options.modOptions[mod.id] or {}

    game.save.options.modOptions[mod.id][key] = value

    if game.mods then
      game.mods.modOptions =
        game.mods.modOptions or {}

      game.mods.modOptions[mod.id] =
        game.mods.modOptions[mod.id] or {}

      game.mods.modOptions[mod.id][key] = value
    end

    if game.writeOptions then
      game:writeOptions()
    end
  end

  -- ==========================================
  -- Schermata delle opzioni
  -- ==========================================

  mod.content.screens:register(SCREEN_ID, {
    new = function(game)

      if mod.exports.prezzi_riga == nil then
        mod.exports.prezzi_riga = true
      end

      if mod.exports.trainer_card == nil then
        mod.exports.trainer_card = true
      end

      local Font = mod.ui.Font

      -- Carica i valori salvati
      mod.exports.lingua_mosse =
        getOption(game, "lingua_mosse")

      mod.exports.mostra_nemico =
        getOption(game, "mostra_nemico")

      mod.exports.prezzi_riga =
        getOption(game, "prezzi_riga")

      mod.exports.trainer_card =
        getOption(game, "trainer_card")

      local rows = {
        {
          label = "LINGUA MOSSE",
          key = "lingua_mosse",
          value = mod.exports.lingua_mosse,
        },

        {
          label = "MOSTRA NEMICO",
          key = "mostra_nemico",
          value = mod.exports.mostra_nemico,
        },

        {
          label = "PREZZI E Q.TÀ",
          key = "prezzi_riga",
          value = mod.exports.prezzi_riga,
        },

        {
          label = "SCHEDA ALLENAT.",
          key = "trainer_card",
          value = mod.exports.trainer_card,
        },
      }

      local screen = {
        game = game,
        rows = rows,
        index = 1,
        isOpaque = true,
      }

      function screen:update()
        local input = game.input
        local row = self.rows[self.index]

        if input:wasPressed("up") then

          self.index = self.index > 1
            and self.index - 1
            or #self.rows

        elseif input:wasPressed("down") then

          self.index = self.index < #self.rows
            and self.index + 1
            or 1

        elseif input:wasPressed("left")
          or input:wasPressed("right")
          or input:wasPressed("a") then

          -- ==========================================
          -- LINGUA MOSSE
          -- GEN1 -> ITALIANO -> INGLESE -> GEN1
          -- ==========================================

          if self.index == 1 then

            if row.value == "gen1" then
              row.value = "italiano"

            elseif row.value == "italiano" then
              row.value = "inglese"

            else
              row.value = "gen1"
            end

            setOption(
              game,
              "lingua_mosse",
              row.value
            )

            mod.exports.lingua_mosse = row.value

          -- ==========================================
          -- MOSTRA "NEMICO"
          -- ==========================================

          elseif self.index == 2 then

            row.value = not row.value

            setOption(
              game,
              "mostra_nemico",
              row.value
            )

            mod.exports.mostra_nemico = row.value

          -- ==========================================
          -- PREZZI E Q.TÀ
          -- ==========================================

          elseif self.index == 3 then

            row.value = not row.value

            setOption(
              game,
              "prezzi_riga",
              row.value
            )

            mod.exports.prezzi_riga = row.value

          -- ==========================================
          -- TRAINER CARD
          -- ==========================================

          elseif self.index == 4 then

            row.value = not row.value

            setOption(
              game,
              "trainer_card",
              row.value
            )

            mod.exports.trainer_card = row.value
          end

        elseif input:wasPressed("b") then
          game.stack:pop()
        end
      end

      function screen:draw()

        Font.drawBox(0, 0, 20, 18)

        for i, row in ipairs(self.rows) do

          local y = 8 + (i - 1) * 24

          if i == self.index then
            Font.drawCode(0xED, 16, y + 8)
          end

          Font.draw(row.label, 16, y)

          local value = row.value

          if row.key == "lingua_mosse" then

            if value == "gen1" then
              value = "GEN1"

            elseif value == "italiano" then
              value = "ITALIANO"

            elseif value == "inglese" then
              value = "INGLESE"
            end

          elseif row.key == "mostra_nemico" then

            value = value and "SI" or "NO"

          elseif row.key == "prezzi_riga" then

            value = value and "RIGA SOTTO" or "STESSA RIGA"

          elseif row.key == "trainer_card" then

            value = value and "CORRETTA" or "ORIGINALE"
          end

          Font.draw(value, 24, y + 8)
        end

        Font.draw("B: INDIETRO", 8, 112)
        Font.draw("NOTA:RIAVVIA PER", 8, 120)
        Font.draw("     OPZIONI 1 E 2", 8, 128)
      end

      return screen
    end,
  })

  -- ==========================================
  -- OPTIONS > MODS
  -- ==========================================

  mod.hooks:wrap("ui.options.rows", function(next, game, rows)

    local out = next(game, rows)

    if type(out) ~= "table" then
      return out
    end

    return mod.ui.insertBefore(out, "MODS", {
      id = "versioneitaliana",

      label = "VERSIONE ITALIANA",

      value = function()
        return " OPZIONI EXTRA"
      end,

      activate = function(g)
        mod.ui.push(g, SCREEN_ID)
      end,
    })
  end)
end

return M