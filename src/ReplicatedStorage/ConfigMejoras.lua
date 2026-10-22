-- Lista de mejoras de la tienda. La usan el servidor (para validar y aplicar)
-- y el cliente (para dibujar la tienda). Agregar una mejora nueva = agregar una fila.

local ConfigMejoras = {}

ConfigMejoras.Lista = {
	{
		id = "Velocidad",
		nombre = "Velocidad",
		descripcion = "+2 de velocidad al caminar",
		costoBase = 20,
		nivelMaximo = 5,
	},
	{
		id = "Salto",
		nombre = "Salto",
		descripcion = "+5 de fuerza de salto",
		costoBase = 30,
		nivelMaximo = 5,
	},
	{
		id = "Multiplicador",
		nombre = "Monedas extra",
		descripcion = "+1 punto por cada moneda",
		costoBase = 50,
		nivelMaximo = 3,
	},
}

ConfigMejoras.VELOCIDAD_BASE = 16
ConfigMejoras.VELOCIDAD_POR_NIVEL = 2
ConfigMejoras.SALTO_BASE = 50
ConfigMejoras.SALTO_POR_NIVEL = 5

-- El costo sube con cada nivel: costoBase * (nivel actual + 1)
function ConfigMejoras.costo(mejora, nivelActual)
	return mejora.costoBase * (nivelActual + 1)
end

return ConfigMejoras
