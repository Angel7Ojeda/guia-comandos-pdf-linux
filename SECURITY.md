# Política de seguridad

Este proyecto es documentación, pero sus comandos se ejecutan en equipos reales. Se consideran problemas de seguridad:

- un comando que pueda borrar o sobrescribir datos sin que la guía lo advierta;
- un consejo que debilite las protecciones del sistema (por ejemplo, desactivar `-dSAFER` en Ghostscript o relajar `policy.xml` en ImageMagick) sin explicar el riesgo;
- un ejemplo que exponga datos personales o credenciales.

## Cómo informar

Si el repositorio tiene activada la notificación privada de vulnerabilidades, use la pestaña **Security** y el botón **Report a vulnerability**. Si no está activada, abra un *issue* con una descripción general, sin los detalles que permitirían aprovechar el problema, y el resto se coordinará en privado.

## Versiones con soporte

Solo la última versión publicada de la guía recibe correcciones.

Los fallos de las propias herramientas (Ghostscript, Poppler, ImageMagick y las demás) deben comunicarse a sus proyectos; la sección «Documentación oficial de referencia» de la guía enlaza a cada uno.
