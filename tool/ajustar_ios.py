#!/usr/bin/env python3
"""Ajusta a pasta ios/ criada pelo `flutter create`:
- bundle id (deve ser o mesmo do app iOS registrado no Firebase)
- iOS mínimo 15.0 (exigido pelo Firebase)
- nome exibido "Jornada ETEADC" e esquemas tel/mailto/https (url_launcher)
- ícone do app (gerado por tool/gerar_icones.py)

Uso: python3 tool/ajustar_ios.py <bundle_id>
"""
import os
import plistlib
import re
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bundle = sys.argv[1]
IOS = os.path.join(RAIZ, "ios")

# ------------------------------------------------------------ project.pbxproj
pbx = os.path.join(IOS, "Runner.xcodeproj", "project.pbxproj")
with open(pbx, encoding="utf-8") as f:
    t = f.read()
t = re.sub(r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;", "IPHONEOS_DEPLOYMENT_TARGET = 15.0;", t)
# Troca o bundle do Runner (e mantém o sufixo .RunnerTests dos testes).
t, n = re.subn(r"PRODUCT_BUNDLE_IDENTIFIER = [A-Za-z0-9.\-]+?(\.RunnerTests)?;",
               lambda m: f"PRODUCT_BUNDLE_IDENTIFIER = {bundle}{m.group(1) or ''};", t)
with open(pbx, "w", encoding="utf-8") as f:
    f.write(t)
print(f"project.pbxproj: bundle={bundle} ({n} ocorrências), iOS mínimo 15.0")

# -------------------------------------------------------------------- Podfile
podfile = os.path.join(IOS, "Podfile")
if os.path.exists(podfile):
    with open(podfile, encoding="utf-8") as f:
        p = f.read()
    p, n = re.subn(r"^#?\s*platform :ios, '[0-9.]+'", "platform :ios, '15.0'", p, flags=re.M)
    if n == 0:
        p = "platform :ios, '15.0'\n" + p
    with open(podfile, "w", encoding="utf-8") as f:
        f.write(p)
    print("Podfile: platform :ios, '15.0'")

# ----------------------------------------------------------------- Info.plist
info = os.path.join(IOS, "Runner", "Info.plist")
with open(info, "rb") as f:
    pl = plistlib.load(f)
pl["CFBundleDisplayName"] = "Jornada ETEADC"
pl["CFBundleName"] = "Jornada ETEADC"
esquemas = set(pl.get("LSApplicationQueriesSchemes", []))
esquemas.update(["tel", "mailto", "https", "whatsapp"])
pl["LSApplicationQueriesSchemes"] = sorted(esquemas)
with open(info, "wb") as f:
    plistlib.dump(pl, f)
print("Info.plist: nome 'Jornada ETEADC' e esquemas de link")

# ------------------------------------------------------------------- ícone
origem = os.path.join(RAIZ, "tool", "icone", "ios", "AppIcon.appiconset")
destino = os.path.join(IOS, "Runner", "Assets.xcassets", "AppIcon.appiconset")
if os.path.isdir(origem):
    shutil.rmtree(destino, ignore_errors=True)
    shutil.copytree(origem, destino)
    print("Ícone do app substituído pelo logotipo ETEADC")
else:
    print("AVISO: tool/icone/ios não encontrado; mantendo o ícone padrão")
