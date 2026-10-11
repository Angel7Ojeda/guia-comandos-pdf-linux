#!/usr/bin/env bash
# shellcheck disable=SC2016  # el código de cada prueba se pasa entre comillas simples a propósito
# =============================================================================
#  Prueba de humo de la guía
#
#  Ejecuta comandos representativos de cada capítulo sobre archivos sintéticos
#  y comprueba sus resultados con las versiones de Ubuntu 26.04 LTS.
#
#  Uso:  bash tests/smoke.sh     (o bien: make test)
#  Trabaja en una carpeta temporal y no modifica nada fuera de ella.
#  Salida en formato TAP: "ok N - ..." o "not ok N - ...".
#  Si cambia un comando de la guía, actualice aquí la prueba equivalente.
# =============================================================================
set -uo pipefail

total=0
fallos=0
omitidas=0

DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT
cd "$DIR" || exit 1

# prueba "descripción" 'comandos': correcta si los comandos terminan con código 0.
prueba() {
    local desc=$1 codigo=$2 salida
    total=$((total + 1))
    if salida=$(bash -c "$codigo" 2>&1); then
        echo "ok $total - $desc"
    else
        fallos=$((fallos + 1))
        echo "not ok $total - $desc"
        printf '%s\n' "$salida" | tail -n 5 | sed 's/^/    # /'
    fi
}

# omitir "descripción" "motivo": se cuenta, pero no se ejecuta.
omitir() {
    total=$((total + 1))
    omitidas=$((omitidas + 1))
    echo "ok $total - $1 # SKIP $2"
}

# Número de páginas de un PDF (disponible dentro de cada prueba).
paginas() { pdfinfo "$1" | awk '/^Pages:/ {print $2}'; }
export -f paginas

for c in pdfinfo pdffonts pdftotext pdftoppm pdftocairo pdfimages pdfseparate pdfunite \
         pdfattach pdfdetach img2pdf magick potrace mkbitmap pandoc qpdf ocrmypdf \
         tesseract gs ps2pdf; do
    command -v "$c" >/dev/null || { echo "Falta '$c'. Instale las herramientas (capítulo 3 de la guía)." >&2; exit 2; }
done

echo "# Poppler $(pdftoppm -v 2>&1 | awk 'NR==1 {print $3}'), ImageMagick $(magick -version | awk 'NR==1 {print $3}'), QPDF $(qpdf --version | awk 'NR==1 {print $3}'), Pandoc $(pandoc --version | awk 'NR==1 {print $2}'), OCRmyPDF $(ocrmypdf --version 2>/dev/null), Ghostscript $(gs --version)"

# --- Archivos de ejemplo ------------------------------------------------------
# PDF digital de 12 páginas creado con PostScript y Ghostscript (no requiere LaTeX).
{
    echo '%!PS'
    for i in $(seq 1 12); do
        echo "/Helvetica findfont 28 scalefont setfont 72 700 moveto (Pagina $i presupuesto anual) show showpage"
    done
} > doc.ps
ps2pdf doc.ps doc.pdf
pdftoppm -r 150 -gray -png -f 1 -l 2 doc.pdf sc                 # páginas como imágenes
img2pdf --imgsize 150dpi sc-01.png sc-02.png -o escaneado.pdf   # PDF escaneado (sin texto)
magick -size 400x200 xc:white -fill black -draw 'circle 100,100 100,30' logo.png
magick -size 640x480 gradient:white-'#1f4e79' foto.jpg
mkdir -p orden && for n in 1 2 10; do cp logo.png "orden/pag$n.png"; done
printf 'columna,valor\nuno,1\n' > datos.csv
printf -- '---\ntitle: "Informe de prueba"\nlang: es\n---\n\n# Introducción\n\nTexto con tildes: canción y año.\n' > informe.md
if [ ! -s doc.pdf ] || [ ! -s escaneado.pdf ]; then
    echo "No se pudieron generar los archivos de ejemplo." >&2
    exit 2
fi

# --- Capítulo 5: Bash ---------------------------------------------------------
prueba "Bash: sort -V ordena pag1, pag2, pag10" \
    'cd orden && [ "$(printf "%s\n" pag*.png | sort -V | paste -sd" ")" = "pag1.png pag2.png pag10.png" ]'
prueba "Bash: lista ordenada con mapfile para img2pdf" \
    'cd orden && mapfile -t imgs < <(printf "%s\n" pag*.png | sort -V) && img2pdf "${imgs[@]}" -o natural.pdf && [ "$(paginas natural.pdf)" = 3 ]'

