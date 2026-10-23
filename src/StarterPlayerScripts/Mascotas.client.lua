-- Interfaz de mascotas: abrir huevos, ver la coleccion y equipar hasta 3.
-- El boton esta del lado derecho para no seguir apilando botones a la izquierda.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigMascotas = require(ReplicatedStorage:WaitForChild("ConfigMascotas"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local abrirHuevo = ReplicatedStorage:WaitForChild("AbrirHuevo")
local equipar = ReplicatedStorage:WaitForChild("EquiparMascota")

local jugador = Players.LocalPlayer
local monedas = jugador:WaitForChild("leaderstats"):WaitForChild("Monedas")
local tengo = jugador:WaitForChild("Mascotas")
local equipadas = jugador:WaitForChild("MascotasEquipadas")

local COLOR_VERDE = Color3.fromRGB(0, 170, 80)
local COLOR_NARANJA = Color3.fromRGB(220, 120, 0)
local COLOR_GRIS = Color3.fromRGB(90, 90, 90)

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Mascotas"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local function redondear(objeto, radio)
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, radio)
	esquinas.Parent = objeto
end

local function nuevoTexto(padre, tamano, fuente, color, alineacion)
	local texto = Instance.new("TextLabel")
	texto.BackgroundTransparency = 1
	texto.Font = fuente
	texto.TextSize = tamano
	texto.TextColor3 = color
	texto.TextXAlignment = alineacion or Enum.TextXAlignment.Center
	texto.Parent = padre
	return texto
end

local function nuevoBoton(padre, tamano)
	local boton = Instance.new("TextButton")
	boton.Font = Enum.Font.GothamBold
	boton.TextSize = tamano
	boton.TextColor3 = Color3.new(1, 1, 1)
	boton.Parent = padre
	redondear(boton, 8)
	return boton
end

-- Boton para abrir el panel, a la derecha de la pantalla
local botonAbrir = nuevoBoton(pantalla, 20)
botonAbrir.Size = UDim2.fromOffset(120, 46)
botonAbrir.BackgroundColor3 = Color3.fromRGB(230, 110, 150)
botonAbrir.Text = "Mascotas"
Interfaz.botonLateral(botonAbrir, "derecha", 0, 2)

-- Panel
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(460, 500)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.Visible = false
panel.Parent = pantalla
redondear(panel, 14)
Interfaz.panel(panel, 460, 500)

local titulo = nuevoTexto(panel, 26, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 0))
titulo.Size = UDim2.new(1, 0, 0, 44)
titulo.Text = "Mascotas"

