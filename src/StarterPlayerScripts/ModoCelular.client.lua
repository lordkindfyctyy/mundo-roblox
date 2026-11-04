-- Gráficos livianos para celulares y tablets (dispositivos sin teclado). En una compu no se toca nada.
-- Todo es solo en ese cliente: los demás jugadores y el servidor no se enteran.
--
-- Por qué: se midió en un Moto G06 (gama baja, 3,8 GB de RAM) con el juego publicado. Andaba a ~30-38 FPS con
-- tirones, y el cuello de botella era DIBUJAR la escena: un hilo de Roblox al 84% mientras el de los scripts
-- estaba al 35%. El mundo tiene ~8.200 partes (el 97% proyecta sombra), 129 luces, 33 emisores de partículas y
-- 3 efectos de pantalla caros (profundidad de campo, bloom y rayos de sol).
--
-- Qué se apaga (cada cosa se puede desactivar en OPCIONES):
--   * sombras globales y efectos de pantalla (profundidad de campo, bloom, rayos de sol)
--   * los focos (faros de los autos) y las luces de los huevos
--   * la mitad de las partículas
-- La atmósfera se deja: da algo de niebla y ayuda a disimular que el mundo se carga por streaming.
-- La tecnología de iluminación y el radio de streaming están en default.project.json.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local OPCIONES = {
	SOMBRAS = true,
	EFECTOS = true,
	LUCES = true,
	PARTICULAS = 0.5, -- que parte de las partículas queda (1 = todas); nil = no tocarlas
}

-- Celular o tablet: sin teclado. ForzarCelular (un BoolValue en ReplicatedStorage) sirve para probar esto en Studio.
local esCelular = not UserInputService.KeyboardEnabled or ReplicatedStorage:FindFirstChild("ForzarCelular") ~= nil
if not esCelular then
	return
end

if OPCIONES.SOMBRAS then
	Lighting.GlobalShadows = false
end

local function aliviarEfecto(objeto)
	if objeto:IsA("DepthOfFieldEffect") or objeto:IsA("BloomEffect") or objeto:IsA("SunRaysEffect") then
		objeto.Enabled = false
	end
end

if OPCIONES.EFECTOS then
	for _, objeto in Lighting:GetChildren() do
		aliviarEfecto(objeto)
	end
	Lighting.ChildAdded:Connect(aliviarEfecto)
end

-- Luces y partículas del mundo, incluidas las que llegan despues por el streaming
local function dentroDe(objeto, nombre)
	return objeto:FindFirstAncestor(nombre) ~= nil
end

local function aliviar(objeto)
	if OPCIONES.LUCES and objeto:IsA("Light") then
		-- los focos son los faros de los autos; las luces de los huevos solo son un adorno. Las farolas se dejan.
		if objeto:IsA("SpotLight") or dentroDe(objeto, "Huevos") then
			objeto:Destroy()
		end
	elseif OPCIONES.PARTICULAS and objeto:IsA("ParticleEmitter") and objeto:GetAttribute("AliviadoCelular") == nil then
		objeto:SetAttribute("AliviadoCelular", true)
		objeto.Rate = objeto.Rate * OPCIONES.PARTICULAS
	end
end

Workspace.DescendantAdded:Connect(aliviar)
for _, objeto in Workspace:GetDescendants() do
	aliviar(objeto)
end
