#!/usr/bin/env bash
# shellcheck disable=SC2016  # el código de cada prueba se pasa entre comillas simples a propósito
# =============================================================================
#  Prueba de humo de la guía
#
#  Ejecuta comandos representativos de cada capítulo sobre archivos sintéticos
#  y comprueba sus resultados con las versiones de Ubuntu 26.04 LTS.
#
#  Uso:  bash tests/smoke.sh     (o bien: make test)
#  Trabaja en una carpeta temporal y no modifica nada fuera de ella, salvo el
#  grupo de Marker, que usa ~/marker-env y su caché (~/.cache/datalab).
#  Salida en formato TAP: "ok N - ..." o "not ok N - ...".
#  Los bloques marcados en la guía con «% prueba: NOMBRE» se leen de allí
#  (funciones bloque y ejecuta); si cambia otro comando, actualice aquí su prueba.
# =============================================================================
set -uo pipefail

GUIA="$(cd "$(dirname "$0")/.." && pwd)/src/guia-herramientas.tex"
export GUIA
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
# Tamaño de la primera página en puntos enteros (rasterizar y volver a PDF redondea décimas).
tamano() { pdfinfo "$1" | awk '/^Page size:/ {printf "%.0f x %.0f\n", $3, $5}'; }
# Anchos de las imágenes de un PDF, en orden de página («10 20 100»).
anchos() { pdfimages -list "$1" | awk 'NR > 2 {print $4}' | paste -sd' '; }
export -f paginas tamano anchos

# bloque NOMBRE: imprime el bloque de la guía cuya línea anterior es «% prueba: NOMBRE».
# Así la prueba ejecuta el texto publicado y no una copia. Falla si no lo encuentra.
bloque() {
    awk -v n="$1" '
        dentro && /^\\end\{lstlisting\}/ { fin = 1; exit }
        dentro { print }
        marca && /^[ \t]*\\begin\{lstlisting\}/ { dentro = 1 }
        { l = $0; sub(/^[ \t]+/, "", l); marca = (l == "% prueba: " n) }
        END { if (!fin) print "No se encuentra el bloque «" n "» en la guía" > "/dev/stderr"; exit !fin }
    ' "$GUIA"
}
# ejecuta NOMBRE: ejecuta el bloque con bash -e, de modo que falla si falla una de sus órdenes
# (no un paso intermedio de una tubería: la prueba comprueba entonces la salida).
ejecuta() { bloque "$1" > "$1.sh" || return 1; bash -e "$1.sh"; }
# bloques DIR: copia cada bloque de órdenes de la guía (lstlisting sin estilo) a DIR/lNNNN.sh,
# donde NNNN es la línea de la guía en la que empieza.
bloques() {
    awk -v d="$1" '
        /^[ \t]*\\begin\{lstlisting\}[ \t]*$/ { f = sprintf("%s/l%04d.sh", d, NR + 1); next }
        /^\\end\{lstlisting\}/ { if (f) close(f); f = ""; next }
        f { print > f }
    ' "$GUIA"
}
export -f bloque ejecuta bloques

for c in pdfinfo pdffonts pdftotext pdftoppm pdftocairo pdfimages pdfseparate pdfunite \
         pdfattach pdfdetach img2pdf magick potrace mkbitmap pandoc qpdf ocrmypdf \
         tesseract gs ps2pdf unpaper latexmk pdflatex; do
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
qpdf --empty --pages doc.pdf 1 escaneado.pdf 1 -- mixto.pdf     # una página digital y otra escaneada
magick -size 400x200 xc:white -fill black -draw 'circle 100,100 100,30' logo.png
magick -size 640x480 gradient:white-'#1f4e79' foto.jpg
mkdir -p orden && for n in 1 2 10; do magick -size "${n}0x50" xc:white "orden/pag$n.png"; done  # anchos 10, 20 y 100
printf 'columna,valor\nuno,1\n' > datos.csv
printf -- '---\ntitle: "Informe de prueba"\nlang: es\n---\n\n# Introducción\n\nTexto con tildes: canción y año.\n' > informe.md
if [ ! -s doc.pdf ] || [ ! -s escaneado.pdf ] || [ ! -s mixto.pdf ]; then
    echo "No se pudieron generar los archivos de ejemplo." >&2
    exit 2
