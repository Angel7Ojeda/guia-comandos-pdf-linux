# Registro de cambios

Este archivo recoge los cambios relevantes de cada versión publicada de la guía. El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y la numeración sigue el [versionado semántico](https://semver.org/lang/es/), adaptado a un documento:

- **MAYOR**: reorganización profunda o cambio de la versión de Ubuntu de referencia.
- **MENOR**: capítulos, herramientas o secciones nuevas.
- **PARCHE**: correcciones y aclaraciones.

## [Sin publicar]

## [1.0.1] - 2026-11-23

### Corregido

- Ghostscript sin `%d` en el nombre de salida no deja «solo la última página»: escribe todas las páginas en el mismo archivo, que con TIFF es multipágina y con PNG solo muestra la primera en los visores.
- Flujo 10 (`masivo.sh`): decidía con `pdffonts` si cada documento era escaneado, de modo que un PDF mixto pasaba sin OCR. Ahora llama directamente a OCRmyPDF con `--skip-text`, que decide página a página; la explicación advierte de que los PDF cifrados o firmados quedan en el registro sin texto.
- Flujo 10: la orden que guarda la salida de la consola con `tee` no guardaba nada la primera vez, porque la carpeta aún no existía.
- Marker: con llama.cpp, `SURYA_INFERENCE_PARALLEL` no se calcula sola; si no se define, vale 8.
- Marker: `--ocr_inline_math` sin valor no siempre da error. Delante del archivo, toma su nombre como valor y falla (`is not a valid boolean`); al final de la orden o delante de otra opción, queda en automático sin avisar. La fila de errores cita ahora el mensaje real.
- Potrace: la tabla de formatos repetía PGM con datos contradictorios.
- El recuadro sobre la numeración de páginas omitía Marker en su primera frase.

### Añadido

- Marker: aviso para equipos con poca memoria. Con 8 peticiones simultáneas, `llama-server` se cierra en WSL2 con 3,5 GB de memoria y Marker termina con código 0 y un Markdown vacío; con `SURYA_INFERENCE_PARALLEL=1`, la conversión se completa. El aviso explica también cómo cerrar los servidores auxiliares de Surya que Marker 2.0.0 deja en marcha, y la tabla de errores recoge los dos casos.
- OCRmyPDF: fila de errores para `Too few characters. Skipping this page` y `Error during processing.`, que con `--rotate-pages` aparecen en páginas con poco texto sin impedir el OCR.
- Prueba de humo: de 42 a 80 comprobaciones. Los scripts y flujos marcados con `% prueba:` se leen de la guía; se prueban los flujos 3 a 6 y 8 a 10, el script de comprobación general, `lote.sh`, `pdf-es.yaml` y afirmaciones concretas del texto; las comprobaciones de xelatex, WSL, Marker y `shellcheck` solo se ejecutan si su entorno está disponible.
- `shellcheck` revisa los 114 bloques de órdenes de la guía, en local (si está instalado) y en los dos flujos de GitHub Actions; cada aviso señala el bloque por su línea en la guía.

### Cambiado

- Marker: la descripción de `--paginate_output` cita el separador real de la salida en Markdown (`{0}` seguido de 48 guiones) y aclara que las páginas se numeran desde 0.
- img2pdf: la fila de errores cita el mensaje `Reading image from standard input...`.

## [1.0.0] - 2026-10-10

Primera versión publicada, a partir de la guía original en LaTeX y tras una auditoría técnica completa (véase `docs/auditoria.md`).

### Añadido

- Procedimiento verificado para crear `~/marker-env` con Python 3.12 mediante `pipx` y `uv`, con su motivo: Marker 2.0.0 exige una versión de Pillow anterior a la 11, que no publica paquetes binarios para el Python 3.14 de Ubuntu 26.04.
- Explicación del aviso de OCRmyPDF 16.13 sobre Ghostscript 10.6, con su fila en la tabla de errores y una limitación en el capítulo de Ghostscript.
- Solución al mensaje `NSS_Init failed` de `pdfsig`.
- Número de versión en la portada y autor en los metadatos del PDF.
- Aviso de licencia en la portada: CC BY-NC-SA 4.0; la venta y el uso comercial requieren autorización escrita del autor.

### Corregido

- El archivo de valores por defecto `pdf-es.yaml` (Pandoc) había perdido la sangría y Pandoc lo rechazaba con `Unknown option "geometry"`.
- `pdfdetach -saveall` necesita que la carpeta de destino exista: el ejemplo la crea antes.
- Flujo 7: la imagen de control se genera con `-singlefile`; el nombre `control-1.png` solo existía en PDF de menos de 10 páginas.
- `--remove-background` no está implementada en OCRmyPDF 16.13 (termina con el código 15).
- La orden `convert` de Ubuntu 26.04 no muestra el aviso de obsolescencia que se describía.
- `qpdf --split-pages` rellena con ceros el número de página en documentos de 10 páginas o más.
- Ancla de hiperenlace `page.1` duplicada entre la portada y la primera página del cuerpo.

### Cambiado

- Sangría de los 137 bloques de código normalizada: el contenido empieza en la columna 0 y los bucles recuperan su estructura. No cambia ningún comando.
- Árbol de la carpeta de salida de Marker con su jerarquía.
- Tabla de comandos: el umbral se aplica sobre la escala de grises al convertir una imagen a SVG, como en el capítulo de Potrace.
