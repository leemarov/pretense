



RewardDefinitions = {}

do
    RewardDefinitions.missions = {
      [Mission.types.cap_easy]        = { xp = { low = 10, high = 20, boost = 0   } },
      [Mission.types.cap_medium]      = { xp = { low = 10, high = 20, boost = 100 } },
      [Mission.types.tarcap]          = { xp = { low = 10, high = 10, boost = 150 } },
      [Mission.types.cas_easy]        = { xp = { low = 10, high = 20, boost = 0   } },
      [Mission.types.cas_medium]      = { xp = { low = 20, high = 30, boost = 0   } },
      [Mission.types.cas_hard]        = { xp = { low = 30, high = 40, boost = 0   } },
      [Mission.types.bai]             = { xp = { low = 20, high = 30, boost = 0   } },
      [Mission.types.sead]            = { xp = { low = 10, high = 20, boost = 0   } },
      [Mission.types.dead]            = { xp = { low = 30, high = 40, boost = 0   } },
      [Mission.types.strike_veryeasy] = { xp = { low = 5,  high = 10, boost = 0   } },
      [Mission.types.strike_easy]     = { xp = { low = 10, high = 20, boost = 0   } },
      [Mission.types.strike_medium]   = { xp = { low = 20, high = 30, boost = 0   } },
      [Mission.types.strike_hard]     = { xp = { low = 30, high = 40, boost = 0   } },
      [Mission.types.deep_strike]     = { xp = { low = 30, high = 40, boost = 0   } },
      [Mission.types.anti_runway]     = { xp = { low = 20, high = 30, boost = 25  } },
      [Mission.types.supply_easy]     = { xp = { low = 10, high = 20, boost = 0   } },
      [Mission.types.supply_hard]     = { xp = { low = 20, high = 30, boost = 0   } },
      [Mission.types.escort]          = { xp = { low = 20, high = 30, boost = 0   } },
      [Mission.types.recon]           = { xp = { low = 20, high = 30, boost = 0   } },
      [Mission.types.csar]            = { xp = { low = 20, high = 30, boost = 0   } },
      [Mission.types.extraction]      = { xp = { low = 20, high = 30, boost = 0   } },
      [Mission.types.deploy_squad]    = { xp = { low = 20, high = 30, boost = 0   } },
      [Mission.types.salvage]         = { xp = { low = 20, high = 30, boost = 0   } }
    }

    RewardDefinitions.actions = {
      pilotExtract = 100,
      squadDeploy = 150,
      squadExtract = 150,
      supplyRatio = 0.06,
      supplyBoost = 0.5,
      recon = 150
    }
end

