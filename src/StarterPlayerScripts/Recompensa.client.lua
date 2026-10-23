-- Interfaz de la recompensa diaria: boton "Regalo" y un panel con los 7 dias de la racha.
-- Se abre solo al entrar si hay un regalo para reclamar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConfigRecompensa = require(ReplicatedStorage:WaitForChild("ConfigRecompensa"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local reclamar = ReplicatedStorage:WaitForChild("ReclamarRecompensa")

local jugador = Players.LocalPlayer

local COLOR_HECHO = Color3.fromRGB(0, 150, 80)
local COLOR_HOY = Color3.fromRGB(255, 190, 0)
local COLOR_PENDIENTE = Color3.fromRGB(70, 70, 70)

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "RecompensaDiaria"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local function redondear(objeto, radio)
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, radio)
	esquinas.Parent = objeto
end

local function nuevoTexto(padre, tamano, fuente, color)
	local texto = Instance.new("TextLabel")
	texto.BackgroundTransparency = 1
	texto.Font = fuente
	texto.TextSize = tamano
	texto.TextColor3 = color
	texto.Parent = padre
	return texto
end

-- Boton debajo del de la tienda
local botonRegalo = Instance.new("TextButton")
botonRegalo.Size = UDim2.fromOffset(120, 46)
botonRegalo.Font = Enum.Font.GothamBold
botonRegalo.TextSize = 20
botonRegalo.TextColor3 = Color3.new(1, 1, 1)
botonRegalo.Parent = pantalla
redondear(botonRegalo, 10)
Interfaz.botonLateral(botonRegalo, "izquierda", 2, 4)

-- Panel
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(460, 290)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.Visible = false
panel.Parent = pantalla
redondear(panel, 14)
Interfaz.panel(panel, 460, 290)

local titulo = nuevoTexto(panel, 26, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 0))
titulo.Size = UDim2.new(1, 0, 0, 50)
titulo.Text = "Recompensa diaria"

local info = nuevoTexto(panel, 16, Enum.Font.Gotham, Color3.new(1, 1, 1))
info.Position = UDim2.fromOffset(0, 48)
info.Size = UDim2.new(1, 0, 0, 24)

-- Un casillero por dia del ciclo
local casilleros = {}
local ancho = 56
local separacion = 6
local inicio = (460 - (ConfigRecompensa.DIAS_CICLO * ancho + (ConfigRecompensa.DIAS_CICLO - 1) * separacion)) / 2

for dia = 1, ConfigRecompensa.DIAS_CICLO do
	local caja = Instance.new("Frame")
	caja.Position = UDim2.fromOffset(inicio + (dia - 1) * (ancho + separacion), 88)
	caja.Size = UDim2.fromOffset(ancho, 90)
	caja.Parent = panel
	redondear(caja, 8)

	local etiquetaDia = nuevoTexto(caja, 14, Enum.Font.GothamBold, Color3.new(1, 1, 1))
	etiquetaDia.Position = UDim2.fromOffset(0, 8)
	etiquetaDia.Size = UDim2.new(1, 0, 0, 20)
	etiquetaDia.Text = "Día " .. dia

	local etiquetaPremio = nuevoTexto(caja, 18, Enum.Font.GothamBold, Color3.new(1, 1, 1))
	etiquetaPremio.Position = UDim2.fromOffset(0, 40)
	etiquetaPremio.Size = UDim2.new(1, 0, 0, 30)
	etiquetaPremio.Text = "+" .. ConfigRecompensa.premio(dia)

	casilleros[dia] = caja
end

local botonReclamar = Instance.new("TextButton")
botonReclamar.AnchorPoint = Vector2.new(0.5, 0)
botonReclamar.Position = UDim2.new(0.5, 0, 0, 196)
botonReclamar.Size = UDim2.fromOffset(200, 44)
botonReclamar.Font = Enum.Font.GothamBold
botonReclamar.TextSize = 20
botonReclamar.TextColor3 = Color3.new(1, 1, 1)
botonReclamar.Parent = panel
redondear(botonReclamar, 10)

