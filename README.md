# dylongou — sitio personal

Esta es la versión inicial del sitio estático con un fondo estilo "galaxy", una foto central y enlaces.

Instrucciones rápidas para ponerlo en marcha localmente:

1. Abrir una terminal en `C:\dev\dylongou`.
2. Inicializar git, hacer commit y conectar el remoto:

```bash
git init
git add .
git commit -m "Initial commit: sitio estático"
git remote add origin https://github.com/lildarkieeeee/dylongou.git
git branch -M main
git push -u origin main
```

3. Reemplaza la imagen de `assets/me.svg` por tu foto (`assets/me.jpg` o `me.png`) y actualiza los enlaces en `index.html`.

4. Para desplegar en GitHub Pages: en el repo Settings → Pages → seleccionar rama `main` y carpeta `/ (root)`.
