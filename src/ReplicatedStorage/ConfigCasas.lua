-- Casas del Barrio (al oeste de la ciudad): precio de la casa y muebles para decorarla.
-- Cada mueble tiene su lugar fijo en la casa; al comprarlo aparece ahi.
-- Agregar un mueble = agregar una fila (y su forma en Casas.server.lua).
--
-- Del jugador (los guarda GuardadoMonedas.server.lua):
--   TieneCasa (bool) y Muebles (ids comprados separados por coma).

local ConfigCasas = {}

ConfigCasas.PRECIO_CASA = 3000

ConfigCasas.Muebles = {
	{ id = "Alfombra", nombre = "Alfombra", precio = 150 },
	{ id = "Planta", nombre = "Planta", precio = 150 },
	{ id = "Lampara", nombre = "Lámpara", precio = 200 },
	{ id = "Mesa", nombre = "Mesa con sillas", precio = 250 },
	{ id = "Sillon", nombre = "Sillón", precio = 300 },
	{ id = "Cucha", nombre = "Cucha para la mascota", precio = 350 },
	{ id = "Cama", nombre = "Cama", precio = 400 },
	{ id = "TV", nombre = "Televisor", precio = 600 },
}

local porId = {}
for _, mueble in ConfigCasas.Muebles do
	porId[mueble.id] = mueble
end

function ConfigCasas.buscar(id)
	return porId[id]
end

-- Los muebles que tiene un jugador, como conjunto { [id] = true }
function ConfigCasas.muebles(jugador)
	local tengo = {}
	for id in string.gmatch(jugador:GetAttribute("Muebles") or "", "[^,]+") do
		tengo[id] = true
	end
	return tengo
end

return ConfigCasas