fi

# Las pruebas con «ejecuta» o «bloque» usan el texto de la guía marcado con «% prueba: NOMBRE».
# Cada comprobación va en su propia orden: set -e no se detiene en un fallo dentro de «a && b».

# --- Capítulo 2: Entorno Ubuntu + WSL2 ----------------------------------------
if command -v wslpath >/dev/null; then
    prueba "WSL: wslpath traduce rutas de Windows a Linux y al revés" \
        '[ "$(wslpath "C:\\Users\\NOMBRE\\Downloads")" = /mnt/c/Users/NOMBRE/Downloads ] && w=$(wslpath -w "$HOME") && case $w in "\\\\wsl.localhost\\"*) ;; *) exit 1 ;; esac && [ "$(wslpath -u "$w")" = "$HOME" ]'
else
    omitir "WSL: wslpath traduce rutas de Windows a Linux y al revés" "solo en WSL"
fi

# --- Capítulo 3: Instalación --------------------------------------------------
prueba "Instalación: el script de comprobación general no echa nada en falta" \
    'set -e; s=$(ejecuta comprobacion-general); if grep FALTA <<<"$s"; then exit 1; fi; grep -qx spa <<<"$s"'

# --- Capítulo 5: Bash ---------------------------------------------------------
prueba "Bash: la plantilla lote.sh extrae el texto y se reanuda" '
    set -e
    export HOME="$PWD/casa-lote"
    mkdir -p "$HOME/trabajo/entrada"; cp doc.pdf escaneado.pdf "$HOME/trabajo/entrada/"
    bloque lote.sh > lote.sh
    bash lote.sh > /dev/null
    s="$HOME/trabajo/salida"
    grep -q presupuesto "$s/doc.txt"; [ -e "$s/escaneado.txt" ]; [ ! -e "$s/errores.log" ]
    o=$(bash lote.sh); [ "$(grep -c "^Ya existe, se omite" <<<"$o")" -eq 2 ]'
prueba "Bash: sort -V ordena pag1, pag2, pag10" \
    'cd orden && [ "$(printf "%s\n" pag*.png | sort -V | paste -sd" ")" = "pag1.png pag2.png pag10.png" ]'
prueba "Bash: lista ordenada con mapfile para img2pdf" \
    'cd orden && mapfile -t imgs < <(printf "%s\n" pag*.png | sort -V) && img2pdf "${imgs[@]}" -o natural.pdf && [ "$(anchos natural.pdf)" = "10 20 100" ]'

