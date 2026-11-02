import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import 'publicar_aviso.dart';

/// Avisos da gestão, eventos e atividades (antes: página MenuEVENTOSCopy2 vazia).
class AbaAvisos extends StatefulWidget {
  final Usuario usuario;
  const AbaAvisos({super.key, required this.usuario});
  @override
  State<AbaAvisos> createState() => _AbaAvisosState();
}

class _AbaAvisosState extends State<AbaAvisos> {
  late final Stream<List<Aviso>> _avisos = Repo.avisos();
  String _filtro = 'Todos';

  Future<void> _excluir(Aviso a) async {
    final ok = await confirmar(context,
        titulo: 'Excluir aviso',
        mensagem: 'Excluir "${a.titulo}"? Esta ação não pode ser desfeita.',
        textoConfirmar: 'Excluir');
    if (!ok) return;
    try {
      await Repo.excluirAviso(a.id);
      if (mounted) mostrarAviso(context, 'Aviso excluído.');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos e eventos')),
      floatingActionButton: u.ehProfessor
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PublicarAvisoTela(autor: u),
              )),
              icon: const Icon(Icons.add),
              label: const Text('Publicar'),
            )
          : null,
      body: StreamBuilder<List<Aviso>>(
        stream: _avisos,
        builder: (context, snap) {
          if (snap.hasError) return ErroCarregar(erro: snap.error);
          if (!snap.hasData) return const Carregando();
          final visiveis = snap.data!.where((a) {
            final paraMim = u.ehProfessor ||
                a.turma.isEmpty ||
                a.turma == todasAsTurmas ||
                a.turma == u.turma;
            final doTipo = _filtro == 'Todos' || a.tipo == _filtro;
            return paraMim && doTipo;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              SeletorDia(
                valor: _filtro,
                dias: const ['Todos', ...tiposDeAviso],
                onChanged: (f) => setState(() => _filtro = f),
              ),
              const SizedBox(height: 8),
              if (visiveis.isEmpty)
                const EstadoVazio(
                  icone: Icons.notifications_none,
                  mensagem: 'Nenhum aviso por aqui.',
                  detalhe: 'Os avisos publicados pela escola aparecem nesta tela.',
                ),
              for (final a in visiveis)
                CartaoAviso(
                  aviso: a,
                  onExcluir: (u.ehProfessor && a.ehDe(u.uid)) ? () => _excluir(a) : null,
                ),
            ],
          );
        },
      ),
    );
  }
}

class CartaoAviso extends StatelessWidget {
  final Aviso aviso;
  final VoidCallback? onExcluir;
  const CartaoAviso({super.key, required this.aviso, this.onExcluir});

  Color get _cor {
    switch (aviso.tipo) {
      case 'Evento':
        return Cores.verde;
      case 'Atividade':
        return Cores.azulMedio;
      default:
        return Cores.vermelho;
    }
  }

  IconData get _icone {
    switch (aviso.tipo) {
      case 'Evento':
        return Icons.event;
      case 'Atividade':
        return Icons.task_alt;
      default:
        return Icons.campaign;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: _cor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                  child: _conteudo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conteudo() {
    final fmt = DateFormat("d 'de' MMM 'às' HH:mm", 'pt_BR');
    final fmtData = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
    return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icone, color: _cor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(aviso.titulo,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (aviso.data != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '📅 ${fmtData.format(aviso.data!)}',
                        style: TextStyle(color: _cor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (aviso.mensagem.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(aviso.mensagem),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (aviso.autorNome.isNotEmpty) aviso.autorNome,
                      if (aviso.turma.isNotEmpty) aviso.turma,
                      if (aviso.criadoEm != null) fmt.format(aviso.criadoEm!),
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: Cores.textoSecundario),
                  ),
                ],
              ),
            ),
            if (onExcluir != null)
              IconButton(
                tooltip: 'Excluir aviso',
                icon: const Icon(Icons.delete_outline, color: Cores.vermelho),
                onPressed: onExcluir,
              ),
          ],
        );
  }
}
