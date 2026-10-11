# Registro de cambios

Este archivo recoge los cambios relevantes de cada versión publicada de la guía. El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y la numeración sigue el [versionado semántico](https://semver.org/lang/es/), adaptado a un documento:

- **MAYOR**: reorganización profunda o cambio de la versión de Ubuntu de referencia.
- **MENOR**: capítulos, herramientas o secciones nuevas.
- **PARCHE**: correcciones y aclaraciones.

## [Sin publicar]

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