# --- Capítulo 6: Marker -------------------------------------------------------
# Solo si está el entorno de la guía: una conversión sin OCR, un análisis de opciones y una lectura del
# código de Surya. La vía con modelo de visión no se prueba.
M="$HOME/marker-env/bin/marker_single"
if [ -x "$M" ]; then
    export M
    servidores() { pgrep -f 'marker-env/bin/python.* -m surya\.' | sort; }
    previos=$(servidores)
    prueba "Marker: _meta.json, --page_range desde 0, --paginate_output y servidor auxiliar de Surya" \
        '"$M" doc.pdf --output_dir md --disable_ocr --disable_image_extraction --page_range "0-1" --paginate_output > marker.txt 2>&1 && d=md/doc && [ -s $d/doc_meta.json ] && grep -q "Pagina 2" $d/doc.md && ! grep -q "Pagina 3" $d/doc.md && grep -qx "{0}-\{48\}" $d/doc.md && grep -qx "{1}-\{48\}" $d/doc.md && p=$(pgrep -af "marker-env/bin/python.* -m surya\.") && grep -q "surya.fast_layout.server" <<<"$p"'
    # Marker 2.0.0 deja servidores de Surya en segundo plano al terminar: se detienen los que arrancó la prueba.
    comm -13 <(echo "$previos") <(servidores) | xargs -r kill
    prueba "Marker 2.0.0: --ocr_inline_math sin valor queda en automático al final y da error delante del archivo" \
        '"${M%/*}/python" -I -W ignore -c "from marker.scripts.convert_single import convert_single_cli as c; p = c.make_context(\"marker_single\", [\"doc.pdf\", \"--mode\", \"fast\", \"--ocr_inline_math\"]).params; print(p[\"ocr_inline_math\"], p[\"mode\"])" | grep -qx "None fast" && { "$M" --ocr_inline_math doc.pdf > inline.txt 2>&1; [ $? -eq 2 ]; } && grep -q "Invalid value for .--ocr_inline_math.: .doc.pdf. is not a valid boolean" inline.txt'
    prueba "Marker 2.0.0 (Surya 0.22.1): con llama.cpp, 8 peticiones de 12 288 tokens y su registro" \
        'S=$("${M%/*}/python" -I -c "import importlib.util as u; print(u.find_spec(\"surya\").submodule_search_locations[0])") && grep -q "DEFAULT_PARALLEL = 8$" "$S/inference/backends/llamacpp.py" && grep -q "datalab/surya/llamacpp_server.log" "$S/inference/backends/llamacpp.py" && grep -q "SURYA_INFERENCE_CTX_PER_SLOT: int = 12288$" "$S/settings.py"'
else
    omitir "Marker: _meta.json, --page_range desde 0, --paginate_output y servidor auxiliar de Surya" "requiere ~/marker-env"
    omitir "Marker 2.0.0: --ocr_inline_math sin valor queda en automático al final y da error delante del archivo" "requiere ~/marker-env"
    omitir "Marker 2.0.0 (Surya 0.22.1): con llama.cpp, 8 peticiones de 12 288 tokens y su registro" "requiere ~/marker-env"
fi

# --- Capítulo 7: Poppler ------------------------------------------------------
prueba "Poppler: pdfinfo cuenta 12 páginas" '[ "$(paginas doc.pdf)" = 12 ]'
prueba "Poppler: pdffonts lista fuentes en un PDF digital" '[ "$(pdffonts doc.pdf | tail -n +3 | wc -l)" -ge 1 ]'
prueba "Poppler: pdffonts no lista fuentes en un PDF escaneado" 'f=$(pdffonts escaneado.pdf) && [ "$(tail -n +3 <<<"$f" | wc -l)" -eq 0 ]'
prueba "Poppler: pdftotext -layout extrae el texto" 'pdftotext -layout doc.pdf doc.txt && grep -q presupuesto doc.txt'
prueba "Poppler: pdftoppm rellena con ceros según el total de páginas" 'pdftoppm -png -r 50 doc.pdf rast && [ -s rast-01.png ] && [ -s rast-12.png ]'
prueba "Poppler: -singlefile da un nombre fijo (flujo 7)" 'pdftoppm -png -r 50 -f 1 -l 1 -singlefile doc.pdf control && [ -s control.png ]'
prueba "Poppler: pdftocairo -svg de una página" 'pdftocairo -svg -f 1 -l 1 doc.pdf p1.svg && grep -q "<svg" p1.svg'
prueba "Poppler: pdfimages -list ve una imagen por página escaneada" '[ "$(pdfimages -list escaneado.pdf | tail -n +3 | wc -l)" -eq 2 ]'
prueba "Poppler: pdfseparate y pdfunite" 'pdfseparate -f 3 -l 5 doc.pdf p-%03d.pdf && pdfunite p-003.pdf p-004.pdf unido.pdf && [ "$(paginas unido.pdf)" = 2 ]'
prueba "Poppler: pdfattach y pdfdetach -saveall con la carpeta creada antes" \
    'pdfattach doc.pdf datos.csv con_adjunto.pdf && mkdir -p adjuntos && pdfdetach -saveall -o adjuntos/ con_adjunto.pdf && cmp -s datos.csv adjuntos/datos.csv'
