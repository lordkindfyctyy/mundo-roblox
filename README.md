# Mundo Roblox

Proyecto sobre el mundo de Roblox.

## Descripción

Este repositorio va a reunir todo lo relacionado con mi proyecto de Roblox: ideas, scripts, recursos y documentación.

## Contenido

- `README.md`: esta presentación del proyecto.
- `src/ServerScriptService/JuegoMonedas.server.lua`: juego de ejemplo "Recolector de Monedas".
- `default.project.json`: configuración de Rojo
- `aftman.toml`: versión de Rojo a usar

## Próximos pasos

- [ ] Definir la idea del juego o mundo
- [ ] Agregar scripts (Lua / Luau)
- [ ] Sumar recursos y documentación

## Autor

[lordkindfyctyy](https://github.com/lordkindfyctyy)

## Usar con Rojo

Este repo está preparado para [Rojo](https://rojo.space), que sincroniza los archivos del repo con Roblox Studio en vivo (sin copiar y pegar).

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

### Estructura

| Carpeta del repo | Dónde aparece en Roblox |
|---|---|
| `src/ServerScriptService` | ServerScriptService |
| `src/ReplicatedStorage` | ReplicatedStorage |
| `src/StarterPlayerScripts` | StarterPlayer → StarterPlayerScripts |

Convención de nombres: `*.server.lua` = Script, `*.client.lua` = LocalScript, `*.lua` = ModuleScript.

## Juego de ejemplo: Recolector de Monedas

Está en `src/ServerScriptService/JuegoMonedas.server.lua`. Con Rojo conectado, presioná Play en Studio: aparecen 20 monedas y cada una que tocás suma 1 punto en la tabla de jugadores.
