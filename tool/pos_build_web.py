"""Ajustes no build web (build/web) para a versão nova sempre aparecer.

O service worker do Flutter guardava o app em cache no navegador e no app
instalado (PWA): quem já tinha aberto o site continuava vendo a versão antiga
mesmo depois de uma atualização. Este script:

1. tira o registro do service worker do flutter_bootstrap.js;
2. troca o flutter_service_worker.js por um que apaga o cache antigo e se
   desinstala (para limpar os aparelhos que já tinham a versão antiga);
3. coloca no index.html um script que remove service workers e caches que
   tenham sobrado e recarrega a página uma única vez.

Uso: python3 tool/pos_build_web.py [pasta do build, padrão build/web]
"""
import re
import sys
from pathlib import Path

pasta = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/web')

# 1) bootstrap sem service worker
boot = pasta / 'flutter_bootstrap.js'
texto = boot.read_text(encoding='utf-8')
novo, n = re.subn(r'_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]*\}\s*\}\);',
                  '_flutter.loader.load({});', texto, flags=re.S)
if n:
    boot.write_text(novo, encoding='utf-8')
    print('flutter_bootstrap.js: service worker desligado')
else:
    print('flutter_bootstrap.js: nenhum registro de service worker encontrado')

# 2) service worker "faxineiro"
(pasta / 'flutter_service_worker.js').write_text("""// Remove o cache antigo do Jornada ETEADC e desinstala este service worker.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const chaves = await caches.keys();
    await Promise.all(chaves.map((c) => caches.delete(c)));
    await self.registration.unregister();
    const janelas = await self.clients.matchAll({ type: 'window' });
    janelas.forEach((j) => j.navigate(j.url));
  })());
});
""", encoding='utf-8')
print('flutter_service_worker.js: substituído pela versão que limpa o cache')

# 3) limpeza no index.html
index = pasta / 'index.html'
html = index.read_text(encoding='utf-8')
marca = 'jornada-limpa-cache'
if marca not in html:
    script = """  <script id="%s">
    // Versões antigas do site ficavam presas no cache do navegador.
    // Remove service workers e caches que sobraram e recarrega uma única vez.
    (function () {
      if (!('serviceWorker' in navigator)) return;
      navigator.serviceWorker.getRegistrations().then(function (regs) {
        if (!regs.length) return;
        var limpezas = regs.map(function (r) { return r.unregister(); });
        if (window.caches) {
          limpezas.push(caches.keys().then(function (ks) {
            return Promise.all(ks.map(function (k) { return caches.delete(k); }));
          }));
        }
        Promise.all(limpezas).then(function () {
          try {
            if (sessionStorage.getItem('jornada-recarregou')) return;
            sessionStorage.setItem('jornada-recarregou', '1');
          } catch (e) { return; }
          location.reload();
        });
      });
    })();
  </script>
""" % marca
    alvo = '<script src="flutter_bootstrap.js" async></script>'
    assert alvo in html, 'index.html sem flutter_bootstrap.js'
    html = html.replace(alvo, script + '  ' + alvo, 1)
    index.write_text(html, encoding='utf-8')
    print('index.html: limpeza de cache adicionada')
