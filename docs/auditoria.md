# Informe de auditoría técnica (versión 1.0.0)

Fecha: 10 de octubre de 2026. Alcance: `src/guia-herramientas.tex` (4.598 líneas, 137 bloques de código, 118 páginas) en su versión original y en la versión corregida que publica este repositorio.

## Método

1. Lectura completa del código fuente.
2. Compilación del original sin cambios, como referencia, con TeX Live 2023 y con TeX Live 2025.
3. Contraste con fuentes primarias: índices de paquetes de Ubuntu 26.04 descargados de `archive.ubuntu.com`; notas de versión, README y código fuente de Marker 2.0.0 y Surya 0.22.1 (paquetes de PyPI); registro de cambios de OCRmyPDF 16.13.0; metadatos de PyPI.
4. Ejecución real en un sistema Ubuntu 26.04 mínimo, instalado con `debootstrap` y la orden de instalación de la propia guía. Un programa extrajo los 137 bloques de código y ejecutó los 85 ejecutables sobre archivos sintéticos, registrando cada orden que fallaba. Se añadieron catorce pruebas dirigidas a afirmaciones concretas.

## Entorno de verificación

| Componente | Versión |
|---|---|
| Ubuntu | 26.04 LTS («resolute»), Python del sistema 3.14.3 |
| Poppler / img2pdf / ImageMagick | 26.01.0 / 0.6.2 / 7.1.2-18 |
| Potrace / Pandoc / QPDF | 1.16 / 3.7.0.2 / 12.3.2 |
| OCRmyPDF / Tesseract / Ghostscript | 16.13.0 / 5.5.0 / 10.06.0 |
| TeX Live / pdfTeX / latexmk | 2025 / 1.40.28 / 4.87 |
| Marker / Surya (solo código y documentación) | 2.0.0 / 0.22.1 |

## Resultados generales

| Comprobación | Original | Versión corregida |
|---|---|---|
| Compilación (errores, páginas) | 0 errores, 118 páginas | 0 errores, 118 páginas |
| Advertencias de pdfTeX | 1 (ancla `page.1` duplicada) | 0 |
| Referencias sin resolver | 0 | 0 |
| Fuentes sin incrustar | 0 | 0 |
| Bloques ejecutados sin incidencias | 66 de 85 | 69 de 85 |

Las incidencias que quedan en la versión corregida se deben al entorno de prueba, no a la guía: `free` y `df` dentro de un sistema aislado, la sustitución de procesos (`/dev/fd`) no disponible en ese sistema, archivos de ejemplo que no encajaban con el caso del comando (un PDF digital usado como entrada de OCR devuelve el código 6, que la propia guía documenta) y comandos que necesitan un entorno real de Marker.

## Errores confirmados y corregidos

| Ubicación | Problema | Evidencia | Corrección |
|---|---|---|---|
| Pandoc, archivo `pdf-es.yaml` | La sangría del YAML se había perdido | Pandoc termina con `Unknown option "geometry"` (código 64) | Jerarquía restaurada; la versión corregida compila con xelatex y DejaVu Serif |
| Poppler, adjuntos | `pdfdetach -saveall -o adjuntos/` falla si la carpeta no existe | `I/O Error: Error saving embedded file` | El ejemplo crea la carpeta antes |
| Flujo 7 | Abría `control-1.png`, pero en PDF de 10 o más páginas el archivo es `control-01.png` | Comprobado con un PDF de 12 páginas | Uso de `-singlefile`: el archivo siempre es `control.png` |
| OCRmyPDF, preprocesado | `--remove-background` no está implementada en 16.13 | `NotImplementedError` (código 15) | Marcada como no disponible, con alternativa |
| ImageMagick | Se afirmaba que `convert` muestra un aviso de obsolescencia | En Ubuntu 26.04 `convert` es un enlace a ImageMagick 7 y no muestra ningún aviso; el texto no existe en el paquete | Nota, tabla y fila de errores reescritas |
| QPDF, ejemplos | El comentario indicaba `pag-1.pdf` | Con 10 páginas o más el número se rellena con ceros (`pag-001.pdf` con 118 páginas) | Comentario precisado |
| Portada | Ancla de hiperenlace `page.1` duplicada | Advertencia de pdfTeX | Numeración propia de la portada |
| Capítulo 3 | No se explicaba cómo crear `~/marker-env` | Ubuntu 26.04 solo trae Python 3.14 y Marker 2.0.0 exige Pillow anterior a la 11, sin paquetes binarios para 3.14 | Procedimiento con `pipx` y `uv` probado: Python 3.12.15 y resolución de 101 dependencias con paquetes binarios |

## Información añadida

- **Aviso de OCRmyPDF sobre Ghostscript 10.6.** Aparece en cada ejecución en Ubuntu 26.04. Según las notas de OCRmyPDF 16.13.0, Ghostscript 10.6 puede truncar entre 1 y 15 bytes de datos JPEG, y OCRmyPDF detecta ese caso y restaura la imagen original. Se explica en el capítulo de OCRmyPDF, en su tabla de errores y como limitación de Ghostscript.
- **`pdfsig` sin base de certificados NSS.** En un sistema recién instalado, `pdfsig` muestra `NSS_Init failed: security library: bad database`. Se comprobó que el aviso desaparece al crear la base con `certutil` (paquete `libnss3-tools`).

## Cambios editoriales

- Sangría de los 137 bloques normalizada. El programa de transformación verifica que solo cambian espacios en blanco, y `git diff -w` sobre ese *commit* no muestra diferencias. Los bucles recuperan su estructura, el bloque `.wslconfig` ya no aparece desplazado y el riesgo de copiar un `EOF` con espacios delante desaparece.
- Árbol de la carpeta de salida de Marker con su jerarquía.
- Umbral sobre escala de grises en la tabla de comandos (imagen a SVG).
- Atajos `\bs` y `\tl` trasladados al preámbulo.

## Afirmaciones verificadas como correctas

Versiones de las nueve herramientas y de Tesseract; Python 3.14 como Python del sistema; existencia de los paquetes `jbig2` y `llama.cpp-tools`; dependencias y recomendaciones del paquete `ocrmypdf`; códigos de salida de QPDF y OCRmyPDF; `pdfunite` sobrescribe el último archivo si falta el de salida; valores de la política de ImageMagick (memoria 1 GiB, disco 2 GiB, área 256 MP, lado máximo 32 000 píxeles, `@*`, `URL`, `HTTP` y `HTTPS` bloqueados); el modo SAFER de Ghostscript bloquea la lectura de `/etc/passwd`; `img2pdf` sin imágenes espera la entrada estándar; `HISTCONTROL=ignoreboth` en la configuración predeterminada; `--jbig2-lossy` sigue disponible; Pandoc 3.7 no tiene `--syntax-highlighting` y OCRmyPDF 16 no tiene `--mode`; `qpdf --remove-structure` y `--set-page-labels` funcionan; en Marker 2.0.0, los cuatro ejecutables, los modos `balanced` y `fast`, las puntuaciones de olmOCR-bench, las variables `SURYA_*` y `LLAMA_CPP_BINARY`, los nombres de los modelos GGUF, las licencias (código Apache 2.0, pesos Open Rail-M modificada con el umbral de 5 millones de dólares) y que `--ocr_inline_math` exige `true` o `false`.

