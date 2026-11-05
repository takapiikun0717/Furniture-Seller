extends Node

# MCM registration for Furniture Seller. Settings are shared through Engine meta "FurnitureSellerSettings".

const MOD_ID = "FurnitureSeller"
const MOD_TITLE = "Furniture Seller"
const MOD_DESC = "Sell furniture from the Decor Mode catalog for Cash Money euros."
const FILE_PATH = "user://MCM/" + MOD_ID
const MCM_HELPERS_PATH = "res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres"

var McmHelpers = null
var menuPos = 0

func _ready():
	Engine.set_meta("FurnitureSellerSettings", {"sell_ratio": 0.8})

	if ResourceLoader.exists(MCM_HELPERS_PATH):
		McmHelpers = load(MCM_HELPERS_PATH)
	if McmHelpers == null:
		return

	var config = ConfigFile.new()
	config.set_value("Category", "General", {"menu_pos": 1})
	config.set_value("Float", "sell_ratio", {
		"name": "Sell Ratio",
		"tooltip": "Fraction of the furniture's value you receive when selling (0.8 = 80%).",
		"default": 0.8,
		"value": 0.8,
		"minRange": 0.0,
		"maxRange": 2.0,
		"menu_pos": 1,
		"category": "General"
	})

	var configPath = FILE_PATH + "/config.ini"
	if !FileAccess.file_exists(configPath):
		DirAccess.open("user://").make_dir_recursive(FILE_PATH)
		config.save(configPath)
	else:
		McmHelpers.CheckConfigurationHasUpdated(MOD_ID, config, configPath)
		config.load(configPath)

	McmHelpers.RegisterConfiguration(MOD_ID, MOD_TITLE, FILE_PATH, MOD_DESC, OnConfigChanged, self)
	ApplySettings(McmHelpers.GetModConfigFile(MOD_ID))

func OnConfigChanged(config: ConfigFile):
	ApplySettings(config)

func ApplySettings(config: ConfigFile):
	if config == null:
		return
	var ratio = config.get_value("Float", "sell_ratio", {"value": 0.8})["value"]
	Engine.set_meta("FurnitureSellerSettings", {"sell_ratio": float(ratio)})
