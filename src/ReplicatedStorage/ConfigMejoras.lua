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
	{
		id = "Iman",
		nombre = "Imán",
		descripcion = "+8 de radio para atraer monedas",
		costoBase = 40,
		nivelMaximo = 5,
	},
	{
		id = "Suerte",
		nombre = "Suerte",
		descripcion = "+8% de chance de que una moneda valga el doble",
		costoBase = 60,
		nivelMaximo = 5,
	},
	{
		id = "SaltoDoble",
		nombre = "Salto extra",
		descripcion = "+1 salto en el aire (apretá saltar de nuevo)",
		costoBase = 100,
		nivelMaximo = 2,
	},
}

ConfigMejoras.SUERTE_POR_NIVEL = 0.08 -- probabilidad de "moneda doble" por nivel

ConfigMejoras.IMAN_RADIO_POR_NIVEL = 8 -- studs
ConfigMejoras.IMAN_VELOCIDAD = 30 -- studs por segundo con que viaja la moneda
ConfigMejoras.VELOCIDAD_BASE = 16
ConfigMejoras.VELOCIDAD_POR_NIVEL = 2
ConfigMejoras.SALTO_BASE = 50
ConfigMejoras.SALTO_POR_NIVEL = 5

-- El costo sube con cada nivel: costoBase * (nivel actual + 1)
function ConfigMejoras.costo(mejora, nivelActual)
	return mejora.costoBase * (nivelActual + 1)
end

return ConfigMejoras
