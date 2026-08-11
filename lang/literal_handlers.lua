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
end