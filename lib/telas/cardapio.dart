import 'package:flutter/material.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../tema.dart';
import '../widgets/comuns.dart';

/// Cardápio da semana lido do Firestore (antes: abas só com a palavra
/// "Cardápio" e botão voltar levando a outra página).
class CardapioTela extends StatefulWidget {
  final Usuario usuario;
  const CardapioTela({super.key, required this.usuario});
  @override
  State<CardapioTela> createState() => _CardapioTelaState();
}

class _CardapioTelaState extends State<CardapioTela> {
  String _dia = diaDeHoje();
  final _memo = MemoStream<List<ItemCardapio>>();

  Future<void> _adicionar() async {
    final salvo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FormItem(dia: _dia),
    );
    if (salvo == true && mounted) mostrarAviso(context, 'Item adicionado!');
  }

  Future<void> _excluir(ItemCardapio i) async {
    final ok = await confirmar(context,
        titulo: 'Excluir item',
        mensagem: 'Excluir ${i.refeicao} de ${diasExtenso[i.diaSemana] ?? i.diaSemana}?',
        textoConfirmar: 'Excluir');
    if (!ok) return;
    try {
      await Repo.excluirItemCardapio(i.id);
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    }
  }

  IconData _icone(String refeicao) {
    if (refeicao.contains('Almoço')) return Icons.lunch_dining_outlined;
    if (refeicao.contains('Café')) return Icons.free_breakfast_outlined;
    return Icons.bakery_dining_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final prof = widget.usuario.ehProfessor;
    return Scaffold(
      appBar: AppBar(title: const Text('Cardápio da semana')),
      floatingActionButton: prof
          ? FloatingActionButton.extended(
              onPressed: _adicionar,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          SeletorDia(
            valor: _dia,
            dias: diasSemana,
            onChanged: (d) => setState(() => _dia = d),
          ),
          const SizedBox(height: 8),
          Text(
            diasExtenso[_dia] ?? _dia,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<ItemCardapio>>(
            stream: _memo.obter(_dia, () => Repo.cardapio(_dia)),
            builder: (context, snap) {
              if (snap.hasError) return ErroCarregar(erro: snap.error);
              if (!snap.hasData) return const Carregando();
              final itens = snap.data!;
              if (itens.isEmpty) {
                return const EstadoVazio(
                  icone: Icons.restaurant_menu,
                  mensagem: 'Cardápio ainda não divulgado.',
                );
              }
              return Column(
                children: [
                  for (final i in itens)
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Cores.borda),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Cores.verde.withValues(alpha: 0.12),
                          child: Icon(_icone(i.refeicao), color: Cores.verde),
                        ),
                        title: Text(i.refeicao,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(i.itens),
                        trailing: prof
                            ? IconButton(
                                tooltip: 'Excluir item',
                                icon: const Icon(Icons.delete_outline, color: Cores.vermelho),
                                onPressed: () => _excluir(i),
                              )
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FormItem extends StatefulWidget {
  final String dia;
  const _FormItem({required this.dia});
  @override
  State<_FormItem> createState() => _FormItemState();
}

class _FormItemState extends State<_FormItem> {
  final _form = GlobalKey<FormState>();
  final _itens = TextEditingController();
  String _refeicao = refeicoes.first;
  bool _salvando = false;

  @override
  void dispose() {
    _itens.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await Repo.salvarItemCardapio(
        dia: widget.dia,
        refeicao: _refeicao,
        itens: _itens.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + teclado),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cardápio · ${diasExtenso[widget.dia]}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            CampoSelecao(
              rotulo: 'Refeição',
              valor: _refeicao,
              opcoes: refeicoes,
              onChanged: (v) => setState(() => _refeicao = v ?? _refeicao),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _itens,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Itens',
                hintText: 'Ex.: arroz, feijão, frango assado e salada',
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Informe os itens.' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
