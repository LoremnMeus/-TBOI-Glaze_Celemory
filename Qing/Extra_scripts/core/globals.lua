local Globals = {}

Globals.ZeroV = Vector.Zero
Globals.CenterV = Vector(320, 280)
Globals.CenterVBig = Vector(640, 560)

Globals.game = Game()
Globals.sound = SFXManager()
Globals.Randomizer = RNG()
Globals.Randomizer:SetSeed(Random() + 1, 35)
Globals.ItemConfig = Isaac.GetItemConfig()
Globals.ItemPool = Globals.game:GetItemPool()
Globals.HUD = Globals.game:GetHUD()

Globals.TempestaFont = Font()
--Globals.TempestaFont:Load("font/pftempestasevencondensed.fnt")

return Globals