# --- Capítulo 7: Poppler ------------------------------------------------------
prueba "Poppler: pdfinfo cuenta 12 páginas" '[ "$(paginas doc.pdf)" = 12 ]'
prueba "Poppler: pdffonts lista fuentes en un PDF digital" '[ "$(pdffonts doc.pdf | tail -n +3 | wc -l)" -ge 1 ]'
prueba "Poppler: pdffonts no lista fuentes en un PDF escaneado" '[ "$(pdffonts escaneado.pdf | tail -n +3 | wc -l)" -eq 0 ]'
prueba "Poppler: pdftotext -layout extrae el texto" 'pdftotext -layout doc.pdf doc.txt && grep -q presupuesto doc.txt'
prueba "Poppler: pdftoppm rellena con ceros según el total de páginas" 'pdftoppm -png -r 50 doc.pdf rast && [ -s rast-01.png ] && [ -s rast-12.png ]'
prueba "Poppler: -singlefile da un nombre fijo (flujo 7)" 'pdftoppm -png -r 50 -f 1 -l 1 -singlefile doc.pdf control && [ -s control.png ]'
prueba "Poppler: pdftocairo -svg de una página" 'pdftocairo -svg -f 1 -l 1 doc.pdf p1.svg && grep -q "<svg" p1.svg'
prueba "Poppler: pdfimages -list ve una imagen por página escaneada" '[ "$(pdfimages -list escaneado.pdf | tail -n +3 | wc -l)" -eq 2 ]'
prueba "Poppler: pdfseparate y pdfunite" 'pdfseparate -f 3 -l 5 doc.pdf p-%03d.pdf && pdfunite p-003.pdf p-004.pdf unido.pdf && [ "$(paginas unido.pdf)" = 2 ]'
prueba "Poppler: pdfattach y pdfdetach -saveall con la carpeta creada antes" \
    'pdfattach doc.pdf datos.csv con_adjunto.pdf && mkdir -p adjuntos && pdfdetach -saveall -o adjuntos/ con_adjunto.pdf && cmp -s datos.csv adjuntos/datos.csv'

# --- Capítulo 8: img2pdf ------------------------------------------------------
prueba "img2pdf: página A4 con margen" 'img2pdf --pagesize A4 --border 1.5cm foto.jpg -o a4.pdf && pdfinfo a4.pdf | grep -q "A4"'
prueba "img2pdf: --from-file con orden natural" 'cd orden && find . -maxdepth 1 -name "pag*.png" -print0 | sort -zV | img2pdf --from-file - -o natural2.pdf && [ "$(paginas natural2.pdf)" = 3 ]'
prueba "img2pdf: el JPEG se incrusta sin recomprimir" 'img2pdf foto.jpg -o foto.pdf && pdfimages -list foto.pdf | grep -q jpeg'

# --- Capítulo 9: ImageMagick --------------------------------------------------
prueba "ImageMagick: recorte cuadrado con -resize ^ y -extent" 'magick foto.jpg -resize "300x300^" -gravity center -extent 300x300 cuadrada.jpg && [ "$(magick identify -format "%wx%h" cuadrada.jpg)" = 300x300 ]'
prueba "ImageMagick: la política permite leer PDF" 'magick -density 100 "doc.pdf[0]" -background white -alpha remove -alpha off im_p1.png && [ -s im_p1.png ]'
prueba "ImageMagick: mogrify -path deja intacto el original" 'mkdir -p web && cp foto.jpg copia.jpg && h=$(sha256sum copia.jpg) && magick mogrify -path web -resize 50% copia.jpg && [ "$(sha256sum copia.jpg)" = "$h" ] && [ -s web/copia.jpg ]'

# --- Capítulo 10: Potrace -----------------------------------------------------
prueba "Potrace: PNG -> PBM -> SVG" 'magick logo.png -colorspace Gray -threshold 50% logo.pbm && potrace logo.pbm -s -o logo.svg && grep -q "<svg" logo.svg'
prueba "Potrace: PDF vectorial" 'magick logo.png -colorspace Gray -threshold 50% logo.pbm && potrace -b pdf logo.pbm -o logo.pdf && [ "$(paginas logo.pdf)" = 1 ]'
prueba "Potrace: tubería sin archivo intermedio" 'magick logo.png -colorspace Gray -threshold 50% pbm:- | potrace -s -o tuberia.svg && grep -q "<svg" tuberia.svg'
prueba "Potrace: mkbitmap prepara un dibujo en gris" 'magick foto.jpg -colorspace Gray dibujo.pgm && mkbitmap -f 2 -s 2 -t 0.48 dibujo.pgm -o dibujo.pbm && [ -s dibujo.pbm ]'

