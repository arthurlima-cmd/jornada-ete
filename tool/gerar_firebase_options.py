#!/usr/bin/env python3
"""Gera lib/firebase_options.dart com a configuração do Firebase por plataforma.

- Android: android/app/google-services.json (obrigatório)
- iOS:     ios/Runner/GoogleService-Info.plist (opcional; sem ele o app
           compila para iOS, mas mostra erro ao abrir até o arquivo ser adicionado)

Uso:  python3 tool/gerar_firebase_options.py [pacote_android]
Imprime o pacote Android escolhido (e o grava em GITHUB_OUTPUT no Actions).
"""
import json
import os
import plistlib
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANDROID = os.path.join(RAIZ, "android", "app", "google-services.json")
IOS = os.path.join(RAIZ, "ios", "Runner", "GoogleService-Info.plist")
WEB = os.path.join(RAIZ, "tool", "firebase_web.json")
DESTINO = os.path.join(RAIZ, "lib", "firebase_options.dart")

if not os.path.exists(ANDROID):
    sys.exit(f"ERRO: coloque o arquivo do Firebase em {ANDROID}")

with open(ANDROID, encoding="utf-8") as f:
    dados = json.load(f)

pacote_desejado = sys.argv[1] if len(sys.argv) > 1 else None
cliente = None
for c in dados.get("client", []):
    pacote = c["client_info"]["android_client_info"]["package_name"]
    if pacote_desejado is None or pacote == pacote_desejado:
        cliente = c
        break
if cliente is None:
    sys.exit(f"ERRO: pacote {pacote_desejado} não encontrado no google-services.json")

info = dados["project_info"]
pacote = cliente["client_info"]["android_client_info"]["package_name"]


def bloco(valores: dict) -> str:
    linhas = "\n".join(f"    {k}: '{v}'," for k, v in valores.items() if v)
    return f"FirebaseOptions(\n{linhas}\n  )"


android = bloco({
    "apiKey": cliente["api_key"][0]["current_key"],
    "appId": cliente["client_info"]["mobilesdk_app_id"],
    "messagingSenderId": info["project_number"],
    "projectId": info["project_id"],
    "storageBucket": info.get("storage_bucket", ""),
})

if os.path.exists(IOS):
    with open(IOS, "rb") as f:
        p = plistlib.load(f)
    ios = "const " + bloco({
        "apiKey": p["API_KEY"],
        "appId": p["GOOGLE_APP_ID"],
        "messagingSenderId": p["GCM_SENDER_ID"],
        "projectId": p["PROJECT_ID"],
        "storageBucket": p.get("STORAGE_BUCKET", ""),
        "iosBundleId": p.get("BUNDLE_ID", ""),
    })
    print(f"iOS configurado (bundle {p.get('BUNDLE_ID')})")
else:
    ios = "null"
    print("AVISO: ios/Runner/GoogleService-Info.plist não encontrado; iOS sem Firebase")

if os.path.exists(WEB):
    with open(WEB, encoding="utf-8") as f:
        w = json.load(f)
    web = "const " + bloco({
        "apiKey": w["apiKey"],
        "appId": w["appId"],
        "messagingSenderId": w["messagingSenderId"],
        "projectId": w["projectId"],
        "authDomain": w.get("authDomain", ""),
        "storageBucket": w.get("storageBucket", ""),
    })
    print("Web configurado")
else:
    web = "null"

codigo = f"""// GERADO AUTOMATICAMENTE por tool/gerar_firebase_options.py — não edite.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {{
  static FirebaseOptions get currentPlatform {{
    // No navegador vem primeiro: num iPhone, o Safari também se diz "iOS".
    if (kIsWeb) {{
      return web ??
          (throw UnsupportedError('Firebase ainda não configurado para a web.'));
    }}
    if (defaultTargetPlatform == TargetPlatform.iOS) {{
      return ios ??
          (throw UnsupportedError(
              'Firebase ainda não configurado para iOS: adicione '
              'ios/Runner/GoogleService-Info.plist ao repositório.'));
    }}
    return android;
  }}

  static const FirebaseOptions android = {android};

  static const FirebaseOptions? ios = {ios};

  static const FirebaseOptions? web = {web};
}}
"""
with open(DESTINO, "w", encoding="utf-8") as f:
    f.write(codigo)

print(f"firebase_options.dart gerado para o projeto {info['project_id']} (pacote Android {pacote})")
saida = os.environ.get("GITHUB_OUTPUT")
if saida:
    with open(saida, "a", encoding="utf-8") as f:
        f.write(f"package={pacote}\n")
