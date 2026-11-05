extends "res://Scripts/Context.gd"

# Furniture Seller
# Adds a "Sell" button to the right-click menu of furniture in the Decor Mode catalog.
# Selling removes the furniture from the catalog and gives Cash Money euros.
# Requires the Cash Money mod.

const FS_EURO_DATA_PATH = "res://mods/CashMoney/Items/Money/Stack_Euro_1/Stack_Euro_1.tres"
const FS_DEFAULT_SELL_RATIO = 0.8

var fsSellButton: Button
var fsSellProgress: ProgressBar

func _ready():
	super._ready()
	fsCreateButton()

func fsCreateButton():
	# Copy the Destroy button (including its hold progress bar) so selling works as a hold-to-confirm button
	fsSellButton = destroyButton.duplicate(6) # 2 (groups) + 4 (scripts) = no signals
	fsSellButton.name = "FurnitureSell"
	fsSellButton.text = "Sell"
	fsSellButton.disabled = false
	fsSellButton.tooltip_text = "Hold to sell"
	fsSellButton.hide()
	buttons.add_child(fsSellButton)
	buttons.move_child(fsSellButton, destroyButton.get_index())
	fsSellProgress = fsSellButton.get_node_or_null("Progress")
	if fsSellProgress:
		fsSellProgress.value = 0.0

func _physics_process(delta):
	super._physics_process(delta)
	if fsSellButton != null && fsSellButton.visible:
		fsHoldProgress(delta)

func fsHoldProgress(delta):
	if fsSellProgress == null:
		return
	if fsSellButton.is_pressed():
		fsSellProgress.value += delta * 100.0
	else:
		fsSellProgress.value = 0.0
	if fsSellProgress.value >= 100.0 && interface.visible:
		fsSellProgress.value = 0.0
		fsDoSell()

func Update(slotData: SlotData):
	super.Update(slotData)
	if fsSellButton == null:
		return
	fsSellButton.hide()
	if fsSellProgress:
		fsSellProgress.value = 0.0
	var contextItem = interface.contextItem
	if contextItem == null:
		return
	if gameData.decor && interface.contextGrid == interface.catalogGrid && contextItem.slotData.itemData.type == "Furniture":
		fsSellButton.text = "Sell (" + str(fsGetPrice(contextItem)) + ")"
		fsSellButton.show()
		# Same placement logic as the original Update(), now that the menu has one more button
		panel.size = Vector2(80.0, 0.0)
		panel.global_position = get_global_mouse_position() - Vector2(0, panel.size.y)
		centerPosition = get_global_mouse_position() - Vector2(-panel.size.x / 2, panel.size.y / 2)

func fsGetSellRatio() -> float:
	var ratio = FS_DEFAULT_SELL_RATIO
	if Engine.has_meta("FurnitureSellerSettings"):
		ratio = float(Engine.get_meta("FurnitureSellerSettings").get("sell_ratio", FS_DEFAULT_SELL_RATIO))
	return maxf(ratio, 0.0)

func fsGetPrice(contextItem) -> int:
	var baseValue = 0.0
	if contextItem.has_method("Value"):
		baseValue = float(contextItem.Value())
	else:
		baseValue = float(contextItem.slotData.itemData.value)
	return int(round(baseValue * fsGetSellRatio()))

func fsDoSell():
	if !interface.visible:
		return
	var contextItem = interface.contextItem
	var contextGrid = interface.contextGrid
	if contextItem == null || contextGrid == null || contextGrid != interface.catalogGrid:
		return
	if contextItem.slotData.storage.size() != 0:
		Loader.Message("Empty the furniture's storage before selling it.", Color.RED)
		interface.PlayError()
		return
	if !ResourceLoader.exists(FS_EURO_DATA_PATH):
		Loader.Message("Cash Money mod is required to sell furniture.", Color.RED)
		interface.PlayError()
		return
	var price = fsGetPrice(contextItem)
	if price <= 0:
		Loader.Message("This furniture can't be sold.", Color.RED)
		interface.PlayError()
		return

	var cashSlotData = SlotData.new()
	cashSlotData.itemData = load(FS_EURO_DATA_PATH)
	cashSlotData.amount = price

	var furnitureName = contextItem.slotData.itemData.name
	contextGrid.Pick(contextItem)
	contextItem.queue_free()

	# Same as Cash Money: stack onto existing euros, otherwise create a new stack (dropped if the inventory is full)
	if !interface.AutoStack(cashSlotData, interface.inventoryGrid):
		interface.Create(cashSlotData, interface.inventoryGrid, true)

	Loader.Message("Sold " + furnitureName + " (+" + str(price) + ")", Color.GREEN)
	fsSellButton.hide()
	interface.HideContext()
	interface.PlayClick()
	interface.Reset()
