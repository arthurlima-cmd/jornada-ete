#!/usr/bin/env python3
"""Gera lib/firebase_options.dart a partir de android/app/google-services.json.

Uso:  python3 tool/gerar_firebase_options.py [pacote_android]
Sem argumento, usa o primeiro app Android do arquivo.
Imprime o pacote escolhido (e o grava em GITHUB_OUTPUT quando roda no Actions).
"""
import json
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "android", "app", "google-services.json")
DESTINO = os.path.join(RAIZ, "lib", "firebase_options.dart")

if not os.path.exists(ORIGEM):
    sys.exit(f"ERRO: coloque o arquivo do Firebase em {ORIGEM}")

with open(ORIGEM, encoding="utf-8") as f:
    dados = json.load(f)

pacote_desejado = sys.argv[1] if len(sys.argv) > 1 else None
clientes = dados.get("client", [])
cliente = None
for c in clientes:
    pacote = c["client_info"]["android_client_info"]["package_name"]
    if pacote_desejado is None or pacote == pacote_desejado:
        cliente = c
        break
if cliente is None:
    sys.exit(f"ERRO: pacote {pacote_desejado} não encontrado no google-services.json")

info = dados["project_info"]
pacote = cliente["client_info"]["android_client_info"]["package_name"]
valores = {
    "apiKey": cliente["api_key"][0]["current_key"],
    "appId": cliente["client_info"]["mobilesdk_app_id"],
    "messagingSenderId": info["project_number"],
    "projectId": info["project_id"],
    "storageBucket": info.get("storage_bucket", ""),
}

linhas = "\n".join(f"    {k}: '{v}'," for k, v in valores.items())
codigo = f"""// GERADO AUTOMATICAMENTE por tool/gerar_firebase_options.py — não edite.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {{
  static const FirebaseOptions currentPlatform = FirebaseOptions(
{linhas}
  );
}}
"""
with open(DESTINO, "w", encoding="utf-8") as f:
    f.write(codigo)

print(f"firebase_options.dart gerado para o projeto {info['project_id']} (pacote {pacote})")
saida = os.environ.get("GITHUB_OUTPUT")
if saida:
    with open(saida, "a", encoding="utf-8") as f:
        f.write(f"package={pacote}\n")
