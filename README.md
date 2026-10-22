# Mundo Roblox

Juego de Roblox hecho con Luau y sincronizado con [Rojo](https://rojo.space): un **Recolector de Monedas** con tienda de mejoras y progreso guardado.

## Cómo se juega

- Aparecen 20 monedas girando por el mapa. Las **doradas** valen 1 punto, las **azules** (más raras) valen 5 y la **gigante violeta** (muy rara) vale 25.
- Cada moneda suena al recogerla (un sonido distinto para la dorada y la azul).
- Cada tanto hay un **evento**: la *Hora dorada* (las monedas valen el doble durante 30 segundos) o la *Lluvia de monedas* (caen 40 monedas extra del cielo). Un cartel arriba avisa cuál está activo.
- Tu puntaje se ve en el marcador de arriba y en la tabla de jugadores.
- Con el botón **Tienda** (al medio del borde izquierdo) comprás mejoras con las monedas:

| Mejora | Efecto por nivel | Niveles | Costo |
|---|---|---|---|
| Velocidad | +2 al caminar | 5 | 20, 40, 60… |
| Salto | +5 de fuerza de salto | 5 | 30, 60, 90… |
| Monedas extra | +1 punto por moneda | 3 | 50, 100, 150 |
| Imán | +8 studs de radio para atraer monedas | 5 | 40, 80, 120… |
| Suerte | +8% de chance de que una moneda valga el doble | 5 | 60, 120, 180… |
| Salto extra | +1 salto en el aire (doble y triple salto) | 2 | 100, 200 |

- Las monedas y las mejoras se **guardan** (DataStore) y siguen ahí cuando volvés a entrar.
- Con suficientes monedas podés **Renacer** (fila violeta al pie de la tienda): reinicia tus monedas y mejoras a cambio de un bonus permanente de +20% de monedas por cada renacimiento. El primero cuesta 2.000 monedas, el segundo 4.000, y así. El ranking no se reinicia.
- Cada día podés reclamar una **recompensa diaria** (botón *Regalo* debajo de la tienda). Con la racha de días seguidos el premio sube de 50 a 350 monedas en el día 7, y después vuelve a empezar. Si te salteás un día, la racha se reinicia. El día cambia a las 00:00 UTC (21:00 en Argentina).
- Hay 10 **logros** (botón *Logros* debajo de Regalo) con premio en monedas: juntar monedas, cazar gigantes, comprar mejoras, renacer, mantener la racha diaria… El panel muestra el progreso de cada uno y un aviso salta al desbloquearlos.
- Suena **música de fondo** (5 temas alegres en orden al azar). El botón *Música* arriba de la tienda la silencia solo para vos.
- En el fondo del mapa hay un **ranking global** con los 10 jugadores que más monedas recolectaron en total.

## Contenido

| Archivo | Qué hace |
|---|---|
| `src/ServerScriptService/JuegoMonedas.server.lua` | Crea las monedas, las hace girar, suma los puntos y atrae monedas con el imán |
| `src/ServerScriptService/Mapa.server.lua` | Genera el mapa: césped, cerco, árboles, flores y cartel de bienvenida |
| `src/ServerScriptService/Eventos.server.lua` | Elige y corre los eventos aleatorios (hora dorada, lluvia de monedas) |
| `src/ServerScriptService/Logros.server.lua` | Detecta los logros cumplidos, paga el premio y avisa |
| `src/ServerScriptService/Recompensa.server.lua` | Valida y paga la recompensa diaria con racha |
| `src/ServerScriptService/Renacer.server.lua` | Valida y hace el reinicio de Renacer (prestigio) |
| `src/ServerScriptService/Ranking.server.lua` | Cartel con el ranking global (top 10 de monedas recolectadas en total) |
| `src/ServerScriptService/TiendaMejoras.server.lua` | Valida las compras y aplica velocidad y salto |
| `src/ServerScriptService/GuardadoMonedas.server.lua` | Guarda y carga monedas y mejoras |
| `src/ReplicatedStorage/ConfigMejoras.lua` | Lista de mejoras (agregar una = agregar una fila) |
| `src/ReplicatedStorage/ConfigRenacer.lua` | Costo y bonus de Renacer |
| `src/ReplicatedStorage/ConfigRecompensa.lua` | Premio base, largo del ciclo y fórmulas de la recompensa diaria |
| `src/ReplicatedStorage/ConfigLogros.lua` | Lista de logros (agregar uno = agregar una fila) |
| `src/StarterPlayerScripts/MarcadorMonedas.client.lua` | Marcador de monedas en pantalla |
| `src/StarterPlayerScripts/Anuncio.client.lua` | Cartel del evento activo con cuenta regresiva |
| `src/StarterPlayerScripts/MusicaFondo.client.lua` | Música de fondo con lista de temas y botón para silenciar |
| `src/StarterPlayerScripts/Logros.client.lua` | Botón Logros, panel de progreso y aviso al desbloquear |
| `src/StarterPlayerScripts/Recompensa.client.lua` | Botón Regalo y panel de la recompensa diaria |
| `src/StarterPlayerScripts/SaltoExtra.client.lua` | Saltos extra en el aire (mejora "Salto extra") |
| `src/StarterPlayerScripts/Tienda.client.lua` | Interfaz de la tienda (con scroll) |
| `default.project.json` | Configuración de Rojo |
| `aftman.toml` | Versión de Rojo a usar |

## Usar con Rojo

Este repo está preparado para Rojo, que sincroniza los archivos con Roblox Studio en vivo (sin copiar y pegar).

### Instalación (una sola vez)

1. Instalá el **plugin de Rojo** en Studio: buscá "Rojo" en el Toolbox o en https://create.roblox.com/store/asset/13916111004
2. Instalá la herramienta de línea de comandos, con [Aftman](https://github.com/LPGhatguy/aftman) (lee `aftman.toml`):
   ```
   aftman install
   ```
   o descargá `rojo` desde https://github.com/rojo-rbx/rojo/releases

### Trabajar

1. En la carpeta del repo, corré:
   ```
   rojo serve
   ```
2. En Studio, abrí un lugar nuevo (Baseplate), andá a la pestaña **Plugins → Rojo** y tocá **Connect**.
3. Editá los archivos `.lua` con tu editor (por ejemplo VS Code) y los cambios aparecen solos en Studio.
4. Dale **Play** para probar.

### Estructura

| Carpeta del repo | Dónde aparece en Roblox |
|---|---|
| `src/ServerScriptService` | ServerScriptService |
| `src/ReplicatedStorage` | ReplicatedStorage |
| `src/StarterPlayerScripts` | StarterPlayer → StarterPlayerScripts |

Convención de nombres: `*.server.lua` = Script, `*.client.lua` = LocalScript, `*.lua` = ModuleScript.

## Para que funcione el guardado

El guardado usa DataStore, así que en Studio hay que:

1. **Publicar el juego:** File → Publish to Roblox.
2. **Permitir DataStore en Studio:** Home → Game Settings → Security → activar **Enable Studio Access to API Services**.

## Ideas para seguir

- [ ] Publicar el juego para que lo prueben otras personas


## Autor

[lordkindfyctyy](https://github.com/lordkindfyctyy)
