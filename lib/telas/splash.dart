import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constantes.dart';
import 'portao.dart';

/// Animação inicial, igual à página "animacaoinicio" do FlutterFlow,
/// com as logos oficiais (logo_Artez e LOGOTIPO ETEADC TRANS) sobre fundo
/// branco, que é o fundo para o qual as duas logos foram desenhadas:
///
///   0,0 s – 0,6 s  logo Artez aparece (fade in)
///   0,6 s – 2,0 s  logo Artez fica na tela
///   2,0 s – 2,6 s  logo Artez some (fade out)
///   2,6 s – 3,2 s  logo da ETE aparece (fade in)
///   3,8 s          segue para o app
///
/// Correções em relação ao protótipo:
///  - navegava em 1 s, antes de a logo da ETE aparecer; agora espera a animação;
///  - deixava a splash no histórico (pop + push); agora a substitui;
///  - três áreas de toque abriam páginas duplicadas (uma ia para o login);
///    agora um toque só pula a animação, uma única vez;
///  - BoxFit.fill distorcia as logos; agora BoxFit.contain com largura responsiva.
class SplashTela extends StatefulWidget {
  const SplashTela({super.key});
  @override
  State<SplashTela> createState() => _SplashTelaState();
}

class _SplashTelaState extends State<SplashTela>
    with SingleTickerProviderStateMixin {
  static const _artez = 'assets/images/logo_artez.png';
  static const _logoEte = 'assets/images/logotipo_eteadc_trans.png';

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  // Pesos em milissegundos (somam 3200).
  late final Animation<double> _opacidadeArtez = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 600,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 1400),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 600,
    ),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 600),
  ]).animate(_ctrl);

  late final Animation<double> _opacidadeEte = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 2600),
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 600,
    ),
  ]).animate(_ctrl);

  bool _saiu = false;

  @override
  void initState() {
    super.initState();
    _ctrl.forward().whenComplete(() async {
      await Future.delayed(const Duration(milliseconds: 600));
      _seguir();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _seguir() {
    if (_saiu || !mounted) return;
    _saiu = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const PortaoAuth(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final tamanho = math.min(largura * 0.8, 340.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // ícones escuros na barra de status
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _seguir, // toque pula a animação (uma única vez)
          child: Semantics(
            label: 'Jornada ETE, $nomeEscola. Toque para continuar.',
            child: Stack(
              alignment: Alignment.center,
              children: [
                FadeTransition(
                  opacity: _opacidadeArtez,
                  child: Image.asset(
                    _artez,
                    width: tamanho,
                    fit: BoxFit.contain,
                    semanticLabel: 'Artez Comunicação Visual',
                    errorBuilder: (_, __, ___) => const _MarcaProvisoria(
                      icone: Icons.palette_outlined,
                      titulo: 'Artez',
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _opacidadeEte,
                  child: Image.asset(
                    _logoEte,
                    width: tamanho,
                    fit: BoxFit.contain,
                    semanticLabel: 'ETE Antônio Dourado Cavalcanti',
                    errorBuilder: (_, __, ___) => const _MarcaProvisoria(
                      icone: Icons.school_rounded,
                      titulo: 'Jornada ETE',
                      subtitulo: nomeEscola,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Mostrada só se o arquivo de imagem não estiver em assets/images/.
class _MarcaProvisoria extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? subtitulo;
  const _MarcaProvisoria({required this.icone, required this.titulo, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 96, color: const Color(0xFF091540)),
        const SizedBox(height: 16),
        Text(
          titulo,
          style: const TextStyle(color: Color(0xFF091540), fontSize: 34, fontWeight: FontWeight.w800),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitulo!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF57636C), fontSize: 15),
          ),
        ],
      ],
    );
  }
}