prueba "Poppler: pdfimages -all -p nombra img-PÁGINA-NÚMERO" \
    'mkdir pi && cp escaneado.pdf pi/doc.pdf && cd pi && mkdir -p imagenes && pdfimages -all -p doc.pdf imagenes/img && [ -s imagenes/img-001-000.png ]'
prueba "Poppler: pdftohtml -xml -i crea doc.xml" \
    'mkdir ph && cp doc.pdf ph/ && cd ph && pdftohtml -xml -i doc.pdf doc > /dev/null && [ -s doc.xml ]'
prueba "Poppler: pdfunite sin nombre de salida sobrescribe el último PDF" \
    'mkdir pu && cp doc.pdf pu/a.pdf && cp mixto.pdf pu/b.pdf && cd pu && pdfunite a.pdf b.pdf && [ "$(paginas b.pdf)" = 12 ]'

# --- Capítulo 8: img2pdf ------------------------------------------------------
prueba "img2pdf: página A4 con margen" 'img2pdf --pagesize A4 --border 1.5cm foto.jpg -o a4.pdf && pdfinfo a4.pdf | grep -q "A4"'
prueba "img2pdf: --from-file con orden natural" 'cd orden && find . -maxdepth 1 -name "pag*.png" -print0 | sort -zV | img2pdf --from-file - -o natural2.pdf && [ "$(anchos natural2.pdf)" = "10 20 100" ]'
prueba "img2pdf: el JPEG se incrusta sin recomprimir" 'img2pdf foto.jpg -o foto.pdf && pdfimages -list foto.pdf | grep -q jpeg'
prueba "img2pdf: un PNG con alfa se guarda con una máscara aparte (smask)" \
    'magick -size 60x60 xc:none -fill red -draw "circle 30,30 30,5" alfa.png && img2pdf alfa.png -o alfa.pdf 2>/dev/null && pdfimages -list alfa.pdf | grep -q smask'
prueba "img2pdf: sin imágenes en la orden espera la entrada estándar" \
    'timeout 1 img2pdf -o vacio.pdf < <(sleep 3 2>/dev/null) > espera.txt 2>&1; [ $? -eq 124 ] && grep -qF "Reading image from standard input..." espera.txt'

# --- Capítulo 9: ImageMagick --------------------------------------------------
prueba "ImageMagick: recorte cuadrado con -resize ^ y -extent" 'magick foto.jpg -resize "300x300^" -gravity center -extent 300x300 cuadrada.jpg && [ "$(magick identify -format "%wx%h" cuadrada.jpg)" = 300x300 ]'
prueba "ImageMagick: la política permite leer PDF" 'magick -density 100 "doc.pdf[0]" -background white -alpha remove -alpha off im_p1.png && [ -s im_p1.png ]'
prueba "ImageMagick: mogrify -path deja intacto el original" 'mkdir -p web && cp foto.jpg copia.jpg && h=$(sha256sum copia.jpg) && magick mogrify -path web -resize 50% copia.jpg && [ "$(sha256sum copia.jpg)" = "$h" ] && [ -s web/copia.jpg ]'
prueba "ImageMagick: -crop 2x2@ genera de pieza_00 a pieza_03" \
    'mkdir ic && magick foto.jpg ic/plano.png && cd ic && magick plano.png -crop 2x2@ +repage pieza_%02d.png && [ -s pieza_00.png ] && [ -s pieza_03.png ] && [ ! -e pieza_04.png ]'
prueba "ImageMagick: \"doc.pdf[0-2]\" numera las salidas desde 0" \
    'mkdir ir && cp doc.pdf ir/ && cd ir && magick -density 150 "doc.pdf[0-2]" -background white -alpha remove -quality 85 pag-%02d.jpg && [ -s pag-00.jpg ] && [ -s pag-02.jpg ] && [ ! -e pag-03.jpg ]'