local mensaje = nuevoTexto(panel, 16, Enum.Font.Gotham, Color3.new(1, 1, 1))
mensaje.AnchorPoint = Vector2.new(0, 1)
mensaje.Position = UDim2.new(0, 0, 1, -8)
mensaje.Size = UDim2.new(1, 0, 0, 24)

-- Estado actual calculado con los atributos que guarda el servidor
local function estado()
	local hoy = ConfigRecompensa.dia(Workspace:GetServerTimeNow())
	local ultimoDia = jugador:GetAttribute("UltimoDia") or 0
	local racha = jugador:GetAttribute("Racha") or 0
	local listo = jugador:GetAttribute("DatosCargados") == true

	local disponible = listo and ultimoDia ~= hoy
	-- Si reclamara ahora: la racha sigue si reclamo ayer, si no vuelve a 1
	local rachaProyectada = racha
	if disponible then
		rachaProyectada = (ultimoDia == hoy - 1) and racha + 1 or 1
	end
	return hoy, listo, disponible, rachaProyectada
end

local function formatoTiempo(segundos)
	segundos = math.max(0, math.floor(segundos))
	return string.format("%02d:%02d:%02d", segundos // 3600, (segundos % 3600) // 60, segundos % 60)
end

local function actualizar()
	local hoy, listo, disponible, rachaProyectada = estado()
	local posicion = rachaProyectada > 0 and ConfigRecompensa.posicion(rachaProyectada) or 0

	for dia, caja in casilleros do
		if disponible then
			caja.BackgroundColor3 = (dia < posicion and COLOR_HECHO) or (dia == posicion and COLOR_HOY) or COLOR_PENDIENTE
		else
			caja.BackgroundColor3 = (dia <= posicion and COLOR_HECHO) or COLOR_PENDIENTE
		end
	end

	if not listo then
		info.Text = "Cargando..."
		botonReclamar.Text = "Cargando..."
		botonReclamar.BackgroundColor3 = COLOR_PENDIENTE
		botonRegalo.Text = "Regalo"
		botonRegalo.BackgroundColor3 = COLOR_PENDIENTE
	elseif disponible then
		info.Text = string.format("Racha: %d día(s). ¡Tu regalo de hoy está listo!", rachaProyectada - 1)
		botonReclamar.Text = "Reclamar +" .. ConfigRecompensa.premio(rachaProyectada)
		botonReclamar.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
		botonRegalo.Text = "¡Regalo!"
		botonRegalo.BackgroundColor3 = COLOR_HOY
	else
		local faltan = (hoy + 1) * 86400 - Workspace:GetServerTimeNow()
		info.Text = string.format("Racha: %d día(s). Próximo regalo en %s", rachaProyectada, formatoTiempo(faltan))
		botonReclamar.Text = "Volvé mañana"
		botonReclamar.BackgroundColor3 = COLOR_PENDIENTE
		botonRegalo.Text = "Regalo"
		botonRegalo.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
	end
end

botonRegalo.Activated:Connect(function()
	Interfaz.alternar(panel)
	mensaje.Text = ""
	actualizar()
end)

botonReclamar.Activated:Connect(function()
	local ok, texto = reclamar:InvokeServer()
	mensaje.Text = texto or ""
	mensaje.TextColor3 = ok and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(255, 100, 100)
	actualizar()
end)

jugador:GetAttributeChangedSignal("UltimoDia"):Connect(actualizar)
jugador:GetAttributeChangedSignal("Racha"):Connect(actualizar)

-- Cuando terminan de cargar los datos, abrimos el panel si hay regalo
local function alCargar()
	actualizar()
	local _, _, disponible = estado()
	if disponible then
		Interfaz.cerrarPaneles(panel)
		panel.Visible = true
	end
end

if jugador:GetAttribute("DatosCargados") then
	alCargar()
else
	jugador:GetAttributeChangedSignal("DatosCargados"):Connect(alCargar)
	actualizar()
end

-- Refresca la cuenta regresiva cada segundo mientras el panel esta abierto
task.spawn(function()
	while true do
		task.wait(1)
		if panel.Visible then
			actualizar()
		end
	end
end)
