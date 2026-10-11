# Órdenes habituales del proyecto (ver README.md):
#   make           compila la guía en build/guia-herramientas.pdf
#   make test      ejecuta la prueba de humo de los comandos de la guía
#   make clean     borra los archivos auxiliares de LaTeX (conserva el PDF)
#   make distclean borra la carpeta build/ completa

SRC := src/guia-herramientas.tex

.PHONY: all pdf test clean distclean

all: pdf

pdf:
	latexmk $(SRC)

test:
	bash tests/smoke.sh

clean:
	latexmk -c $(SRC)

distclean:
	rm -rf build
