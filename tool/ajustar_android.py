#!/usr/bin/env python3
"""Ajusta a pasta android/ criada pelo `flutter create`:
- applicationId igual ao pacote registrado no Firebase
- minSdk 23 (exigido pelo Firebase Auth)
- nome do app e permissão de internet no AndroidManifest

Uso: python3 tool/ajustar_android.py <pacote>
"""
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pacote = sys.argv[1]

# ---------------------------------------------------------------- build.gradle
gradle = None
for nome in ("build.gradle.kts", "build.gradle"):
    caminho = os.path.join(RAIZ, "android", "app", nome)
    if os.path.exists(caminho):
        gradle = caminho
        break
if gradle is None:
    sys.exit("ERRO: android/app/build.gradle(.kts) não encontrado")

with open(gradle, encoding="utf-8") as f:
    texto = f.read()

kts = gradle.endswith(".kts")
if kts:
    texto, n1 = re.subn(r'applicationId\s*=\s*"[^"]*"', f'applicationId = "{pacote}"', texto)
    texto, n2 = re.subn(r'minSdk\s*=\s*[^\n]+', "minSdk = 23", texto)
else:
    texto, n1 = re.subn(r'applicationId\s+"[^"]*"', f'applicationId "{pacote}"', texto)
    texto, n2 = re.subn(r'minSdk(Version)?\s+[^\n]+', "minSdkVersion 23", texto)

if n1 == 0:
    sys.exit("ERRO: applicationId não encontrado no build.gradle")
if n2 == 0:
    print("AVISO: minSdk não encontrado; mantendo o padrão do Flutter")

# Android 16 (API 36): exigência do Google Play desde 31/08/2026.
if kts:
    texto = re.sub(r"compileSdk\s*=\s*flutter\.compileSdkVersion",
                   "compileSdk = maxOf(flutter.compileSdkVersion, 36)", texto)
    texto = re.sub(r"targetSdk\s*=\s*flutter\.targetSdkVersion",
                   "targetSdk = maxOf(flutter.targetSdkVersion, 36)", texto)

# Assinatura de publicação: usa android/key.properties quando existir
# (criado pelo workflow "Gerar AAB" a partir dos segredos do GitHub);
# sem ele, continua assinando com a chave de depuração.
if kts and "key.properties" not in texto:
    texto = "import java.io.FileInputStream\nimport java.util.Properties\n\n" + texto
    texto = texto.replace(
        "\nandroid {",
        '''
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {''', 1)
    texto = texto.replace(
        "    buildTypes {",
        '''    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {''', 1)
    texto, n3 = re.subn(
        r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
        'signingConfig = if (keystorePropertiesFile.exists()) '
        'signingConfigs.getByName("release") else signingConfigs.getByName("debug")',
        texto)
    print(f"assinatura de publicação configurada ({n3} buildType)")
elif not kts:
    print("AVISO: build.gradle (Groovy) — assinatura de publicação não configurada")

with open(gradle, "w", encoding="utf-8") as f:
    f.write(texto)
print(f"{os.path.basename(gradle)}: applicationId={pacote}, minSdk=23, targetSdk>=36")

# ------------------------------------------------------------ AndroidManifest
manifest = os.path.join(RAIZ, "android", "app", "src", "main", "AndroidManifest.xml")
with open(manifest, encoding="utf-8") as f:
    m = f.read()

m = re.sub(r'android:label="[^"]*"', 'android:label="Jornada ETE"', m, count=1)
if "android.permission.INTERNET" not in m:
    m = m.replace(
        "<application",
        '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
        1,
    )
# Permite abrir telefone, e-mail e navegador (url_launcher) no Android 11+.
intents = """
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="mailto"/></intent>"""
if "android.intent.action.DIAL" not in m:
    if "<queries>" in m:
        m = m.replace("<queries>", "<queries>" + intents, 1)
    else:
        m = m.replace("</manifest>", "    <queries>" + intents + "\n    </queries>\n</manifest>", 1)

# Notificações: permissão do Android 13+ e ícone/cor padrão das notificações.
if "android.permission.POST_NOTIFICATIONS" not in m:
    m = m.replace(
        "<application",
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <application',
        1,
    )
if "default_notification_icon" not in m:
    meta = """
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_stat_notificacao" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/cor_notificacao" />
        <activity"""
    m = m.replace("\n        <activity", meta, 1) if "\n        <activity" in m else m.replace("<activity", meta.strip() + "", 1)

with open(manifest, "w", encoding="utf-8") as f:
    f.write(m)
print("AndroidManifest.xml ajustado")

# --------------------------------------------------------------- ícone do app
# Copia os ícones gerados por tool/gerar_icones.py (logotipo ETEADC) por cima
# do ícone padrão do Flutter.
import shutil

origem_icones = os.path.join(RAIZ, "tool", "icone", "res")
destino_res = os.path.join(RAIZ, "android", "app", "src", "main", "res")
if os.path.isdir(origem_icones):
    shutil.copytree(origem_icones, destino_res, dirs_exist_ok=True)
    print("Ícone do app substituído pelo logotipo ETEADC")
else:
    print("AVISO: tool/icone/res não encontrado; mantendo o ícone padrão")
