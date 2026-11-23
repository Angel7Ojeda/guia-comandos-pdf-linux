# Cómo contribuir

Gracias por ayudar a mejorar la guía. Este documento explica cómo informar de un error, cómo preparar un cambio y qué convenciones sigue el proyecto.

## Informar de un error o proponer una mejora

Abra un *issue* con la plantilla «Error en un comando» o «Propuesta de mejora». Si se trata de un error, incluya el comando exacto, el mensaje completo y la versión de la herramienta (`--version`): muchos fallos se deben a diferencias entre versiones.

## Preparar el entorno

Necesita Ubuntu 26.04 (en WSL2 o instalado directamente) con las herramientas de la guía (capítulo 3) y las dependencias de compilación:

```bash
sudo apt install make latexmk texlive-latex-recommended texlive-latex-extra \
    texlive-fonts-recommended texlive-lang-spanish lmodern
# opcional, para la prueba de Pandoc con xelatex:
sudo apt install texlive-xetex fonts-dejavu-core
# opcional, para revisar los bloques de órdenes:
sudo apt install shellcheck
```

## Flujo de trabajo

1. Cree una rama para el cambio: `git switch -c fix/descripcion-breve`.
2. Edite `src/guia-herramientas.tex`.
3. Compile y pruebe: `make && make test`.
4. Anote el cambio en la sección «Sin publicar» de `CHANGELOG.md`.
5. Haga *commit*, suba la rama (`git push -u origin fix/descripcion-breve`) y abra una solicitud de cambios (*pull request*). GitHub compilará la guía y ejecutará la prueba de humo en Ubuntu 26.04 antes de integrarla.

## Convenciones de la guía

- **Comandos verificados.** Todo comando nuevo o modificado se prueba con las versiones de Ubuntu 26.04. Si cambia un comando que cubre `tests/smoke.sh`, actualice también su comprobación; en los bloques marcados con `% prueba:` no hace falta copiar el comando nuevo, porque `tests/smoke.sh` lo lee de la guía.
- **Pruebas ligadas a un bloque.** Para probar un bloque tal como aparece en la guía, escriba `% prueba: NOMBRE` en la línea anterior a su `\begin{lstlisting}`. En `tests/smoke.sh`, `bloque NOMBRE` imprime su contenido y `ejecuta NOMBRE` lo lanza con `bash -e`. Todos los bloques de órdenes (sin estilo; véase «Estilos de bloque») pasan también por `shellcheck`.
- **Pruebas de varias líneas.** En `tests/smoke.sh`, empiécelas con `set -e` y escriba una comprobación por orden. `set -e` no detiene la prueba en `a && b` ni en `! orden`, así que las negaciones van en un `if …; then exit 1; fi`. Guarde en una variable la salida que va a comparar (`s=$(orden)`): dentro de `[ "$(orden)" … ]`, un fallo de la orden pasa inadvertido.
- **Bloques de código.** El contenido de cada `lstlisting` empieza en la columna 0, sin tabuladores, con 4 espacios por nivel de sangría. Desactive la sangría automática del editor dentro de esos bloques: la sangría se ve en el PDF y, en un *heredoc*, un `EOF` desplazado hace que la orden no termine.
- **Estilos de bloque.** Sin opción: comandos para copiar. `[style=sintaxis]`: plantillas que el lector adapta. `[style=salida]`: salida de un programa o contenido de un archivo.
- **Marcado.** `\cmd{}` para programas, `\opt{}` para opciones, `\arch{}` para archivos y rutas, `\val{}` para valores; cajas `nota`, `consejo`, `advertencia`, `importante`, `limitacion` y `ejemplo`.
- **Sin datos personales.** Las rutas usan `NOMBRE` (usuario de Windows) y `USUARIO` (usuario de Linux), nunca nombres reales.
- **Fuentes.** Las afirmaciones técnicas se apoyan en la documentación oficial o en la ayuda del programa instalado (`--help`, `man`).
- **Mensajes reales.** Los mensajes de error y de salida se copian de una ejecución real con las versiones de Ubuntu 26.04; no se traducen ni se reconstruyen de memoria.
- **Afirmaciones con alcance.** «Siempre», «nunca» y «por defecto» indican su alcance cuando dependen de la versión, del modo o del backend: «con llama.cpp», «en Marker 2.0.0».
- **Un concepto, un término.** La misma cosa se nombra igual en toda la guía; por ejemplo, «PDF mixto» para el que combina páginas digitales y escaneadas.
- **Sin relleno.** Cada frase aporta algo que el lector necesita para usar la herramienta.

## Licencia de las contribuciones

Al enviar una contribución acepta que se publique con las licencias del repositorio: CC BY-NC-SA 4.0 para el texto y MIT para el código. Para el texto, además, concede al autor permiso para publicar su aportación con otras condiciones, incluidas licencias comerciales; sin ese permiso, el autor no podría autorizar usos comerciales de la guía completa. Si no está de acuerdo, indíquelo en la solicitud de cambios antes de que se integre.

## Mensajes de commit

Use el formato `tipo(ámbito): descripción`, en español y en infinitivo, por ejemplo `fix(guia): corregir el rango de páginas de qpdf`. Tipos habituales: `docs` (contenido), `fix` (correcciones), `style` (formato sin cambios de contenido), `build`, `test`, `ci` y `chore` (mantenimiento).

## Publicar una versión (mantenimiento)

1. Actualice `\newcommand{\versionguia}{X.Y.Z}` en `src/guia-herramientas.tex`.
2. En `CHANGELOG.md`, mueva lo anotado en «Sin publicar» a una sección `## [X.Y.Z] - AAAA-MM-DD`.
3. Haga *commit* y `git push`, y espere a que el flujo «Compilar y probar» termine en verde.
4. Cree y suba la etiqueta: `git tag -a vX.Y.Z -m "Versión X.Y.Z"` y `git push origin vX.Y.Z`.
5. El flujo «Publicar versión» comprueba que la etiqueta coincide con `\versionguia`, compila, ejecuta la prueba de humo y crea la versión con el PDF y su suma SHA-256.
