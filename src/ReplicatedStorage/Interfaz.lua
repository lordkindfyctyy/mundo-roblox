-- Ayudas para que la interfaz se vea bien en compu y en celular:
-- todo se achica en pantallas chicas, en el celular los botones laterales
-- suben para no tapar el joystick ni el boton de saltar, y solo queda un
-- panel abierto a la vez (cada uno con su boton para cerrar).

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Interfaz = {}

local ALTO_BASE = 620 -- alto de pantalla en el que la interfaz se ve a tamaño real
local ANCHO_BASE = 1000
local ESCALA_MINIMA = 0.55
local SEPARACION_BOTONES = 56 -- distancia entre botones laterales (alto 46 + 10)

-- Celulares y tablets: pantalla tactil sin teclado
function Interfaz.esTactil()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function tamanoPantalla()
	return Workspace.CurrentCamera.ViewportSize
end

-- 1 en una compu; menos en pantallas chicas
function Interfaz.escala()
	local vista = tamanoPantalla()
	local escala = math.min(vista.Y / ALTO_BASE, vista.X / ANCHO_BASE, 1)
	return math.max(escala, ESCALA_MINIMA)
end

-- Llama a funcion ahora y cada vez que cambia el tamaño de la pantalla
-- (girar el celular, agrandar la ventana)
function Interfaz.alCambiarPantalla(funcion)
	local conexion
	local function conectar()
		if conexion then
			conexion:Disconnect()
		end
		conexion = Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(funcion)
		funcion()
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(conectar)
	conectar()
end

-- El objeto (y todo lo que tiene adentro) se achica con la pantalla
function Interfaz.escalar(objeto)
	local escala = Instance.new("UIScale")
	escala.Parent = objeto
	Interfaz.alCambiarPantalla(function()
		escala.Scale = Interfaz.escala()
	end)
	return escala
end

-- Ubica un boton del costado. lugar: 0, 1, 2... de arriba hacia abajo.
-- En la compu quedan a media altura, como siempre; en el celular, arriba,
-- lejos del joystick (abajo a la izquierda) y del salto (abajo a la derecha).
function Interfaz.botonLateral(boton, lado, lugar, total)
	local derecha = lado == "derecha"
	Interfaz.escalar(boton)
	Interfaz.alCambiarPantalla(function()
		local escala = Interfaz.escala()
		local x = derecha and UDim.new(1, -12) or UDim.new(0, 12)
		if Interfaz.esTactil() then
			boton.AnchorPoint = Vector2.new(derecha and 1 or 0, 0)
			boton.Position = UDim2.new(x, UDim.new(0, 10 + lugar * SEPARACION_BOTONES * escala))
		else
			-- La columna queda centrada en la mitad de la pantalla
			local desdeElMedio = (lugar - (total - 1) / 2) * SEPARACION_BOTONES
			boton.AnchorPoint = Vector2.new(derecha and 1 or 0, 0.5)
			boton.Position = UDim2.new(derecha and 1 or 0, derecha and -20 or 20, 0.5, desdeElMedio * escala)
		end
	end)
end

-- Paneles: se achican para entrar en la pantalla y solo uno abierto a la vez
local paneles = {}

function Interfaz.cerrarPaneles(menos)
	for _, panel in paneles do
		if panel ~= menos then
			panel.Visible = false
		end
	end
end

-- Abre el panel (cerrando los demas) o lo cierra si ya estaba abierto.
-- Devuelve si quedo abierto.
function Interfaz.alternar(panel)
	local abrir = not panel.Visible
	Interfaz.cerrarPaneles(panel)
	panel.Visible = abrir
	return abrir
end

-- Prepara un panel centrado de ancho x alto: escala para que entre entero,
-- registro para que se cierren entre si y una X arriba a la derecha.
function Interfaz.panel(panel, ancho, alto)
	table.insert(paneles, panel)

	local escala = Instance.new("UIScale")
	escala.Parent = panel
	Interfaz.alCambiarPantalla(function()
		local vista = tamanoPantalla()
		escala.Scale = math.min(Interfaz.escala(), (vista.Y - 60) / alto, (vista.X - 20) / ancho)
	end)

	local cerrar = Instance.new("TextButton")
	cerrar.Name = "Cerrar"
	cerrar.AnchorPoint = Vector2.new(1, 0)
	cerrar.Position = UDim2.new(1, -8, 0, 8)
	cerrar.Size = UDim2.fromOffset(38, 38)
	cerrar.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	cerrar.Font = Enum.Font.GothamBold
	cerrar.TextSize = 22
	cerrar.TextColor3 = Color3.new(1, 1, 1)
	cerrar.Text = "X"
	cerrar.ZIndex = 5
	cerrar.Parent = panel
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, 8)
	esquinas.Parent = cerrar

	cerrar.Activated:Connect(function()
		panel.Visible = false
	end)
	return cerrar
end

return Interfaz