prueba "ImageMagick: límites y patrones bloqueados de la política de Ubuntu" \
    'p=$(magick -list policy | awk "/name:/ {n = \$2} /value:/ {print n, \$2} /pattern:/ {print \"patrón\", \$2}") && for e in "memory 1024MiB" "map 2048MiB" "disk 2GiB" "area 256MP" "width 32KP" "height 32KP" "patrón @*" "patrón URL" "patrón HTTP" "patrón HTTPS"; do grep -qxF "$e" <<<"$p" || exit 1; done && r=$(magick -list policy | grep "rights:") && ! grep -qv None <<<"$r"'
prueba "ImageMagick: convert funciona sin aviso de obsolescencia" \
    'o=$(convert logo.png convert.png 2>&1) && [ -z "$o" ] && [ -s convert.png ]'

# --- Capítulo 10: Potrace -----------------------------------------------------
prueba "Potrace: PNG -> PBM -> SVG" 'magick logo.png -colorspace Gray -threshold 50% logo.pbm && potrace logo.pbm -s -o logo.svg && grep -q "<svg" logo.svg'
prueba "Potrace: PDF vectorial" 'magick logo.png -colorspace Gray -threshold 50% logo.pbm && potrace -b pdf logo.pbm -o logo.pdf && [ "$(paginas logo.pdf)" = 1 ]'
prueba "Potrace: tubería sin archivo intermedio" 'magick logo.png -colorspace Gray -threshold 50% pbm:- | potrace -s -o tuberia.svg && grep -q "<svg" tuberia.svg'
prueba "Potrace: mkbitmap prepara un dibujo en gris" 'magick foto.jpg -colorspace Gray dibujo.pgm && mkbitmap -f 2 -s 2 -t 0.48 dibujo.pgm -o dibujo.pbm && [ -s dibujo.pbm ]'
prueba "Potrace: un PNG da «file format not recognized» y código 2" \
    'potrace logo.png -o no.svg > potrace.txt 2>&1; [ $? -eq 2 ] && grep -q "file format not recognized" potrace.txt'
prueba "Potrace: pdfpage usa papel letter por defecto" \
    'magick logo.png -colorspace Gray -threshold 50% pagina.pbm && potrace -b pdfpage pagina.pbm -o pagina.pdf && pdfinfo pagina.pdf | grep -q "(letter)"'
prueba "Potrace: PGM y PPM de entrada, PGM de salida con -g y sin motor ppm" \
    'magick logo.png logo.pgm && magick logo.png logo.ppm && potrace logo.pgm -s -o pgm.svg && potrace logo.ppm -s -o ppm.svg && grep -q "<svg" pgm.svg && magick logo.png -colorspace Gray -threshold 50% g.pbm && potrace -g g.pbm -o g.pgm && [ "$(head -c 2 g.pgm)" = P5 ] && { potrace -b ppm g.pbm -o x.ppm > ppm.txt 2>&1; [ $? -eq 1 ]; } && grep -q "unrecognized backend" ppm.txt'

# --- Capítulo 11: Pandoc ------------------------------------------------------
prueba "Pandoc: Markdown -> DOCX" 'pandoc informe.md -o informe.docx && [ -s informe.docx ]'
prueba "Pandoc: HTML autónomo con --embed-resources" 'pandoc informe.md -s --embed-resources -o informe.html && grep -q "<html" informe.html'
prueba "Pandoc: texto plano conserva las tildes" 'pandoc informe.md -t plain -o informe.txt && grep -q "canción" informe.txt'
prueba "Pandoc 3.7 rechaza --syntax-highlighting (opción de 3.8) con código 6" \
    'pandoc --syntax-highlighting=none informe.md -o x.html 2>/dev/null; [ $? -eq 6 ]'
prueba "Pandoc 3.7 rechaza --math-method (opción de 3.11) con código 6" \
    'pandoc --math-method=mathml informe.md -o x.html 2>/dev/null; [ $? -eq 6 ]'
