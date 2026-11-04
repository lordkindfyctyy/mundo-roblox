# Ciudad de Benja (mundo-roblox)

Juego de Roblox en Luau con Rojo. El código está en `src/ServerScriptService` (servidor), `src/ReplicatedStorage`
(módulos compartidos y configuración) y `src/StarterPlayerScripts` (cliente, `*.client.lua`). No existen `src/client`
ni `src/server`.

## Rendimiento: reglas que salieron de medir

Se midió con `Stats.DataSendKbps` y `Stats.HeartbeatTimeMs` en una partida de Studio, sacando de `Workspace` una
carpeta a la vez para ver cuánto pesaba (`carpeta.Parent = nil`, medir, volver a poner). Medir siempre antes y después:
sin eso es adivinar.

1. **El servidor no mueve cosas decorativas en cada frame.** Cada `CFrame` o `PivotTo` que se hace desde el servidor se
   replica a todos los jugadores. Eso hacía que 85 monedas girando fueran el 74% del tráfico, y 14 autos de tráfico,
   otro 55%. Lo decorativo se mueve en el cliente:
   - Movimiento **constante** (giro de la rueda, de las monedas): el cliente calcula la posición con
     `Workspace:GetServerTimeNow()` y el servidor no hace nada por frame (`RuedaGigante.client.lua`,
     `MonedasGiran.client.lua`).
   - Movimiento que **cambia** (autos que frenan): el servidor decide y publica en atributos solo cuando algo cambia
     (origen, dirección, velocidad, hora); el cliente calcula el resto y suaviza las correcciones
     (`Autos.server.lua` + `AutosTrafico.client.lua`).
   - Los modelos que se mueven así llevan `ModelStreamingMode = Atomic` para que el cliente los reciba enteros.
2. **No disparar remotos por frame.** Hoy no hay ninguno dentro de un `Heartbeat`; que siga así. Si hace falta mandar
   algo seguido, publicar un atributo o agrupar los datos.
3. **Bucles con espera.** Un `while true do task.wait(n)` está bien si `n` es razonable (hoy van de 0,1 s a 60 s).
   No reemplazarlos por eventos "porque sí": el ciclo de semáforos o el reloj del día son periódicos de verdad. Sí hay
   que evitar trabajo por frame (`Heartbeat`/`RenderStepped`) cuando una espera o un evento alcanza, y limitar con la
   distancia al jugador lo que solo importa de cerca (como la rueda gigante).
4. **Instancias.** Crear el mundo una sola vez al arrancar está bien. Lo que se crea por evento (un sonido por moneda,
   efectos) conviene hacerlo en el cliente. No crear tablas ni instancias dentro de bucles que corren seguido.
5. **Efectos visuales y sonidos** solo en el cliente cuando no afectan al juego.
6. **Celulares:** el cuello de botella en un Moto G06 (3,8 GB de RAM) era DIBUJAR la escena, no los scripts: un hilo de Roblox al 84% con el de los scripts al 35%, 29-38 FPS y ~780 MB. `ModoCelular.client.lua` recorta lo caro solo en dispositivos sin teclado; `default.project.json` fija la iluminacion (`ShadowMap`) y el streaming (radio 320). Para probarlo en Studio se crea un `BoolValue` llamado `ForzarCelular` en `ReplicatedStorage` (y se borra despues). Los cambios solo llegan al celular **publicando** el lugar desde Studio.
7. **Mascotas:** hoy se mueven desde el servidor (~22 Kbps y ~0,33 ms por mascota) y escalan mal con muchos jugadores.
   Pendiente pasarlas al cliente con el patrón del punto 1.

## Datos (DataStore)

- Un solo módulo guarda: `GuardadoMonedas.server.lua`. Todo dato nuevo del jugador va como atributo y se carga y se guarda ahí.
- Se guarda al salir, cada 60 s y al cerrar el servidor. **Nunca por cada acción.**
- `guardar` no escribe dos veces a la vez para el mismo jugador y `BindToClose` espera a que terminen todos (tope 25 s).
  No volver a poner una espera fija.
- No agregar librerías externas (ProfileService y similares) sin hablarlo: es reescribir cómo se guardan los datos reales
  de los jugadores.

## Al trabajar

- **Rojo 7.7.1 se cae** (`change_processor.rs`, archivo no encontrado) si se crean o cambian archivos rápido mientras
  vigila la carpeta. Escribir todo con Rojo apagado, levantarlo para probar (`rojo serve --port 34873`) y volver a tocar
  *Connect* en Studio. Guerra Mundial Z usa el puerto 34872.
- **Las partidas de prueba en Studio usan los datos reales del jugador** (DataStore). Si una prueba cambia monedas,
  logros, mascotas o huevos, devolverlos antes de cerrar y comprobar en el DataStore que quedó como estaba.
- El jugador puede estar jugando en esa misma ventana de Studio: los teletransportes de una prueba le mueven el personaje.
- Nunca forzar un `git push` ni pisar `main` sin preguntar. Este repo ya se bifurcó una vez y hubo que mezclar a mano.
- Los `Id` que se guardan (logros, huevos) no se renombran aunque cambie la meta: se cobraría dos veces.
