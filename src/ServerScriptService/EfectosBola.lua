-- Le pone a una pelota de golf el estilo que eligio el jugador (ConfigGolf.Pelotas):
-- color, material, luz, fuego y estela. Lo usa Golf.server.lua al crear cada pelota.

local EfectosBola = {}

local VUELTA_ARCOIRIS = 3 -- segundos que tarda en dar la vuelta a todos los colores

function EfectosBola.aplicar(bola, estilo)
	bola.Color = estilo.color
	bola.Material = estilo.material or Enum.Material.SmoothPlastic

	if estilo.luz then
		local luz = Instance.new("PointLight")
		luz.Name = "Luz"
		luz.Color = estilo.luz.color
		luz.Brightness = estilo.luz.brillo
		luz.Range = estilo.luz.rango
		luz.Shadows = false
		luz.Parent = bola
	end

	if estilo.fuego then
		local fuego = Instance.new("Fire")
		fuego.Name = "Fuego"
		fuego.Color = estilo.fuego.color
		fuego.SecondaryColor = estilo.fuego.secundario
		fuego.Size = 3
		fuego.Heat = 0
		fuego.Parent = bola
	end

	if estilo.estela then
		local arriba = Instance.new("Attachment")
		arriba.Name = "EstelaArriba"
		arriba.Position = Vector3.new(0, 0.5, 0)
		arriba.Parent = bola
		local abajo = Instance.new("Attachment")
		abajo.Name = "EstelaAbajo"
		abajo.Position = Vector3.new(0, -0.5, 0)
		abajo.Parent = bola

		local estela = Instance.new("Trail")
		estela.Name = "Estela"
		estela.Attachment0 = arriba
		estela.Attachment1 = abajo
		estela.Lifetime = 0.6
		estela.LightEmission = 1
		estela.Color = ColorSequence.new(estilo.estela)
		estela.Transparency = NumberSequence.new(0.1, 1)
		estela.Parent = bola
	end
end

-- Para el estilo arcoiris: llamar cada cuadro. Los demas estilos no hacen nada.
function EfectosBola.animar(bola, estilo)
	if not estilo.arcoiris then
		return
	end
	local color = Color3.fromHSV((os.clock() / VUELTA_ARCOIRIS) % 1, 0.85, 1)
	bola.Color = color
	local luz = bola:FindFirstChild("Luz")
	if luz then
		luz.Color = color
	end
	local estela = bola:FindFirstChild("Estela")
	if estela then
		estela.Color = ColorSequence.new(color)
	end
end

return EfectosBola