if command -v xelatex >/dev/null && fc-list 2>/dev/null | grep -i "DejaVu Serif" >/dev/null; then
    prueba "Pandoc: archivo de valores por defecto pdf-es.yaml" \
        'set -e; mkdir yaml; cp informe.md yaml/; cd yaml; ejecuta pdf-es.yaml; pdffonts informe.pdf | grep -q DejaVuSerif'
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
prueba "QPDF: --split-pages rellena con ceros y --split-pages=10 hace bloques" \
    'mkdir qs && cp doc.pdf qs/ && cd qs && qpdf --split-pages doc.pdf pag-%d.pdf && [ -s pag-01.pdf ] && [ -s pag-12.pdf ] && qpdf --split-pages=10 doc.pdf bloque.pdf && [ "$(paginas bloque-01-10.pdf)" = 10 ] && [ "$(paginas bloque-11-12.pdf)" = 2 ]'
prueba "QPDF: --collate con z-1 intercala anversos y reversos invertidos" \
    'p() { { echo "%!PS"; for i in 1 2 3; do echo "/Helvetica findfont 40 scalefont setfont 72 700 moveto ($1$i) show showpage"; done; } | ps2pdf - "$2"; } && p A anversos.pdf && p B reversos.pdf && qpdf --collate --empty --pages anversos.pdf reversos.pdf z-1 -- completo.pdf && [ "$(pdftotext completo.pdf - | tr -d "\f" | grep . | paste -sd" ")" = "A1 B3 A2 B2 A3 B1" ]'
prueba "QPDF: reparar un startxref roto da código 3 y un PDF sin errores" \
    'LC_ALL=C sed "/^startxref/{n;s/.*/999999/}" doc.pdf > roto.pdf && { qpdf roto.pdf reparado.pdf 2>/dev/null; [ $? -eq 3 ]; } && qpdf --check reparado.pdf > /dev/null'
prueba "QPDF: --requires-password (3 sin contraseña de apertura, 2 sin cifrar) e --is-encrypted (0 y 2)" \
    'qpdf --encrypt --owner-password=propietario --bits=256 -- doc.pdf permisos.pdf && { qpdf --requires-password permisos.pdf; [ $? -eq 3 ]; } && { qpdf --requires-password doc.pdf; [ $? -eq 2 ]; } && qpdf --is-encrypted permisos.pdf && { qpdf --is-encrypted doc.pdf; [ $? -eq 2 ]; }'
prueba "QPDF: la misma ruta como entrada y salida da código 2 y el mensaje de la guía" \
    'cp doc.pdf misma.pdf && { qpdf misma.pdf misma.pdf > misma.txt 2>&1; [ $? -eq 2 ]; } && grep -q "input file and output file are the same" misma.txt'

# --- Capítulo 13: OCRmyPDF ----------------------------------------------------
prueba "OCRmyPDF: OCR en español de un escaneo, en PDF/A-2b por defecto" 'ocrmypdf -q -l spa escaneado.pdf ocr.pdf && pdffonts ocr.pdf | grep -q GlyphLessFont && pdftotext ocr.pdf - | grep -qi presupuesto && m=$(pdfinfo -meta ocr.pdf) && grep -q "pdfaid:part=\"2\"" <<<"$m" && grep -q "pdfaid:conformance=\"B\"" <<<"$m"'
prueba "OCRmyPDF: código 6 si el PDF ya tiene texto" 'ocrmypdf -q doc.pdf x.pdf; [ $? -eq 6 ]'
prueba "OCRmyPDF: --skip-text en un PDF mixto, con --sidecar" 'ocrmypdf -q -l spa --skip-text --sidecar mixto.txt mixto.pdf mixto_ocr.pdf && grep -qi presupuesto mixto.txt && grep -qF "[OCR skipped on page(s) 1]" mixto.txt'
prueba "OCRmyPDF: --output-type pdf no crea un PDF/A" 'ocrmypdf -q -l spa --output-type pdf escaneado.pdf ocr_pdf.pdf && m=$(pdfinfo -meta ocr_pdf.pdf) && ! grep -q pdfaid <<<"$m"'
prueba "OCRmyPDF 16.13: con --rotate-pages y poco texto avisa «Too few characters», pero hace el OCR" \
    'ocrmypdf -l spa --rotate-pages escaneado.pdf rotar.pdf > rotar.txt 2>&1 && grep -qF "[tesseract] Too few characters. Skipping this page" rotar.txt && grep -qF "Error during processing." rotar.txt && grep -qF "confidence 0.00 - no change" rotar.txt && [ "$(pdftotext rotar.pdf - | grep -io presupuesto | wc -l)" -eq 2 ]'