-- Un boton por huevo, uno al lado del otro
local botonesHuevo = {}
local anchoBoton = (420 - 10 * (#ConfigMascotas.Huevos - 1)) / #ConfigMascotas.Huevos
for i, huevo in ConfigMascotas.Huevos do
	local boton = nuevoBoton(panel, 15)
	boton.Position = UDim2.fromOffset(20 + (i - 1) * (anchoBoton + 10), 48)
	boton.Size = UDim2.fromOffset(anchoBoton, 44)
	botonesHuevo[huevo.id] = boton
end

local resultado = nuevoTexto(panel, 16, Enum.Font.GothamBold, Color3.new(1, 1, 1))
resultado.Position = UDim2.fromOffset(10, 96)
resultado.Size = UDim2.new(1, -20, 0, 26)

local resumen = nuevoTexto(panel, 15, Enum.Font.Gotham, Color3.fromRGB(210, 210, 210))
resumen.Position = UDim2.fromOffset(0, 124)
resumen.Size = UDim2.new(1, 0, 0, 22)

local lista = Instance.new("ScrollingFrame")
lista.Position = UDim2.fromOffset(0, 154)
lista.Size = UDim2.new(1, 0, 1, -164)
lista.BackgroundTransparency = 1
lista.BorderSizePixel = 0
lista.ScrollBarThickness = 6
lista.CanvasSize = UDim2.fromOffset(0, #ConfigMascotas.Lista * 64)
lista.Parent = panel

-- Una fila por mascota
local filas = {}

for i, mascota in ConfigMascotas.Lista do
	local rareza = ConfigMascotas.Rarezas[mascota.rareza]

	local marco = Instance.new("Frame")
	marco.Position = UDim2.fromOffset(15, (i - 1) * 64)
	marco.Size = UDim2.new(1, -36, 0, 56)
	marco.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	marco.Parent = lista
	redondear(marco, 10)

	local muestra = Instance.new("Frame")
	muestra.Position = UDim2.fromOffset(10, 10)
	muestra.Size = UDim2.fromOffset(36, 36)
	muestra.BackgroundColor3 = mascota.color
	muestra.Parent = marco
	redondear(muestra, 18)

	local nombre = nuevoTexto(marco, 16, Enum.Font.GothamBold, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)
	nombre.Position = UDim2.fromOffset(56, 6)
	nombre.Size = UDim2.new(0.5, 0, 0, 22)
	nombre.Text = mascota.nombre

	local detalle = nuevoTexto(marco, 13, Enum.Font.Gotham, rareza.color, Enum.TextXAlignment.Left)
	detalle.Position = UDim2.fromOffset(56, 29)
	detalle.Size = UDim2.new(0.55, 0, 0, 20)

	local boton = nuevoBoton(marco, 15)
	boton.AnchorPoint = Vector2.new(1, 0.5)
	boton.Position = UDim2.new(1, -10, 0.5, 0)
	boton.Size = UDim2.fromOffset(96, 36)

	filas[mascota.id] = { marco = marco, muestra = muestra, nombre = nombre, detalle = detalle, boton = boton }

	boton.Activated:Connect(function()
		if not tengo:FindFirstChild(mascota.id) then
			return
		end
		local quiere = equipadas:FindFirstChild(mascota.id) == nil
		local ok, texto = equipar:InvokeServer(mascota.id, quiere)
		if not ok then
			resultado.Text = texto
			resultado.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end)
end

local function actualizar()
	local cantidadEquipadas = #equipadas:GetChildren()

	for _, mascota in ConfigMascotas.Lista do
		local fila = filas[mascota.id]
		local esMia = tengo:FindFirstChild(mascota.id) ~= nil
		local puesta = equipadas:FindFirstChild(mascota.id) ~= nil

		fila.nombre.TextTransparency = esMia and 0 or 0.5
		fila.muestra.BackgroundTransparency = esMia and 0 or 0.7

		-- Rareza, nivel y bonus (en el nivel que la tenes, o el del nivel 1 si no la tenes)
		local nivel = esMia and ConfigMascotas.nivel(jugador, mascota.id) or 1
		local bonus = math.floor(ConfigMascotas.bonusEnNivel(mascota, nivel) * 100 + 0.5)
		local rareza = ConfigMascotas.Rarezas[mascota.rareza].nombre
		if esMia then
			fila.detalle.Text = string.format("%s · Nv %d/%d · +%d%%", rareza, nivel, ConfigMascotas.NIVEL_MAXIMO, bonus)
		else
			local soloDorado = mascota.pesos.Comun == nil
			fila.detalle.Text = string.format("%s · +%d%%%s", rareza, bonus, soloDorado and " · huevo dorado" or "")
		end

		if not esMia then
			fila.boton.Text = "Bloqueada"
			fila.boton.BackgroundColor3 = COLOR_GRIS
		elseif puesta then
			fila.boton.Text = "Quitar"
			fila.boton.BackgroundColor3 = COLOR_NARANJA
		else
			fila.boton.Text = "Equipar"
			fila.boton.BackgroundColor3 = COLOR_VERDE
		end
	end

	local bonus = math.floor((ConfigMascotas.multiplicador(jugador) - 1) * 100 + 0.5)
	resumen.Text = string.format(
		"Tenés %d/%d · Equipadas: %d/%d · Bonus: +%d%%",
		#tengo:GetChildren(),
		#ConfigMascotas.Lista,
		cantidadEquipadas,
		ConfigMascotas.MAX_EQUIPADAS,
		bonus
	)

	for _, huevo in ConfigMascotas.Huevos do
		local boton = botonesHuevo[huevo.id]
		boton.Text = string.format("%s · %d", huevo.nombre, huevo.costo)
		boton.BackgroundColor3 = monedas.Value >= huevo.costo and huevo.color or COLOR_GRIS
	end
end

for _, huevo in ConfigMascotas.Huevos do
	botonesHuevo[huevo.id].Activated:Connect(function()
		local ok, texto, id = abrirHuevo:InvokeServer(huevo.id)
		resultado.Text = texto or ""
		local mascota = id and ConfigMascotas.buscar(id)
		if ok and mascota then
			resultado.TextColor3 = ConfigMascotas.Rarezas[mascota.rareza].color
		else
			resultado.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
		actualizar() -- el nivel puede haber subido
	end)
end

botonAbrir.Activated:Connect(function()
	Interfaz.alternar(panel)
	resultado.Text = ""
	actualizar()
end)

monedas.Changed:Connect(actualizar)
tengo.ChildAdded:Connect(actualizar)
tengo.ChildRemoved:Connect(actualizar)
equipadas.ChildAdded:Connect(actualizar)
equipadas.ChildRemoved:Connect(actualizar)
actualizar()
