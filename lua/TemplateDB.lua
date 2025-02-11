



TemplateDB = {}

do
    TemplateDB.type = {
        group = 'group',
        static = 'static',
    }

    TemplateDB.templates = {}
    function TemplateDB.getData(objtype)
        return TemplateDB.templates[objtype]
    end

    TemplateDB.templates['player-truck'] = {
        units = { "M 818" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-truck-small'] = {
        units = { "Land_Rover_101_FC" },
        skill = "Good",
        dataCategory = TemplateDB.type.group,
        props = { Variant=3  }
    }

    TemplateDB.templates['player-brad'] = {
        units = { "M-2 Bradley" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-bradaa'] = {
        units = { "M6 Linebacker" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-m113'] = {
        units = { "M-113" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-mlrs'] = {
        units = { "MLRS" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-arty'] = {
        units = { "M-109" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-abrams'] = {
        units = { "M1A2C_SEP_V3" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-m60'] = {
        units = { "M-60" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-mrap'] = {
        units = { "MaxxPro_MRAP" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-hm'] = {
        units = { "M1043 HMMWV Armament" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-hmaa'] = {
        units = { "M1097 Avenger" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates['player-gepard'] = {
        units = { "Gepard" },
        skill = "Good",
        dataCategory = TemplateDB.type.group
    }

    TemplateDB.templates["pilot-replacement"] = {
        units = { "Soldier M4 GRG" },
        skill = "Good",
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["capture-squad"] = {
        units = {
            "Soldier M4 GRG",
            "Soldier M4 GRG",
            "Soldier M249",
            "Soldier M4 GRG"
        },
        skill = "Good",
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["sabotage-squad"] = {
        units = {
            "Soldier M4 GRG",
            "Soldier M249",
            "Soldier M249",
            "Soldier M4 GRG"
        },
        skill = "Good",
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["ambush-squad"] = {
        units = {
            "Soldier RPG",
            "Soldier RPG",
            "Soldier M249",
            "Soldier M4 GRG",
            "Soldier M4 GRG"
        },
        skill = "Good",
        invisible = true,
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["manpads-squad"] = {
        units = {
            "Soldier M4 GRG",
            "Soldier M249",
            "Soldier stinger",
            "Soldier stinger",
            "Soldier M4 GRG"
        },
        skill = "Good",
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["ambush-squad-red"] = {
        units = {
            "Paratrooper RPG-16",
            "Paratrooper RPG-16",
            "Infantry AK ver2",
            "Infantry AK",
            "Infantry AK ver3"
        },
        skill = "Good",
        invisible = true,
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["manpads-squad-red"] = {
        units = {
            "Infantry AK ver3",
            "Infantry AK ver2",
            "SA-18 Igla manpad",
            "SA-18 Igla manpad",
            "Infantry AK"
        },
        skill = "Good",
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["engineer-squad"] = {
        units = {
            "Soldier M4 GRG",
            "Soldier M4 GRG"
        },
        skill = "Good",
        dataCategory= TemplateDB.type.group
    }
    
    TemplateDB.templates["spy-squad"] = {
        units = {
            "Infantry AK"
        },
        skill = "Good",
        invisible = true,
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["rapier-squad"] = {
        units = {
            "rapier_fsa_blindfire_radar",
            "rapier_fsa_optical_tracker_unit",
            "rapier_fsa_launcher",
            "rapier_fsa_launcher",
            "Soldier M4 GRG",
            "Soldier M4 GRG"
        },
        skill = "Excellent",
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["assault-squad"] = {
        units = {
            "Soldier M4 GRG",
            "Soldier M4 GRG",
            "Soldier RPG",
            "Soldier RPG",
            "Soldier M249",
            "Soldier M249"
        },
        skill = "Excellent",
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["assault-squad-red"] = {
        units = {
            "Infantry AK ver3",
            "Paratrooper RPG-16",
            "Paratrooper RPG-16",
            "Infantry AK ver2",
            "Infantry AK",
            "Infantry AK ver3"
        },
        skill = "Excellent",
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["hawksr"] = {
        units = {
            "Hawk sr"
        },
        skill = "Excellent",
        dataCategory= TemplateDB.type.group
    }    
    
    TemplateDB.templates["hawkpcp"] = {
        units = {
            "Hawk pcp"
        },
        skill = "Excellent",
        dataCategory= TemplateDB.type.group
    }

    TemplateDB.templates["tent"] = { type="FARP Tent", category="Fortifications", shape_name="PalatkaB", dataCategory=TemplateDB.type.static }
    TemplateDB.templates["tent_1"] = { type="Tent01", category="Fortifications", shape_name="M92_Tent01", dataCategory=TemplateDB.type.static }
    TemplateDB.templates["tent_2"] = { type="Tent02", category="Fortifications", shape_name="M92_Tent02", dataCategory=TemplateDB.type.static } -- medical
    TemplateDB.templates["tent_3"] = { type="Tent03", category="Fortifications", shape_name="M92_Tent03", dataCategory=TemplateDB.type.static }
    TemplateDB.templates["tent_4"] = { type="Tent04", category="Fortifications", shape_name="M92_Tent04", dataCategory=TemplateDB.type.static }
    TemplateDB.templates["tent_5"] = { type="Tent05", category="Fortifications", shape_name="M92_Tent05", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["barracks"] = { type="house1arm", category="Fortifications", shape_name=nil, dataCategory=TemplateDB.type.static }

    TemplateDB.templates["outpost"] = { type="outpost", category="Fortifications", shape_name=nil, dataCategory=TemplateDB.type.static }

    TemplateDB.templates["ammo-depot"] = { type=".Ammunition depot", category="Warehouses", shape_name="SkladC", dataCategory=TemplateDB.type.static }
    
    TemplateDB.templates["ammo-cache"] = { type="FARP Ammo Dump Coating", category="Fortifications", shape_name="SetkaKP", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["fuel-cache"] = { type="FARP Fuel Depot", category="Fortifications", shape_name="GSM Rus", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["farp-pad"] = { 
        type="FARP_SINGLE_01", 
        category="Heliports", 
        shape_name="FARP_SINGLE_01",
        heliport_callsign_id = 1,
        heliport_modulation = 0,
        heliport_frequency = 127.5,
        dataCategory=TemplateDB.type.static 
    }

    TemplateDB.templates["fuel-tank-small"] = { type="Fuel tank", category="Fortifications", shape_name="toplivo-bak", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["fuel-tank-big"] = { type="Tank", category="Warehouses", shape_name="bak", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["chem-tank"] = { type="Chemical tank A", category="Fortifications", shape_name="him_bak_a", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["factory-1"] = { type="Tech combine", category="Fortifications", shape_name="kombinat", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["factory-2"] = { type="Workshop A", category="Fortifications", shape_name="tec_a", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["oil-pump"] = { type="Pump station", category="Fortifications", shape_name="nasos", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["hangar"] = { type="Hangar A", category="Fortifications", shape_name="angar_a", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["excavator"] = { type="345 Excavator", category="Fortifications", shape_name="cat_3451", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["farm-house-1"] = { type="Farm A", category="Fortifications", shape_name="ferma_a", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["farm-house-2"] = { type="Farm B", category="Fortifications", shape_name="ferma_b", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["antenna"] = { type="Comms tower M", category="Fortifications", shape_name="tele_bash_m", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["tv-tower"] = { type="TV tower", category="Fortifications", shape_name="tele_bash", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["command-center"] = { type=".Command Center", category="Fortifications", shape_name="ComCenter", dataCategory=TemplateDB.type.static }
    
    TemplateDB.templates["military-staff"] = { type="Military staff", category="Fortifications", shape_name="aviashtab", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["building1"] = { type="Building01_PBR", category="Fortifications", shape_name="M92_Building01_PBR", dataCategory=TemplateDB.type.static } -- factory/tech
    TemplateDB.templates["building2"] = { type="Building02_PBR", category="Fortifications", shape_name="M92_Building02_PBR", dataCategory=TemplateDB.type.static } -- factory/tech
    TemplateDB.templates["building3"] = { type="Building03_PBR", category="Fortifications", shape_name="M92_Building03_PBR", dataCategory=TemplateDB.type.static } -- factory/tech
    TemplateDB.templates["building4"] = { type="Building04_PBR", category="Fortifications", shape_name="M92_Building04_PBR", dataCategory=TemplateDB.type.static } -- factory/tech
    TemplateDB.templates["building5"] = { type="Building05_PBR", category="Fortifications", shape_name="M92_Building05_PBR", dataCategory=TemplateDB.type.static } -- farm building?
    TemplateDB.templates["building6"] = { type="Building06_PBR", category="Fortifications", shape_name="M92_Building06_PBR", dataCategory=TemplateDB.type.static } -- farm building?
    TemplateDB.templates["building7"] = { type="Building07_PBR", category="Fortifications", shape_name="M92_Building07_PBR", dataCategory=TemplateDB.type.static } -- compost
    TemplateDB.templates["building8"] = { type="Building08_PBR", category="Fortifications", shape_name="M92_Building08_PBR", dataCategory=TemplateDB.type.static } -- compost

    TemplateDB.templates["tower1"] = { type="Container_watchtower", category="Fortifications", shape_name="M92_Container_watchtower", dataCategory=TemplateDB.type.static }
    TemplateDB.templates["hesco_gen"] = { type="HESCO_generator", category="Fortifications", shape_name="M92_HESCO_generator", dataCategory=TemplateDB.type.static } -- can work as ammo cache

    TemplateDB.templates["hesco1"] = { type="HESCO_post_1", category="Fortifications", shape_name="M92_HESCO_post_1", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["hesco_tower1"] = { type="HESCO_watchtower_1", category="Fortifications", shape_name="M92_HESCO_watchtower_1", dataCategory=TemplateDB.type.static }
    TemplateDB.templates["hesco_tower2"] = { type="HESCO_watchtower_2", category="Fortifications", shape_name="M92_HESCO_watchtower_2", dataCategory=TemplateDB.type.static }
    TemplateDB.templates["hesco_tower3"] = { type="HESCO_watchtower_3", category="Fortifications", shape_name="M92_HESCO_watchtower_3", dataCategory=TemplateDB.type.static }
    
    TemplateDB.templates["forklift"] = { type="CV_59_H60", category="ADEquipment", shape_name=nil, dataCategory=TemplateDB.type.static }

    TemplateDB.templates["ammo-boxes"] = { type="Cargo06", category="Fortifications", shape_name="M92_Cargo06", dataCategory=TemplateDB.type.static }
    TemplateDB.templates["fuel-barrels"] = { type="Cargo05", category="Fortifications", shape_name="M92_Cargo05", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["hq-building"] = { type="af_hq", category="Fortifications", shape_name="syr_af_hq", dataCategory=TemplateDB.type.static }

    -- mass 1000 to 2000
    TemplateDB.templates['ammo_box'] = { type="ammo_cargo", category="Cargos", shape_name="ammo_box_cargo", dataCategory=TemplateDB.type.static}
    
    -- mass 100 to 480
    TemplateDB.templates['barrels'] = { type="barrels_cargo", category="Cargos", shape_name="barrels_cargo", dataCategory=TemplateDB.type.static}
    
    -- mass 100 to 4000
    TemplateDB.templates['container'] = { type="container_cargo", category="Cargos", shape_name="bw_container_cargo", dataCategory=TemplateDB.type.static }
    
    -- mass 100 to 10000
    TemplateDB.templates['cargonet'] = { type="uh1h_cargo", category="Cargos", shape_name="ab-212_cargo", dataCategory=TemplateDB.type.static }
end