prueba "OCRmyPDF: un PDF cifrado termina con código 8" \
    'qpdf --encrypt --user-password=lectura --owner-password=propietario --bits=256 -- escaneado.pdf ocr_cifrado.pdf && { ocrmypdf -q ocr_cifrado.pdf x8.pdf 2>/dev/null; [ $? -eq 8 ]; }'
prueba "OCRmyPDF 16.13: --remove-background no está implementada y termina con código 15" \
    'ocrmypdf -q --remove-background escaneado.pdf x15.pdf > x15.txt 2>&1; [ $? -eq 15 ] && grep -q "remove-background is temporarily not implemented" x15.txt'

# --- Capítulo 14: Ghostscript -------------------------------------------------
prueba "Ghostscript: reducir con /ebook" 'gs -q -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -o reducido.pdf escaneado.pdf && qpdf --check reducido.pdf >/dev/null'
prueba "Ghostscript: una imagen por página con %03d" 'gs -q -sDEVICE=png16m -r50 -o gs-%03d.png doc.pdf && [ -s gs-001.png ] && [ -s gs-012.png ]'
prueba "Ghostscript: selección con -sPageList" 'gs -q -sDEVICE=pdfwrite -sPageList=1,3 -o lista.pdf doc.pdf && [ "$(paginas lista.pdf)" = 2 ]'
prueba "Ghostscript: el modo SAFER impide leer /etc/passwd" 'printf "(/etc/passwd) (r) file\n" > leer.ps; gs -q -dNOPAUSE -dBATCH -sDEVICE=nullpage leer.ps 2>&1 | grep -q invalidfileaccess'
prueba "Ghostscript: tiffg4 crea un TIFF multipágina" \
    'gs -q -sDEVICE=tiffg4 -r300 -o fax.tif escaneado.pdf && [ "$(magick identify fax.tif | wc -l)" = 2 ]'
prueba "Ghostscript: -sPageList=odd y 10- (de 12 páginas, 6 y 3)" \
    'gs -q -sDEVICE=pdfwrite -sPageList=odd -o impares.pdf doc.pdf && gs -q -sDEVICE=pdfwrite -sPageList=10- -o finales.pdf doc.pdf && [ "$(paginas impares.pdf)" = 6 ] && [ "$(paginas finales.pdf)" = 3 ]'
prueba "Ghostscript: sin marcador %d, todas las páginas van a un único PNG, del que se lee solo la primera" \
    'gs -q -sDEVICE=png16m -r20 -o una.png doc.pdf && [ "$(LC_ALL=C grep -aoP "\x89PNG\r" una.png | wc -l)" = 12 ] && [ "$(magick identify una.png | wc -l)" = 1 ]'

# --- Capítulo 17: Flujos de trabajo -------------------------------------------
# Cada flujo trabaja en su carpeta, con copias de los archivos de ejemplo que espera.
prueba "Flujo 3: PDF a imágenes, retoque y de nuevo a PDF (2 páginas)" \
    'set -e; mkdir f3; cp mixto.pdf f3/doc.pdf; cd f3; ejecuta flujo3
     [ "$(paginas doc_procesado.pdf)" = 2 ]
     t=$(tamano doc.pdf); [ -n "$t" ]; [ "$t" = "$(tamano doc_procesado.pdf)" ]'
prueba "Flujo 4: imagen a vector (SVG y PDF)" \
    'set -e; mkdir f4; cp logo.png f4/; cd f4; ejecuta flujo4; grep -q "<svg" logo.svg; [ "$(paginas logo.pdf)" = 1 ]'
