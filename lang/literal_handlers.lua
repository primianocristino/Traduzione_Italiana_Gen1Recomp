-- Gestori dinamici dei dialoghi letterali generati da qid.
return function(mod)
  local TextBox = mod.ui.TextBox
  local ChoiceBox = mod.ui.ChoiceBox
  mod.content.map_scripts:register("VIRIDIAN_CITY", {talk = {
    ["TEXT_VIRIDIANCITY_YOUNGSTER2"] = function(game, ow, npc, done)
      game.stack:push(TextBox.new(game, "Vuoi informazioni\nsui 2 tipi di\011POKéMON bruco?", function()
        game.stack:push(ChoiceBox.new(game, function(yes)
          game.stack:push(TextBox.new(game, yes and "CATERPIE non é\nvelenoso, ma\011WEEDLE si.\012Attento alla sua\nVELENOPUNTURA!" or "Ah, va bene\nallora!", done))
        end))
      end))
    end,
  },
  })
  mod.content.map_scripts:register("MUSEUM_1F", {talk = {
    ["TEXT_MUSEUM1F_SCIENTIST1"] = function(game, ow, npc, done)
      if game.save.flags["EVENT_BOUGHT_MUSEUM_TICKET"] then
        game.stack:push(TextBox.new(game, "Guarda pure per\ntutto il tempo\011che desideri!", done))
      else
        game.stack:push(TextBox.new(game, "Un biglietto per\nragazzi costa 50¥.\012Vuoi entrare?", function()
          game.stack:push(ChoiceBox.new(game, function(yes)
            if yes then
              if (game.save.money or 0) >= 50 then
                game.save.money = (game.save.money or 0) + (-50)
                game.save.flags["EVENT_BOUGHT_MUSEUM_TICKET"] = true
                game.stack:push(TextBox.new(game, "50¥! Ottimo!\nGrazie!", done))
              else
                game.stack:push(TextBox.new(game, "Non hai abbastanza\nsoldi.", done))
              end
            else
              game.stack:push(TextBox.new(game, "Torna a trovarci!", done))
            end
          end))
        end))
      end
    end,
  },
    onStep = function(game, ow, x, y)
      if ((x == 9 and y == 4) or (x == 10 and y == 4)) and not game.save.flags["EVENT_BOUGHT_MUSEUM_TICKET"] then
        local function on_done() end
        game.stack:push(TextBox.new(game, "Un biglietto per\nragazzi costa 50¥.\012Vuoi entrare?", function()
          game.stack:push(ChoiceBox.new(game, function(yes)
            if yes then
              if (game.save.money or 0) >= 50 then
                game.save.money = (game.save.money or 0) + (-50)
                game.save.flags["EVENT_BOUGHT_MUSEUM_TICKET"] = true
                game.stack:push(TextBox.new(game, "Perfetto, 50¥!\nGrazie!", on_done))
              else
                game.stack:push(TextBox.new(game, "Non hai abbastanza\nsoldi.", function()
                  ow:scriptMove(ow.player, "down", 1, on_done)
                end))
              end
            else
              game.stack:push(TextBox.new(game, "Torna a trovarci!", function()
                ow:scriptMove(ow.player, "down", 1, on_done)
              end))
            end
          end))
        end))
        return true
      end
      return false
    end,
  })
  mod.content.map_scripts:register("BIKE_SHOP", {talk = {
    ["TEXT_BIKESHOP_CLERK"] = function(game, ow, npc, done)
      if (game.save.inventory["BICYCLE"] or 0) > 0 then
        game.stack:push(TextBox.new(game, "Ti piace la tua\nnuova BICICLETTA?\012Puoi andarci sulla\nPISTA CICLABILE e\011nelle grotte!", done))
      else
        if (game.save.inventory["BIKE_VOUCHER"] or 0) > 0 then
          game.stack:push(TextBox.new(game, "Oh, ma questo é...\012un BUONO BICI!\012OK! Ecco a te!", function()
            game.save.inventory["BIKE_VOUCHER"] = nil
            game.save.inventory["BICYCLE"] = 1
            game.save.flags["EVENT_GOT_BICYCLE"] = true
            game.stack:push(TextBox.new(game, "{PLAYER} scambia\nil BUONO BICI con\011una BICICLETTA.", done))
          end))
        else
          game.stack:push(TextBox.new(game, "Ciao! Benvenuto al\nNEGOZIO BICI.\012Abbiamo la bici\nperfetta per te!", done))
        end
      end
    end,
  },
  })
  mod.content.map_scripts:register("BIKE_SHOP", {talk = {
    ["TEXT_BIKESHOP_MIDDLE_AGED_WOMAN"] = function(game, ow, npc, done)
      game.stack:push(TextBox.new(game, "Una BICICLETTA\nda citta' mi basta\011e avanza!\012Non puoi mettere\nun cestino per la\011spesa su una\011Mountain BIKE!", done))
    end,
  },
  })
  mod.content.map_scripts:register("BIKE_SHOP", {talk = {
    ["TEXT_BIKESHOP_YOUNGSTER"] = function(game, ow, npc, done)
      if (game.save.flags["EVENT_GOT_BICYCLE"] or (game.save.inventory["BICYCLE"] or 0) > 0) then
        game.stack:push(TextBox.new(game, "Uau! La tua\nBICICLETTA é\011fantastica!", done))
      else
        game.stack:push(TextBox.new(game, "Quelle BICICLETTE\nsono belle, ma\011costano troppo!", done))
      end
    end,
  },
  })





