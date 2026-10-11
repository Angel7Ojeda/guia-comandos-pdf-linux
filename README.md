# Guía de comandos para PDF, imágenes y documentos en Linux

[![Compilar y probar](../../actions/workflows/compilar.yml/badge.svg)](../../actions/workflows/compilar.yml)
[![Licencia: CC BY-NC-SA 4.0](https://img.shields.io/badge/licencia-CC%20BY--NC--SA%204.0-lightgrey.svg)](LICENSE)

Manual de consulta en español para trabajar desde la terminal de **Ubuntu 26.04 LTS en WSL2** (Windows 11) con nueve herramientas libres: Marker, Poppler, img2pdf, ImageMagick, Potrace, Pandoc, QPDF, OCRmyPDF y Ghostscript.

**[Descargar el PDF de la última versión](../../releases/latest/download/guia-comandos-pdf-linux.pdf)** · [Todas las versiones](../../releases) · [English summary](README.en.md)

## Qué problema resuelve

La documentación de estas herramientas está repartida en manuales en inglés, cada uno con sus propias convenciones, y muchas opciones cambian de una versión a otra: un comando copiado de Internet puede no existir en la versión que instala Ubuntu. Esta guía reúne en un solo documento lo necesario para las tareas habituales, como pasar un PDF a Markdown, hacer OCR a un escaneo, unir o dividir PDF, reducir su tamaño, convertir imágenes, vectorizar un logotipo o generar documentos con Pandoc. Los comandos están comprobados con las versiones exactas de Ubuntu 26.04, y la guía explica además lo que cambia al trabajar en WSL2: rutas de Windows, rendimiento, memoria y nombres con espacios.

## Qué contiene

Cada herramienta tiene un capítulo con la misma estructura: qué es y cuándo conviene usarla, instalación, sintaxis y opciones, ejemplos listos para copiar, formatos admitidos, limitaciones y errores frecuentes. Después vienen las comparaciones entre herramientas, una matriz de operaciones sobre PDF, diez flujos de trabajo que combinan varias de ellas, tablas de formatos, dependencias y comandos, y una referencia rápida. En total, 118 páginas.

| Herramienta | Para qué sirve | Versión verificada |
|---|---|---|
| Marker | PDF y documentos a Markdown, JSON o HTML | 2.0.0 (PyPI, entorno con Python 3.12) |
| Poppler | Inspeccionar, extraer y rasterizar PDF | 26.01.0 |
| img2pdf | Imágenes a PDF sin recomprimir | 0.6.2 |
| ImageMagick | Procesar y convertir imágenes | 7.1.2-18 |
| Potrace | Vectorizar mapas de bits | 1.16 |
| Pandoc | Convertir entre formatos de documento | 3.7.0.2 |
| QPDF | Páginas, cifrado y reparación de PDF | 12.3.2 |
| OCRmyPDF (con Tesseract 5.5.0) | Capa de texto OCR para escaneos | 16.13.0 |
| Ghostscript | Reescribir, reducir y rasterizar PDF y PostScript | 10.06.0 |

## Requisitos

La guía está escrita para Windows 11 con WSL2 y Ubuntu 26.04 LTS. En otras versiones de Ubuntu la mayoría de los comandos funcionan, pero algunas opciones cambian; la sección 1.3 de la guía explica cómo comprobar la versión instalada. Ocho herramientas se instalan con `apt`; Marker se instala con `pip` dentro de un entorno virtual con Python 3.12 (sección 3.4).

## Inicio rápido

```bash
# Ubuntu (WSL2): instalar las herramientas
sudo apt update
sudo apt install poppler-utils img2pdf imagemagick potrace pandoc qpdf \
    ocrmypdf tesseract-ocr-spa ghostscript unpaper pngquant jbig2

# Algunos usos habituales
pdfinfo documento.pdf                              # páginas, tamaño y metadatos
pdftotext -layout documento.pdf documento.txt      # texto de un PDF digital
ocrmypdf -l spa escaneo.pdf escaneo_ocr.pdf        # OCR en español
qpdf --empty --pages a.pdf b.pdf -- unido.pdf      # unir PDF sin alterarlos
```

La sección 1.2 de la guía («Localizador rápido») indica qué herramienta y qué comando usar para cada tarea.

## Compilar la guía

El código fuente está en `src/guia-herramientas.tex` y se compila con pdfLaTeX mediante `latexmk`.

```bash
# Ubuntu: dependencias de compilación
sudo apt install make latexmk texlive-latex-recommended texlive-latex-extra \
    texlive-fonts-recommended texlive-lang-spanish lmodern

git clone 
cd guia-comandos-pdf-linux
make            # genera build/guia-herramientas.pdf
make test       # prueba de humo (requiere las herramientas de la guía)
make clean      # borra los archivos auxiliares de LaTeX
```

La compilación se detiene si queda alguna referencia interna sin resolver. Los archivos generados van a `build/`, que Git ignora.

## Cómo se verifica

Cada cambio en la rama `main` y cada solicitud de cambios ejecutan un flujo de GitHub Actions dentro de un contenedor de Ubuntu 26.04, con las mismas versiones que documenta la guía. El flujo compila el PDF y ejecuta `tests/smoke.sh`, una prueba de humo con 42 comprobaciones de comandos representativos de cada capítulo sobre archivos sintéticos. Al subir una etiqueta `vX.Y.Z`, otro flujo publica la versión con el PDF y su suma SHA-256. Una vez por semana se comprueban los enlaces externos.

Dos partes no se automatizan: Marker, cuyos modelos ocupan varios gigabytes, y los comandos que dependen de Windows (`explorer.exe`, `wslpath`). El informe [`docs/auditoria.md`](docs/auditoria.md) describe cómo se verificó la guía, qué se corrigió y qué queda fuera de las pruebas.

## Estructura del repositorio

```
.
├── src/guia-herramientas.tex   código fuente de la guía (LaTeX)
├── tests/smoke.sh              prueba de humo de los comandos
├── docs/auditoria.md           informe de la auditoría técnica
├── .github/                    automatizaciones, Dependabot y plantillas
├── Makefile, latexmkrc         compilación con make y latexmk
├── CHANGELOG.md                historial de versiones
├── CONTRIBUTING.md             cómo contribuir
├── SECURITY.md                 cómo informar de un problema de seguridad
└── LICENSE                     licencias: texto CC BY-NC-SA 4.0, código MIT
```

## Contribuir

Los avisos de errores, las correcciones y las propuestas son bienvenidos. [`CONTRIBUTING.md`](CONTRIBUTING.md) explica cómo compilar, cómo probar y qué convenciones sigue la guía; las plantillas de *issues* piden la información necesaria para reproducir un problema.

## Hoja de ruta

- Ampliar la prueba de humo a más ejemplos de cada capítulo.
- Revisar la guía cuando Ubuntu actualice alguna herramienta o se publiquen nuevas versiones de Marker 2.
- Valorar una versión HTML navegable si resulta útil para quienes la leen.

## Licencia y atribución

El texto de la guía y la documentación se publican con la licencia [Creative Commons Atribución-NoComercial-CompartirIgual 4.0 Internacional](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es) (CC BY-NC-SA 4.0): pueden copiarse, compartirse y adaptarse sin fines comerciales, siempre que se cite la autoría y las adaptaciones se distribuyan con la misma licencia. **La venta de copias y cualquier otro uso comercial requieren la autorización previa y por escrito del autor.** Ejemplo de atribución: «Guía técnica de herramientas de línea de comandos», de Angel David Ojeda Peralta, CC BY-NC-SA 4.0.

El código del repositorio (`Makefile`, `latexmkrc`, `tests/` y los flujos de `.github/`) usa la licencia MIT. Los textos de ambas licencias están en [`LICENSE`](LICENSE).

Los nombres de las herramientas pertenecen a sus respectivos proyectos; esta guía no está afiliada a ninguno de ellos. Las cifras de rendimiento de Marker proceden de la documentación de Datalab y se citan como tales.

## Autor

Angel David Ojeda Peralta.  
[LinkedIn](www.linkedin.com/in/angel-ojeda-2424893a3) | [GitHub](https://github.com/Angel7Ojeda)