prueba "Flujo 5: Markdown a PDF por la vía directa y por la controlada" \
    'set -e; mkdir f5; cp informe.md f5/; cd f5; ejecuta flujo5 > /dev/null; [ -s informe.tex ]; pdftotext informe.pdf - | grep -q "Informe de prueba"'
prueba "Flujo 6: diagnóstico y estrategias de optimización" \
    'set -e; mkdir f6; cp doc.pdf f6/; cd f6; d=$(ejecuta flujo6-diagnostico); ejecuta flujo6-estrategias > /dev/null
     grep -q "^Pages:" <<<"$d"; grep -q "^page" <<<"$d"; grep -q "^name" <<<"$d"; [ -s op_qpdf.pdf ]; qpdf --check-linearization op_gs_web.pdf > /dev/null'
prueba "Flujo 8: fotos a PDF A4 con OCR, limpieza y optimización" \
    'set -e; mkdir -p f8/escaneos; magick sc-01.png f8/escaneos/a.jpg; magick sc-02.png f8/escaneos/b.jpg; cd f8
     ejecuta flujo8 > /dev/null; grep -qi presupuesto escaneo.txt; pdfinfo escaneo.pdf | grep -q A4'
prueba "Flujo 9: PDF escaneado a imágenes, limpieza y OCR" \
    'set -e; mkdir f9; cp escaneado.pdf f9/; cd f9; ejecuta flujo9
     [ "$(paginas limpio_ocr.pdf)" = 2 ]; pdftotext limpio_ocr.pdf - | grep -qi presupuesto'
prueba "Flujo 10: masivo.sh hace OCR de las páginas escaneadas de un PDF mixto, no toca los originales y se reanuda" '
    set -e
    export HOME="$PWD/casa-masivo"
    e="$HOME/trabajo/entrada"
    mkdir -p "$e" && cp doc.pdf escaneado.pdf mixto.pdf "$e/"
    h=$(cat "$e"/*.pdf | sha256sum)
    bloque masivo.sh > masivo.sh
    bash masivo.sh > /dev/null
    s="$HOME/trabajo/salida"
    n=$(grep -io presupuesto "$s/txt/mixto.txt" | wc -l); echo "«presupuesto» en mixto.txt: $n"; [ "$n" -eq 2 ]
    grep -qi presupuesto "$s/txt/escaneado.txt"; grep -qi presupuesto "$s/txt/doc.txt"
    if grep -Eqs "ERROR (ocrmypdf|pdftotext)" "$s/registro.log"; then exit 1; fi
    f=$(pdffonts "$s/pdf/doc.pdf"); if grep -q GlyphLessFont <<<"$f"; then echo "OCR añadido a un PDF digital"; exit 1; fi
    m=$(pdfinfo -meta "$s/pdf/escaneado.pdf"); if grep -q pdfaid <<<"$m"; then echo "PDF/A con --output-type pdf"; exit 1; fi
    [ "$(cat "$e"/*.pdf | sha256sum)" = "$h" ]
    o=$(bash masivo.sh); [ "$(grep -c "^Omitido" <<<"$o")" -eq 3 ]'

# --- Toda la guía -------------------------------------------------------------
# Exclusiones propias de órdenes que se escriben en la terminal, no de scripts: SC1090 y SC1091
# (source de una ruta variable), SC2035 (comodín que podría empezar por -) y SC2164 (cd sin || exit).
if command -v shellcheck >/dev/null; then
    prueba "Guía: shellcheck no encuentra problemas en los bloques de órdenes" \
        'mkdir sc && bloques sc && [ "$(find sc -name "*.sh" | wc -l)" -ge 100 ] && shellcheck -f gcc -s bash -e SC1090,SC1091,SC2035,SC2164 sc/*.sh'
else
    omitir "Guía: shellcheck no encuentra problemas en los bloques de órdenes" "requiere shellcheck"
fi

echo "1..$total"
echo "# Resultado: $((total - fallos - omitidas)) correctas, $fallos con fallos, $omitidas omitidas"
[ "$fallos" -eq 0 ]
