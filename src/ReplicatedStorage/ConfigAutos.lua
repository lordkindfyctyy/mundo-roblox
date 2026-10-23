-- Tienda de autos (el taller del estacionamiento): pinturas, rayas, ruedas y el
-- motor deportivo. Lo comprado queda guardado y se elige que tener puesto; cuando
-- el jugador maneja un auto de Vehiculos.server.lua, el auto toma su estilo.
-- Agregar algo = agregar una fila.
--
-- categoria: "color", "rayas", "ruedas" o "motor". Se puede tener puesta una cosa
-- por categoria.

local ConfigAutos = {}

ConfigAutos.Categorias = {
	{ id = "color", nombre = "Pintura" },
	{ id = "rayas", nombre = "Rayas" },
	{ id = "ruedas", nombre = "Ruedas" },
	{ id = "motor", nombre = "Motor" },
}

ConfigAutos.Lista = {
	{ id = "Rojo", categoria = "color", nombre = "Pintura roja", precio = 300, color = Color3.fromRGB(220, 40, 40) },
	{ id = "Verde", categoria = "color", nombre = "Pintura verde", precio = 300, color = Color3.fromRGB(40, 170, 80) },
	{ id = "Negro", categoria = "color", nombre = "Pintura negra", precio = 400, color = Color3.fromRGB(25, 25, 30) },
	{ id = "Rosa", categoria = "color", nombre = "Pintura rosa", precio = 400, color = Color3.fromRGB(255, 120, 180) },
	{ id = "Dorado", categoria = "color", nombre = "Pintura dorada", precio = 2000, color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Foil },
	{ id = "RayasBlancas", categoria = "rayas", nombre = "Rayas blancas", precio = 500, color = Color3.fromRGB(250, 250, 250) },
	{ id = "RayasCarrera", categoria = "rayas", nombre = "Rayas de carrera", precio = 500, color = Color3.fromRGB(20, 20, 20) },
	{ id = "RayasFuego", categoria = "rayas", nombre = "Rayas de fuego", precio = 800, color = Color3.fromRGB(255, 120, 0), material = Enum.Material.Neon },
	{ id = "RuedasDoradas", categoria = "ruedas", nombre = "Ruedas doradas", precio = 800, color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Foil },
	{ id = "RuedasNeon", categoria = "ruedas", nombre = "Ruedas de neón", precio = 1200, color = Color3.fromRGB(0, 230, 255), material = Enum.Material.Neon },
	{ id = "Deportivo", categoria = "motor", nombre = "Motor deportivo", precio = 5000, velocidad = 62, aceleracion = 34 },
}

-- Atributo del jugador donde queda lo que tiene puesto en cada categoria ("" = nada)
ConfigAutos.ATRIBUTO = {
	color = "AutoColor",
	rayas = "AutoRayas",
	ruedas = "AutoRuedas",
	motor = "AutoMotor",
}

local porId = {}
for _, cosa in ConfigAutos.Lista do
	porId[cosa.id] = cosa
end

function ConfigAutos.buscar(id)
	return porId[id]
end

-- Lo que el jugador tiene puesto en una categoria (o nil)
function ConfigAutos.puesto(jugador, categoria)
	local id = jugador:GetAttribute(ConfigAutos.ATRIBUTO[categoria])
	return id and porId[id] or nil
end

return ConfigAutos