mod.content.map_scripts:register("ROUTE_24", {
  talk = {
    ["TEXT_ROUTE24_COOLTRAINER_M1"] = function(game, ow, npc, done)
      -- 1. Se il reclutatore del Team Rocket e' gia' stato sconfitto
      if game.save.flags["EVENT_BEAT_ROUTE24_ROCKET"] then
        game.stack:push(TextBox.new(game, "Con le tue capacita'\npotresti diventare\011un capo del\011TEAM ROCKET!", done))
        return
      end

      -- Avvio della battaglia e impostazione del flag di vittoria
      local function start_battle()
        mod.log:info("--- DEBUG: Avvio battaglia con ow:engageTrainer ---")
        if ow and type(ow.engageTrainer) == "function" then
          game.save.flags["EVENT_BEAT_ROUTE24_ROCKET"] = true
          ow:engageTrainer(npc, done)
        else
          mod.log:warn("--- DEBUG: ow:engageTrainer non trovato, chiusura dialogo ---")
          done()
        end
      end

      -- Domanda di reclutamento
      local function ask_join()
        game.stack:push(TextBox.new(game, "A proposito, ti\nandrebbe di unirti\011al TEAM ROCKET?", function()
          game.stack:push(ChoiceBox.new(game, function(yes)
            game.stack:push(TextBox.new(game, "Argh! Non sei\nconvinto?\012Allora ti mostrero'\nil mio potere!", function()
              start_battle()
            end))
          end))
        end))
      end

      -- Funzione per verificare se l'inventario è pieno
      local function check_inventory_full()
        -- Metodo standard basato sulla struttura inventory del motore
        if game.save.inventory.isFull and type(game.save.inventory.isFull) == "function" then
          return game.save.inventory:isFull("NUGGET")
        elseif game.save.inventory.hasSpace and type(game.save.inventory.hasSpace) == "function" then
          return not game.save.inventory:hasSpace("NUGGET")
        end

        -- Fallback di controllo basato su limiti standard di Gen 1 (es. 20 slot massimi nell'inventario)
        local count = 0
        for _ in pairs(game.save.inventory) do
          count = count + 1
        end
        -- Se ci sono già 20 o più voci distinte e non possediamo già una Pepita accumulabile nello stesso slot
        if count >= 20 and not (game.save.inventory["NUGGET"] and game.save.inventory["NUGGET"] > 0) then
          return true
        end

        return false
      end

      -- 2. Consegna della Pepita se non ancora ricevuta
      if not game.save.flags["EVENT_GOT_NUGGET"] then
        game.stack:push(TextBox.new(game, "Complimenti!\nHai battuto i nostri 5\011allenatori della sfida!\012Hai appena vinto un\npremio favoloso!", function()
          
          -- Controllo dello spazio nell'inventario prima di consegnare
          if check_inventory_full() then
            mod.log:info("--- DEBUG: Inventario pieno, impossibile consegnare la Pepita ---")
            game.stack:push(TextBox.new(game, "Non hai abbastanza\nspazio!", done))
            return
          end

          game.save.inventory["NUGGET"] = (game.save.inventory["NUGGET"] or 0) + 1
          game.save.flags["EVENT_GOT_NUGGET"] = true
          mod.log:info("--- DEBUG: Pepita aggiunta all'inventario. Totale: " .. tostring(game.save.inventory["NUGGET"]) .. " ---")

          game.stack:push(TextBox.new(game, "{PLAYER} riceve\nuna PEPITA!", function()
            ask_join()
          end))
        end))
      else
        ask_join()
      end
    end,
  },
})

end