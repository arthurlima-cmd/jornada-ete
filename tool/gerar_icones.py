#!/usr/bin/env python3
"""Gera os ícones Android do app a partir de tool/icone/logotipo_eteadc_trans.png.

Saída em tool/icone/res/ (copiada para android/app/src/main/res pelo
tool/ajustar_android.py durante o build):
  mipmap-*/ic_launcher.png            ícone clássico (logo sobre fundo branco)
  drawable-*/ic_launcher_foreground.png  camada da frente do ícone adaptativo
  mipmap-anydpi-v26/ic_launcher.xml   ícone adaptativo (Android 8+)
  values/ic_launcher_background.xml   cor de fundo (branco)

Rode de novo só se trocar o logotipo:  python3 tool/gerar_icones.py
Requer Pillow (pip install pillow).
"""
import os

from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "tool", "icone", "logotipo_eteadc_trans.png")
SAIDA = os.path.join(RAIZ, "tool", "icone", "res")

DENSIDADES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}

logo = Image.open(ORIGEM).convert("RGBA")
logo = logo.crop(logo.getchannel("A").getbbox())


def centralizar(canvas_px: int, ocupacao: float, fundo) -> Image.Image:
    """Logo centralizado ocupando `ocupacao` do lado do quadrado."""
    img = Image.new("RGBA", (canvas_px, canvas_px), fundo)
    lado = canvas_px * ocupacao
    escala = min(lado / logo.width, lado / logo.height)
    w, h = round(logo.width * escala), round(logo.height * escala)
    l = logo.resize((w, h), Image.LANCZOS)
    img.alpha_composite(l, ((canvas_px - w) // 2, (canvas_px - h) // 2))
    return img


def arredondar(img: Image.Image, raio_frac: float) -> Image.Image:
    mascara = Image.new("L", img.size, 0)
    r = round(img.width * raio_frac)
    ImageDraw.Draw(mascara).rounded_rectangle((0, 0, img.width - 1, img.height - 1), r, fill=255)
    saida = Image.new("RGBA", img.size, (0, 0, 0, 0))
    saida.paste(img, (0, 0), mascara)
    return saida


for nome, fator in DENSIDADES.items():
    # Ícone clássico: 48 dp, fundo branco com cantos arredondados.
    px = round(48 * fator)
    classico = arredondar(centralizar(px, 0.86, (255, 255, 255, 255)), 0.18)
    pasta = os.path.join(SAIDA, f"mipmap-{nome}")
    os.makedirs(pasta, exist_ok=True)
    classico.save(os.path.join(pasta, "ic_launcher.png"), optimize=True)

    # Ícone adaptativo: 108 dp; o logo fica na zona segura central (66%).
    px = round(108 * fator)
    frente = centralizar(px, 0.62, (0, 0, 0, 0))
    pasta = os.path.join(SAIDA, f"drawable-{nome}")
    os.makedirs(pasta, exist_ok=True)
    frente.save(os.path.join(pasta, "ic_launcher_foreground.png"), optimize=True)

os.makedirs(os.path.join(SAIDA, "mipmap-anydpi-v26"), exist_ok=True)
with open(os.path.join(SAIDA, "mipmap-anydpi-v26", "ic_launcher.xml"), "w", encoding="utf-8") as f:
    f.write(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )

os.makedirs(os.path.join(SAIDA, "values"), exist_ok=True)
with open(os.path.join(SAIDA, "values", "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
    f.write(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#FFFFFF</color>\n'
        "</resources>\n"
    )


pass
print("Ícones gerados em", SAIDA)

# ------------------------------------------------------------------- iOS
# AppIcon.appiconset completo (sem transparência, como a Apple exige),
# copiado para ios/Runner/Assets.xcassets pelo tool/ajustar_ios.py.
import json

IOS = os.path.join(RAIZ, "tool", "icone", "ios", "AppIcon.appiconset")
os.makedirs(IOS, exist_ok=True)
ICONES_IOS = [  # (idioma, tamanho em pt, escala)
    ("iphone", 20, 2), ("iphone", 20, 3), ("iphone", 29, 1), ("iphone", 29, 2),
    ("iphone", 29, 3), ("iphone", 40, 2), ("iphone", 40, 3), ("iphone", 60, 2),
    ("iphone", 60, 3), ("ipad", 20, 1), ("ipad", 20, 2), ("ipad", 29, 1),
    ("ipad", 29, 2), ("ipad", 40, 1), ("ipad", 40, 2), ("ipad", 76, 1),
    ("ipad", 76, 2), ("ipad", 83.5, 2), ("ios-marketing", 1024, 1),
]
imagens = []
for idioma, pt, esc in ICONES_IOS:
    px = round(pt * esc)
    nome_pt = f"{pt:g}"
    arquivo = f"Icon-App-{nome_pt}x{nome_pt}@{esc}x.png"
    caminho = os.path.join(IOS, arquivo)
    if not os.path.exists(caminho):
        centralizar(px, 0.82, (255, 255, 255, 255)).convert("RGB").save(caminho, optimize=True)
    imagens.append({"size": f"{nome_pt}x{nome_pt}", "idiom": idioma,
                    "filename": arquivo, "scale": f"{esc}x"})
with open(os.path.join(IOS, "Contents.json"), "w", encoding="utf-8") as f:
    json.dump({"images": imagens, "info": {"version": 1, "author": "xcode"}}, f, indent=2)
print("Ícones iOS gerados em", IOS)

# ------------------------------------------------------ ícone de notificação
# Android exige ícone pequeno branco e transparente (24 dp): "ETE" em negrito.
from PIL import ImageFont

FONTE = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
for nome, fator in DENSIDADES.items():
    px = round(24 * fator)
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    tamanho = px
    while True:
        f = ImageFont.truetype(FONTE, tamanho)
        x0, y0, x1, y1 = d.textbbox((0, 0), "ETE", font=f)
        if x1 - x0 <= px * 0.92 or tamanho < 4:
            break
        tamanho -= 1
    d.text(((px - (x1 - x0)) / 2 - x0, (px - (y1 - y0)) / 2 - y0), "ETE",
           font=f, fill=(255, 255, 255, 255))
    pasta = os.path.join(SAIDA, f"drawable-{nome}")
    os.makedirs(pasta, exist_ok=True)
    img.save(os.path.join(pasta, "ic_stat_notificacao.png"), optimize=True)

with open(os.path.join(SAIDA, "values", "cores_notificacao.xml"), "w", encoding="utf-8") as f:
    f.write(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="cor_notificacao">#091540</color>\n'
        "</resources>\n"
    )
print("Ícone de notificação gerado")
