#!/usr/bin/env bash
# Publica a versão web do Jornada ETEADC no Firebase Hosting (gratuito),
# sem depender do GitHub Pages. Endereço: https://compettec-ui6cbh.web.app
#
# Uso (no Cloud Shell: https://shell.cloud.google.com):
#   git clone --depth 1 https://github.com/arthurlima-cmd/jornada-ete.git
#   cd jornada-ete
#   npx -y firebase-tools@latest login --no-localhost
#   bash tool/publicar_firebase_hosting.sh
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf site
mkdir -p site/jornada-ete
cp -r docs/app site/jornada-ete/app      # app (compilado para /jornada-ete/app/)
cp docs/*.html docs/*.css site/          # política de privacidade e exclusão de conta

npx -y firebase-tools@latest deploy --only hosting --project compettec-ui6cbh

echo
echo "Pronto! App:         https://compettec-ui6cbh.web.app/jornada-ete/app/"
echo "        Privacidade: https://compettec-ui6cbh.web.app/privacidade.html"
