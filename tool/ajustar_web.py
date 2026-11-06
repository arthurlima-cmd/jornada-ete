#!/usr/bin/env python3
"""Ajusta a pasta web/ criada pelo `flutter create --platforms=web`:
- título, descrição, cor e idioma da página
- manifest.json do app instalável (PWA): nome, cores e ícones
- ícones e favicon com o logotipo ETEADC (tool/icone/web/)
"""
import json
import os
import re
import shutil

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(RAIZ, "web")
NOME = "Jornada ETEADC"
DESCRICAO = "Rotina escolar da ETE Antônio Dourado Cavalcanti: horários, provas, avisos e agenda."
AZUL = "#091540"

# ---------------------------------------------------------------- index.html
indice = os.path.join(WEB, "index.html")
with open(indice, encoding="utf-8") as f:
    h = f.read()
h = re.sub(r"<html[^>]*>", '<html lang="pt-BR">', h, count=1)
h = re.sub(r"<title>.*?</title>", f"<title>{NOME}</title>", h, count=1, flags=re.S)
h = re.sub(r'(<meta name="description" content=")[^"]*(")', rf"\g<1>{DESCRICAO}\g<2>", h, count=1)
h = re.sub(r'(<meta name="apple-mobile-web-app-title" content=")[^"]*(")', rf"\g<1>{NOME}\g<2>", h, count=1)
if 'name="theme-color"' not in h:
    h = h.replace("</head>", f'  <meta name="theme-color" content="{AZUL}">\n</head>', 1)
with open(indice, "w", encoding="utf-8") as f:
    f.write(h)
print("index.html ajustado")

# ------------------------------------------------------------- manifest.json
manifesto = os.path.join(WEB, "manifest.json")
with open(manifesto, encoding="utf-8") as f:
    m = json.load(f)
m.update({
    "name": NOME,
    "short_name": NOME,
    "description": DESCRICAO,
    "lang": "pt-BR",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#FFFFFF",
    "theme_color": AZUL,
    "orientation": "portrait-primary",
})
with open(manifesto, "w", encoding="utf-8") as f:
    json.dump(m, f, ensure_ascii=False, indent=2)
print("manifest.json ajustado")

# -------------------------------------------------------------------- ícones
origem = os.path.join(RAIZ, "tool", "icone", "web")
os.makedirs(os.path.join(WEB, "icons"), exist_ok=True)
for nome in os.listdir(origem):
    destino = os.path.join(WEB, "favicon.png" if nome == "favicon.png" else os.path.join("icons", nome))
    shutil.copyfile(os.path.join(origem, nome), destino)
print("Ícones e favicon com o logotipo ETEADC")
