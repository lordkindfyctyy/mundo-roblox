# Mundo Roblox

Juego de Roblox hecho con Luau y sincronizado con [Rojo](https://rojo.space): un **Recolector de Monedas** con tienda de mejoras y progreso guardado.

## Cómo se juega

- Aparecen 20 monedas girando por el mapa. Las **doradas** valen 1 punto y las **azules** (más raras) valen 5.
- Tu puntaje se ve en el marcador de arriba y en la tabla de jugadores.
- Con el botón **Tienda** (al medio del borde izquierdo) comprás mejoras con las monedas:

| Mejora | Efecto por nivel | Niveles | Costo |
|---|---|---|---|
| Velocidad | +2 al caminar | 5 | 20, 40, 60… |
| Salto | +5 de fuerza de salto | 5 | 30, 60, 90… |
| Monedas extra | +1 punto por moneda | 3 | 50, 100, 150 |

- Las monedas y las mejoras se **guardan** (DataStore) y siguen ahí cuando volvés a entrar.

## Contenido

| Archivo | Qué hace |
|---|---|
| `src/ServerScriptService/JuegoMonedas.server.lua` | Crea las monedas, las hace girar y suma los puntos |
| `src/ServerScriptService/TiendaMejoras.server.lua` | Valida las compras y aplica velocidad y salto |
| `src/ServerScriptService/GuardadoMonedas.server.lua` | Guarda y carga monedas y mejoras |
| `src/ReplicatedStorage/ConfigMejoras.lua` | Lista de mejoras (agregar una = agregar una fila) |
| `src/StarterPlayerScripts/MarcadorMonedas.client.lua` | Marcador de monedas en pantalla |
| `src/StarterPlayerScripts/Tienda.client.lua` | Interfaz de la tienda |
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

- [ ] Sonido al recoger monedas (completar `SONIDO_ID` en `JuegoMonedas.server.lua`)
- [ ] Más mejoras, por ejemplo un imán que atraiga las monedas
- [ ] Un mapa con decoración en vez del Baseplate
- [ ] Ranking de los jugadores con más monedas

## Autor

[lordkindfyctyy](https://github.com/lordkindfyctyy)