# --- Capítulo 11: Pandoc ------------------------------------------------------
prueba "Pandoc: Markdown -> DOCX" 'pandoc informe.md -o informe.docx && [ -s informe.docx ]'
prueba "Pandoc: HTML autónomo con --embed-resources" 'pandoc informe.md -s --embed-resources -o informe.html && grep -q "<html" informe.html'
prueba "Pandoc: texto plano conserva las tildes" 'pandoc informe.md -t plain -o informe.txt && grep -q "canción" informe.txt'
prueba "Pandoc 3.7 rechaza --syntax-highlighting (opción de 3.8)" '! pandoc --syntax-highlighting=none informe.md -o x.html 2>/dev/null'
if command -v xelatex >/dev/null && fc-list 2>/dev/null | grep -i "DejaVu Serif" >/dev/null; then
    prueba "Pandoc: archivo de valores por defecto pdf-es.yaml" \
        'printf "from: markdown\nto: pdf\npdf-engine: xelatex\nmetadata:\n  lang: es\nvariables:\n  geometry: margin=2.5cm\n  mainfont: DejaVu Serif\n" > pdf-es.yaml && pandoc -d pdf-es.yaml informe.md -o informe.pdf && pdffonts informe.pdf | grep -q DejaVuSerif'
else
    omitir "Pandoc: archivo de valores por defecto pdf-es.yaml" "requiere xelatex y la fuente DejaVu Serif"
fi

# --- Capítulo 12: QPDF --------------------------------------------------------
prueba "QPDF: --check sin errores" 'qpdf --check doc.pdf >/dev/null'
prueba "QPDF: unir con selección de páginas" 'qpdf --empty --pages doc.pdf 1-3 escaneado.pdf z -- seleccion.pdf && [ "$(paginas seleccion.pdf)" = 4 ]'
prueba "QPDF: quitar la página 2 (1-z,x2)" 'qpdf doc.pdf --pages . 1-z,x2 -- sin_pag2.pdf && [ "$(paginas sin_pag2.pdf)" = 11 ]'
prueba "QPDF: dividir en archivos de una página" 'qpdf --split-pages doc.pdf hoja-%d.pdf && [ "$(find . -maxdepth 1 -name "hoja-*.pdf" | wc -l)" = 12 ]'
prueba "QPDF: cifrar con AES-256 y descifrar" \
    'qpdf --encrypt --user-password=lectura --owner-password=propietario --bits=256 -- doc.pdf cifrado.pdf && qpdf --requires-password cifrado.pdf && qpdf --password=propietario --decrypt cifrado.pdf abierto.pdf && ! qpdf --is-encrypted abierto.pdf'
prueba "QPDF: rotar y numerar páginas" 'qpdf doc.pdf girado.pdf --rotate=+90:1 && qpdf doc.pdf etiquetado.pdf --set-page-labels 1:r 3:D -- && qpdf --check etiquetado.pdf >/dev/null'
prueba "QPDF: linealizar" 'qpdf --linearize doc.pdf web.pdf && qpdf --check-linearization web.pdf >/dev/null'

# --- Capítulo 13: OCRmyPDF ----------------------------------------------------
prueba "OCRmyPDF: OCR en español de un escaneo" 'ocrmypdf -q -l spa escaneado.pdf ocr.pdf && pdffonts ocr.pdf | grep -q GlyphLessFont && pdftotext ocr.pdf - | grep -qi presupuesto'
prueba "OCRmyPDF: código 6 si el PDF ya tiene texto" 'ocrmypdf -q doc.pdf x.pdf; [ $? -eq 6 ]'
prueba "OCRmyPDF: --skip-text en un PDF mixto, con --sidecar" 'qpdf --empty --pages doc.pdf 1 escaneado.pdf 1 -- mixto.pdf && ocrmypdf -q -l spa --skip-text --sidecar mixto.txt mixto.pdf mixto_ocr.pdf && grep -qi presupuesto mixto.txt'
prueba "OCRmyPDF: --output-type pdf" 'ocrmypdf -q -l spa --output-type pdf escaneado.pdf ocr_pdf.pdf && [ -s ocr_pdf.pdf ]'

# --- Capítulo 14: Ghostscript -------------------------------------------------
prueba "Ghostscript: reducir con /ebook" 'gs -q -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -o reducido.pdf escaneado.pdf && qpdf --check reducido.pdf >/dev/null'
prueba "Ghostscript: una imagen por página con %03d" 'gs -q -sDEVICE=png16m -r50 -o gs-%03d.png doc.pdf && [ -s gs-001.png ] && [ -s gs-012.png ]'
prueba "Ghostscript: selección con -sPageList" 'gs -q -sDEVICE=pdfwrite -sPageList=1,3 -o lista.pdf doc.pdf && [ "$(paginas lista.pdf)" = 2 ]'
prueba "Ghostscript: el modo SAFER impide leer /etc/passwd" 'printf "(/etc/passwd) (r) file\n" > leer.ps; gs -q -dNOPAUSE -dBATCH -sDEVICE=nullpage leer.ps 2>&1 | grep -q invalidfileaccess'

echo "1..$total"
echo "# Resultado: $((total - fallos - omitidas)) correctas, $fallos con fallos, $omitidas omitidas"
[ "$fallos" -eq 0 ]
