# Mundo Roblox

Juego de Roblox hecho con Luau y sincronizado con [Rojo](https://rojo.space): un **Recolector de Monedas** con tienda de mejoras y progreso guardado.

## Cómo se juega

- Aparecen 20 monedas girando en el parque y otras 40 sobre las calles de la ciudad. Las **doradas** valen 1 punto, las **azules** (más raras) valen 5 y la **gigante violeta** (muy rara) vale 25.
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
- Hay 12 **logros** (botón *Logros* debajo de Regalo) con premio en monedas: juntar monedas, cazar gigantes, comprar mejoras, renacer, mantener la racha diaria… El panel muestra el progreso de cada uno y un aviso salta al desbloquearlos.
- Suena **música de fondo** (5 temas alegres en orden al azar). El botón *Música* arriba de la tienda la silencia solo para vos.
- Con el botón *Mascotas* (borde derecho) abrís huevos y conseguís mascotas de 5 rarezas (Común a Legendaria): el **huevo común** (500 monedas) y el **huevo dorado** (2.500), que no trae comunes y es el único con el Unicornio y el Dragón dorado. Hay 13 mascotas. Si te sale una repetida **sube de nivel** (hasta el 5, cada nivel +25% de su bonus); en nivel máximo, una repetida devuelve parte del huevo. Podés llevar hasta 3 equipadas: te siguen por el mapa y suman un bonus de monedas (de +5% a +60% cada una). Cada especie tiene su propio modelo (orejas, hocico, alas, cola...), con el nombre arriba del color de su rareza; las raras brillan, las épicas tiran destellos, la legendaria tiene fuego, y el búho, el dragón y el fénix vuelan a tu lado.
- La interfaz se adapta a la pantalla: en celular todo se achica, los botones de los costados suben para no tapar el joystick ni el botón de saltar, y cada panel tiene una **X** para cerrarlo (se abre uno a la vez).
- Alrededor del parque hay una **ciudad** para recorrer: calles con líneas pintadas, veredas, edificios de distintas alturas y faroles. Se sale del parque por las entradas del medio de cada lado del cerco. Por las calles andan **autos** por la mano derecha; frenan si tienen a alguien adelante, así que nunca te atropellan, y respetan los **semáforos** de cada cruce (verde 8 s, amarillo 2 s y un segundo todo en rojo antes de darle paso a la otra calle).
- Frente al parque hay **negocios** con cartel (heladería, pizzería, kiosco, farmacia, panadería, librería y verdulería) y **Lo De Lalo Pet Shop**, al oeste: se puede entrar y en el mostrador comprar alimento para las mascotas. Mientras dura, el bonus de monedas de las mascotas equipadas se multiplica (Snack x1,5 por 1 min, Balanceado x2 por 2 min, Premium x3 por 3 min) y un cartel abajo muestra cuánto falta.
- En la esquina noreste de la ciudad está la **Torre** (100 de alto): se sube saltando por plataformas de colores que dan vueltas alrededor. Arriba hay un **cofre con 300 monedas** (una vez cada 10 minutos por jugador) y una plataforma azul para bajar de un toque.
- En la **avenida norte** (saliendo del parque por el lado del ranking) hay **6 autos para manejar**, azules y blancos: "Manejar" para ir al volante y "Subir" de acompañante. Se maneja con W/S y A/D (o el joystick en el celular) y se baja saltando. Si un auto queda solo lejos de su lugar, a los 45 segundos vuelve al estacionamiento.
- **🏝️ La Playa:** al final de la avenida del este, pasando el arco de entrada (libre, sin costo). Hay arena con palmeras y sombrillas, mar de verdad para nadar, monedas que valen el triple y plataformas flotantes hasta la **isla del tesoro**, con un cofre de 500 monedas (una vez cada 10 minutos).
- **🏠 Casas:** al final de la avenida del oeste está el **Barrio**, con 6 terrenos con cartel *Se vende*. La casa se compra una vez (3.000 monedas) y queda guardada: cada vez que entrás aparece en un terreno libre, con tu nombre en el cartel. Adentro, en el atril *Decorar*, comprás muebles (alfombra, planta, lámpara, mesa con sillas, sillón, cucha, cama y televisor), que aparecen cada uno en su lugar. La puerta queda abierta para los amigos y el dueño la puede cerrar para que solo entre él. El botón *Mi casa* (derecha) te lleva a la puerta.
- **🚗 Tienda de autos:** en el taller que está enfrente de la salida norte del parque (cruzando la calle) se compran pinturas (roja, verde, negra, rosa, dorada), rayas (blancas, de carrera, de fuego), ruedas (doradas, de neón) y el **motor deportivo** (más rápido, con alerón). Lo comprado queda guardado; lo que tengas puesto lo lleva cualquier auto que manejes, y al bajarte vuelve a su color.
- **Carreras contra reloj:** con un auto, pasá por el arco de LARGADA de la avenida norte (yendo hacia afuera), recorré los 8 arcos numerados por la calle de afuera de la ciudad y volvé a la largada. Premio: 100 monedas por llegar (en menos de 2 minutos) y 200 más si mejorás tu récord. Los récords quedan guardados: tu mejor tiempo se recuerda aunque salgas del juego, y el cartel al lado de la largada muestra los 5 mejores de todos los jugadores (en Studio necesita Enable Studio Access to API Services; si no, muestra los de la partida). Si te bajás del auto se cancela.
- Siempre hay una **misión** activa (tarjeta arriba a la derecha): entregas entre negocios, la Torre y el parque (a pie o en auto), juntar monedas en la calle, subir a la Torre, manejar o comprar alimento en el pet shop. Una columna de luz amarilla marca a dónde ir y la tarjeta dice a cuántos metros. Al cumplirla se cobra el premio y llega otra; con *Cambiar* se pide una distinta.
- Hay **día y noche**: un día dura 9 minutos (6 de día y 3 de noche). De noche se prenden los faroles y los faros de los autos.
- En el fondo del mapa hay un **ranking global** con los 10 jugadores que más monedas recolectaron en total.

## Contenido

| Archivo | Qué hace |
|---|---|
| `src/ServerScriptService/JuegoMonedas.server.lua` | Crea las monedas, las hace girar, suma los puntos y atrae monedas con el imán |
| `src/ServerScriptService/Mapa.server.lua` | Genera el parque del centro: césped, cerco con 4 entradas, árboles, flores y cartel de bienvenida |
| `src/ServerScriptService/PlanoCiudad.lua` | Dónde van las calles; lo usan la ciudad y las monedas de la ciudad |
| `src/ServerScriptService/Autos.server.lua` | Autos que recorren las calles, frenan ante jugadores y otros autos y ceden el paso en los cruces |
| `src/ServerScriptService/Semaforos.server.lua` | Semáforos en las esquinas de los 16 cruces y el ciclo de luces que siguen los autos |
| `src/ServerScriptService/Negocios.lua` | Arma los negocios con cartel y Lo De Lalo Pet Shop (adentro, la compra de alimentos) |
| `src/ReplicatedStorage/ConfigAlimentos.lua` | Alimentos del pet shop: precio, multiplicador y duración |
| `src/StarterPlayerScripts/Alimentos.client.lua` | Aviso de cada compra y cuenta regresiva del alimento |
| `src/ServerScriptService/Torre.lua` | La Torre: plataformas en espiral, cofre con premio y plataforma para bajar |
| `src/ServerScriptService/DiaNoche.server.lua` | Ciclo de día y noche; prende de noche lo que tiene la etiqueta LuzDeNoche |
| `src/ServerScriptService/Vehiculos.server.lua` | Autos azules y blancos para manejar: asientos, manejo y vuelta al estacionamiento |
| `src/ServerScriptService/Misiones.server.lua` | Da, sigue y paga las misiones de cada jugador |
| `src/ReplicatedStorage/ConfigMisiones.lua` | Lista de misiones (agregar una = agregar una fila) |
| `src/StarterPlayerScripts/Misiones.client.lua` | Tarjeta de la misión, botón Cambiar y la columna de luz en el destino |
| `src/ServerScriptService/Carreras.server.lua` | Circuito con arcos, largada, premios y cartel de mejores tiempos |
| `src/StarterPlayerScripts/Carreras.client.lua` | Cronómetro y marca del próximo arco durante la carrera |
| `src/ServerScriptService/Playa.server.lua` | La Playa: arena, mar, arco de entrada, plataformas e isla del tesoro |
| `src/ServerScriptService/TiendaAutos.server.lua` | El taller y las compras de la tienda de autos |
| `src/ServerScriptService/SkinsAutos.lua` | Le pone al auto el estilo de quien lo maneja y se lo saca al bajarse |
| `src/ReplicatedStorage/ConfigAutos.lua` | Lista de pinturas, rayas, ruedas y motor (agregar una = agregar una fila) |
| `src/StarterPlayerScripts/TiendaAutos.client.lua` | Panel de la tienda de autos |
| `src/ServerScriptService/Casas.server.lua` | El Barrio: terrenos, casas, puerta con llave, muebles y "Mi casa" |
| `src/ReplicatedStorage/ConfigCasas.lua` | Precio de la casa y lista de muebles |
| `src/StarterPlayerScripts/Casas.client.lua` | Botón Mi casa y panel de muebles |
| `src/ServerScriptService/Ciudad.server.lua` | Genera la ciudad alrededor del parque: calles, veredas, 12 manzanas con edificios, faroles y sendas peatonales |
| `src/ServerScriptService/Eventos.server.lua` | Elige y corre los eventos aleatorios (hora dorada, lluvia de monedas) |
| `src/ServerScriptService/ModelosMascotas.lua` | Arma el modelo de cada especie de mascota y sus efectos por rareza |
| `src/ServerScriptService/Mascotas.server.lua` | Huevos, equipar mascotas y modelos que siguen al jugador |
| `src/ServerScriptService/Logros.server.lua` | Detecta los logros cumplidos, paga el premio y avisa |
| `src/ServerScriptService/Recompensa.server.lua` | Valida y paga la recompensa diaria con racha |
| `src/ServerScriptService/Renacer.server.lua` | Valida y hace el reinicio de Renacer (prestigio) |
| `src/ServerScriptService/Ranking.server.lua` | Cartel con el ranking global (top 10 de monedas recolectadas en total) |
| `src/ServerScriptService/TiendaMejoras.server.lua` | Valida las compras y aplica velocidad y salto |
| `src/ServerScriptService/GuardadoMonedas.server.lua` | Guarda y carga monedas y mejoras |
| `src/ReplicatedStorage/Interfaz.lua` | Ayudas de interfaz: escala según la pantalla, botones laterales para compu/celular y un panel abierto a la vez |
| `src/ReplicatedStorage/ConfigMejoras.lua` | Lista de mejoras (agregar una = agregar una fila) |
| `src/ReplicatedStorage/ConfigRenacer.lua` | Costo y bonus de Renacer |
| `src/ReplicatedStorage/ConfigRecompensa.lua` | Premio base, largo del ciclo y fórmulas de la recompensa diaria |
| `src/ReplicatedStorage/ConfigLogros.lua` | Lista de logros (agregar uno = agregar una fila) |
| `src/ReplicatedStorage/ConfigMascotas.lua` | Lista de mascotas, rarezas, chances y costo del huevo |
| `src/StarterPlayerScripts/MarcadorMonedas.client.lua` | Marcador de monedas en pantalla |
| `src/StarterPlayerScripts/Anuncio.client.lua` | Cartel del evento activo con cuenta regresiva |
| `src/StarterPlayerScripts/MusicaFondo.client.lua` | Música de fondo con lista de temas y botón para silenciar |
| `src/StarterPlayerScripts/Mascotas.client.lua` | Botón Mascotas, panel de colección y huevos |
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
4. Dale **Play** para probar. Para ver cómo queda en un celular: pestaña **Test → Device** y elegí un teléfono.

### Estructura

| Carpeta del repo | Dónde aparece en Roblox |
|---|---|
| `src/ServerScriptService` | ServerScriptService |
| `src/ReplicatedStorage` | ReplicatedStorage |
| `src/StarterPlayerScripts` | StarterPlayer → StarterPlayerScripts |

Convención de nombres: `*.server.lua` = Script, `*.client.lua` = LocalScript, `*.lua` = ModuleScript.

## Publicar cambios

El juego ya está publicado en Roblox. Después de cada cambio (con Rojo conectado en Studio): **File → Publish to Roblox** (Alt + P) para que llegue a los servidores.

## Para que funcione el guardado

El guardado usa DataStore, así que en Studio hay que:

1. **Publicar el juego:** File → Publish to Roblox.
2. **Permitir DataStore en Studio:** Home → Game Settings → Security → activar **Enable Studio Access to API Services**.

## Ideas para seguir

- [x] Publicar el juego para que lo prueben otras personas
- [x] Ajustar la interfaz para celular (hay muchos botones y paneles)
- [x] Mascotas con mejor aspecto


## Autor

[lordkindfyctyy](https://github.com/lordkindfyctyy)
