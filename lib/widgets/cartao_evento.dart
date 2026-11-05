import 'package:flutter/material.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../tema.dart';

/// Ícone e cores de cada categoria da Agenda (iguais ao modelo da escola).
class EstiloCategoria {
  final IconData icone;
  final Color fundo;
  final Color cor;
  const EstiloCategoria(this.icone, this.fundo, this.cor);
}

const _roxoFundo = Color(0xFFDDB3EE);
const _roxo = Color(0xFF6A0F4D);
const _rosaFundo = Color(0xFFF8A3A6);
const _vermelho = Color(0xFF9E0E14);

const Map<String, EstiloCategoria> estilosAgenda = {
  'festa': EstiloCategoria(Icons.celebration, _roxoFundo, _roxo),
  'musica': EstiloCategoria(Icons.beach_access, _roxoFundo, _roxo),
  'solidariedade': EstiloCategoria(Icons.volunteer_activism, _rosaFundo, _vermelho),
  'homenagem': EstiloCategoria(Icons.favorite, _rosaFundo, _vermelho),
  'familia': EstiloCategoria(Icons.person_outline, Color(0xFFAFD2FA), Color(0xFF0E6B85)),
  'estudante': EstiloCategoria(Icons.person_outline, Color(0xFFB0F8B2), Color(0xFF117A20)),
  'esporte': EstiloCategoria(Icons.emoji_events, Color(0xFFF6DD8B), Color(0xFFB0620B)),
  'academico': EstiloCategoria(Icons.school_outlined, Color(0xFFCFE0F7), Cores.azul),
  'geral': EstiloCategoria(Icons.event, Color(0xFFE3E6F8), Cores.azul),
};

EstiloCategoria estiloDe(String categoria) =>
    estilosAgenda[categoria] ?? estilosAgenda['geral']!;

const Color _fundoData = Color(0xFFB6B9EC);

/// Cartão de evento: ícone da categoria · data · título, descrição, horário e local.
class CartaoEvento extends StatelessWidget {
  final EventoAgenda evento;
  final VoidCallback? onTap;
  final bool passado;
  const CartaoEvento({
    super.key,
    required this.evento,
    this.onTap,
    this.passado = false,
  });

  @override
  Widget build(BuildContext context) {
    final e = evento;
    final estilo = estiloDe(e.categoria);
    final d = e.data;

    return Opacity(
      opacity: passado ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Cores.azul, width: 1.5),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ícone da categoria
                    Container(
                      width: 72,
                      constraints: const BoxConstraints(minHeight: 92),
                      decoration: BoxDecoration(
                        color: estilo.fundo,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(estilo.icone, color: estilo.cor, size: 36),
                    ),
                    const SizedBox(width: 10),
                    // Data
                    Container(
                      width: 66,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _fundoData,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            d == null ? '--' : mesesAbrev[d.month - 1],
                            style: const TextStyle(fontSize: 16, color: Cores.azul),
                          ),
                          Text(
                            d == null ? '--' : d.day.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Cores.azul,
                            ),
                          ),
                          Text(
                            d == null ? '' : diasAbrev[d.weekday - 1],
                            style: const TextStyle(fontSize: 15, color: Cores.azul),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Texto
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              e.titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Cores.texto,
                              ),
                            ),
                            if (e.descricao.isNotEmpty)
                              Text(
                                e.descricao,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15),
                              ),
                            if (e.horario.isNotEmpty)
                              Text(e.horario, style: const TextStyle(fontSize: 15)),
                            if (e.local.isNotEmpty)
                              Text(
                                e.local,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
