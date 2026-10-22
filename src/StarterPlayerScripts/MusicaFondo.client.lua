-- Musica de fondo: una lista de temas que suenan en orden al azar, sin parar.
-- Es local de cada jugador: el boton "Musica" silencia solo la tuya.
-- Los IDs son de musica publica de Roblox (Toolbox). Si alguno no carga, se salta al siguiente.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local jugador = Players.LocalPlayer

local VOLUMEN = 0.25 -- bajo, para que no tape los sonidos de las monedas
local ESPERA_CARGA = 10 -- segundos que esperamos a que cargue un tema

local TEMAS = {
	"rbxassetid://93310229093873", -- Green Hill Cubes BGM
	"rbxassetid://84770156902104", -- Mining Fun BGM
	"rbxassetid://127582244484162", -- Sunny Mine Day BGM
	"rbxassetid://133524990908447", -- Craftland Cheerful Vibes
	"rbxassetid://130967646669894", -- Cheerful Pets Background Mood
}

local musica = Instance.new("Sound")
musica.Name = "MusicaFondo"
musica.Volume = VOLUMEN
musica.Looped = false
musica.Parent = SoundService

local activa = true

-- Boton para silenciar, arriba del de la tienda
local pantalla = Instance.new("ScreenGui")
pantalla.Name = "MusicaFondo"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local boton = Instance.new("TextButton")
boton.AnchorPoint = Vector2.new(0, 0.5)
boton.Position = UDim2.new(0, 20, 0.5, -56)
boton.Size = UDim2.fromOffset(120, 46)
boton.Font = Enum.Font.GothamBold
boton.TextSize = 18
boton.TextColor3 = Color3.new(1, 1, 1)
boton.Parent = pantalla

local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0, 10)
esquinas.Parent = boton

local function actualizarBoton()
	if activa then
		boton.Text = "Música: ON"
		boton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
	else
		boton.Text = "Música: OFF"
		boton.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
	end
	-- Silenciamos con el volumen y no con Stop, asi el tema sigue avanzando
	musica.Volume = activa and VOLUMEN or 0
end

boton.Activated:Connect(function()
	activa = not activa
	actualizarBoton()
end)
actualizarBoton()

-- Mezcla la lista; el primero nunca es el ultimo que sono, para que no se repita seguido
local function mezclar(ultimo)
	local lista = table.clone(TEMAS)
	for i = #lista, 2, -1 do
		local j = math.random(i)
		lista[i], lista[j] = lista[j], lista[i]
	end
	if lista[1] == ultimo and #lista > 1 then
		lista[1], lista[#lista] = lista[#lista], lista[1]
	end
	return lista
end

local ultimo
while true do
	for _, tema in mezclar(ultimo) do
		musica.SoundId = tema
		musica:Play()

		local inicio = os.clock()
		while not musica.IsLoaded and os.clock() - inicio < ESPERA_CARGA do
			task.wait(0.25)
		end

		if musica.IsLoaded then
			musica.Ended:Wait()
		else
			warn("No cargó el tema de fondo, paso al siguiente:", tema)
			musica:Stop()
		end
		ultimo = tema
	end
end
