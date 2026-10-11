# Configuración de latexmk para compilar la guía. latexmk la lee
# automáticamente cuando se ejecuta (o se usa make) desde la raíz del repositorio.
$pdf_mode = 1;                 # pdfLaTeX, como indica la primera línea del .tex
$out_dir = 'build';            # todo lo generado va a build/, que Git ignora
$warnings_as_errors = 1;       # una referencia o cita sin resolver hace fallar la compilación
$pdflatex = 'pdflatex -interaction=nonstopmode -halt-on-error -file-line-error %O %S';
@default_files = ('src/guia-herramientas.tex');
