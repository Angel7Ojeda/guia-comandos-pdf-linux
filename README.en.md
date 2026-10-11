# Linux command-line guide for PDF, images and documents (in Spanish)

[![Build and test](../../actions/workflows/compilar.yml/badge.svg)](../../actions/workflows/compilar.yml)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-lightgrey.svg)](LICENSE)

This repository contains a **Spanish-language** reference manual (118 pages, written in LaTeX) for working from the terminal of **Ubuntu 26.04 LTS on WSL2** (Windows 11) with nine open-source tools: Marker, Poppler, img2pdf, ImageMagick, Potrace, Pandoc, QPDF, OCRmyPDF and Ghostscript.

**[Download the latest PDF](../../releases/latest/download/guia-comandos-pdf-linux.pdf)** · [All releases](../../releases) · [Versión en español](README.md)

## What it covers

Each tool has a chapter with the same structure: purpose and when to use it, installation, syntax and options, copy-ready examples, supported formats, limitations and common errors. The guide also compares the tools, includes a matrix of PDF operations, ten workflows that combine several tools, and notes specific to WSL2 (Windows paths, performance, memory, file names with spaces).

## How it is verified

The commands were tested against the exact package versions shipped by Ubuntu 26.04. On every change, a GitHub Actions workflow builds the PDF and runs a smoke test with 42 checks inside an `ubuntu:26.04` container. Tagged versions are published automatically with the PDF and its SHA-256 checksum. The audit report is in [`docs/auditoria.md`](docs/auditoria.md) (Spanish).

## Building

```bash
sudo apt install make latexmk texlive-latex-recommended texlive-latex-extra \
    texlive-fonts-recommended texlive-lang-spanish lmodern
make          # builds build/guia-herramientas.pdf
make test     # smoke test (requires the tools described in the guide)
```

## Language

The guide is written in Spanish, and there is no full English translation: keeping two 118-page versions in sync would make them drift apart. Issues and pull requests in English are welcome.

## License

The guide and its documentation are licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/): they may be shared and adapted for non-commercial purposes, with attribution, under the same license. **Selling copies or any other commercial use requires the author's prior written permission.** The code (Makefile, latexmkrc, tests and workflows) is MIT-licensed. Both license texts are in [LICENSE](LICENSE). Author: Angel David Ojeda Peralta.
