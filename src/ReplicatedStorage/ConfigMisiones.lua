-- Misiones de la ciudad. Cada jugador tiene una activa; al cumplirla cobra el
-- premio y le toca otra al azar. Agregar una mision = agregar una fila.
--
-- tipos:
--   entrega: ir a buscar algo a "desde" y llevarlo a "hasta" (lugares: el nombre
--     de un negocio de Ciudad.server.lua, "Torre" o "Parque")
--   monedasCiudad: juntar "meta" monedas en las calles
--   cima: llegar a la cima de la Torre
--   manejar: recorrer "meta" studs (metros) manejando un auto
--   alimento: comprar alimento en Lo De Lalo Pet Shop

local ConfigMisiones = {}

ConfigMisiones.ESPERA_PROXIMA = 3 -- segundos entre una mision cumplida y la siguiente
ConfigMisiones.ESPERA_CAMBIAR = 10 -- segundos minimos entre dos "Cambiar"
ConfigMisiones.DISTANCIA_LLEGADA = 10 -- a esta distancia de un lugar ya se cuenta que llegaste

ConfigMisiones.Lista = {
	{
		id = "Pizza",
		tipo = "entrega",
		desde = "Pizzería",
		hasta = "Parque",
		buscar = "Buscá la pizza en la Pizzería",
		llevar = "Llevá la pizza al parque",
		premio = 200,
	},
	{
		id = "Helado",
		tipo = "entrega",
		desde = "Heladería",
		hasta = "Torre",
		buscar = "Buscá el helado en la Heladería",
		llevar = "Llevá el helado a la Torre antes de que se derrita",
		premio = 250,
	},
	{
		id = "Remedios",
		tipo = "entrega",
		desde = "Farmacia",
		hasta = "Lo De Lalo Pet Shop",
		buscar = "Buscá los remedios en la Farmacia",
		llevar = "Llevá los remedios a Lo De Lalo Pet Shop",
		premio = 200,
	},
	{
		id = "Pan",
		tipo = "entrega",
		desde = "Panadería",
		hasta = "Verdulería",
		buscar = "Buscá el pan en la Panadería",
		llevar = "Llevá el pan a la Verdulería",
		premio = 200,
	},
	{
		id = "Libro",
		tipo = "entrega",
		desde = "Librería",
		hasta = "Kiosco",
		buscar = "Buscá el libro en la Librería",
		llevar = "Llevá el libro al Kiosco",
		premio = 200,
	},
	{ id = "MonedasCalle", tipo = "monedasCiudad", meta = 25, texto = "Juntá monedas en las calles de la ciudad", premio = 150 },
	{ id = "Cima", tipo = "cima", texto = "Subí a la cima de la Torre", premio = 200 },
	{ id = "Manejar", tipo = "manejar", meta = 600, texto = "Manejá un auto por la ciudad (avenida norte)", premio = 200 },
	{ id = "Alimento", tipo = "alimento", meta = 1, texto = "Comprá alimento para tus mascotas en Lo De Lalo Pet Shop", premio = 120 },
}

return ConfigMisiones
