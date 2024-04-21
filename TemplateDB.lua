
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

    TemplateDB.templates["tent"] = { type="FARP Tent", category="Fortifications", shape="PalatkaB", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["barracks"] = { type="house1arm", category="Fortifications", shape=nil, dataCategory=TemplateDB.type.static }

    TemplateDB.templates["outpost"] = { type="outpost", category="Fortifications", shape=nil, dataCategory=TemplateDB.type.static }

    TemplateDB.templates["ammo-cache"] = { type="FARP Ammo Dump Coating", category="Fortifications", shape="SetkaKP", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["ammo-depot"] = { type=".Ammunition depot", category="Warehouses", shape="SkladC", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["fuel-cache"] = { type="FARP Fuel Depot", category="Fortifications", shape="GSM Rus", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["fuel-tank-small"] = { type="Fuel tank", category="Fortifications", shape="toplivo-bak", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["fuel-tank-big"] = { type="Tank", category="Warehouses", shape="bak", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["chem-tank"] = { type="Chemical tank A", category="Fortifications", shape="him_bak_a", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["factory-1"] = { type="Tech combine", category="Fortifications", shape="kombinat", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["factory-2"] = { type="Workshop A", category="Fortifications", shape="tec_a", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["oil-pump"] = { type="Pump station", category="Fortifications", shape="nasos", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["hangar"] = { type="Hangar A", category="Fortifications", shape="angar_a", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["excavator"] = { type="345 Excavator", category="Fortifications", shape="cat_3451", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["farm-house-1"] = { type="Farm A", category="Fortifications", shape="ferma_a", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["farm-house-2"] = { type="Farm B", category="Fortifications", shape="ferma_b", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["antenna"] = { type="Comms tower M", category="Fortifications", shape="tele_bash_m", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["tv-tower"] = { type="TV tower", category="Fortifications", shape="tele_bash", dataCategory=TemplateDB.type.static }

    TemplateDB.templates["command-center"] = { type=".Command Center", category="Fortifications", shape="ComCenter", dataCategory=TemplateDB.type.static }
    
    TemplateDB.templates["military-staff"] = { type="Military staff", category="Fortifications", shape="aviashtab", dataCategory=TemplateDB.type.static }
end

