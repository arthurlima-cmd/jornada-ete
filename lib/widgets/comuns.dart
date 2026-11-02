import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dados/repositorio.dart';
import '../tema.dart';

/// Mensagem curta no rodapé (substitui os Alert Dialogs de sucesso).
void mostrarAviso(BuildContext context, String mensagem, {bool erro = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: erro ? Cores.vermelho : Cores.azul,
    ));
}

/// Traduz qualquer erro para uma mensagem em português.
String mensagemDeErro(Object e) {
  if (e is ErroApp) return e.mensagem;
  final t = e.toString();
  if (t.contains('permission-denied')) {
    return 'Você não tem permissão para esta ação.';
  }
  if (t.contains('unavailable') || t.contains('network')) {
    return 'Sem conexão com a internet. Tente novamente.';
  }
  return 'Algo deu errado. Tente novamente.';
}

/// Diálogo de confirmação para ações destrutivas (excluir, sair).
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Confirmar',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<void> abrirLink(BuildContext context, String url) async {
  try {
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      mostrarAviso(context, 'Não foi possível abrir o link.', erro: true);
    }
  } catch (_) {
    if (context.mounted) {
      mostrarAviso(context, 'Não foi possível abrir o link.', erro: true);
    }
  }
}

/// Guarda um Stream enquanto a "chave" (ex.: turma + dia) não muda.
/// Evita refazer a consulta ao Firestore a cada reconstrução da tela.
class MemoStream<T> {
  String? _chave;
  Stream<T>? _stream;

  Stream<T> obter(String chave, Stream<T> Function() criar) {
    if (_stream == null || _chave != chave) {
      _chave = chave;
      _stream = criar();
    }
    return _stream!;
  }
}

class Carregando extends StatelessWidget {
  const Carregando({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
}

/// Mensagem para listas vazias.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  final String? detalhe;
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.mensagem,
    this.detalhe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 48, color: Cores.textoSecundario),
          const SizedBox(height: 12),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (detalhe != null) ...[
            const SizedBox(height: 6),
            Text(
              detalhe!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Cores.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}

class ErroCarregar extends StatelessWidget {
  final Object? erro;
  const ErroCarregar({super.key, this.erro});
  @override
  Widget build(BuildContext context) => EstadoVazio(
        icone: Icons.cloud_off,
        mensagem: 'Não foi possível carregar os dados.',
        detalhe: erro == null ? null : mensagemDeErro(erro!),
      );
}

class TituloSecao extends StatelessWidget {
  final String texto;
  final Widget? acao;
  const TituloSecao(this.texto, {super.key, this.acao});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Cores.texto,
              ),
            ),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

/// Card de atalho reutilizável (substitui os 18 cards copiados do protótipo).
class CardAtalho extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final Color cor;
  final VoidCallback onTap;
  const CardAtalho({
    super.key,
    required this.icone,
    required this.titulo,
    required this.onTap,
    this.cor = Cores.azul,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: titulo,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Cores.borda),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cor.withValues(alpha: 0.12),
                  child: Icon(icone, color: cor),
                ),
                const SizedBox(height: 10),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grade responsiva de atalhos: 2 colunas no celular, mais em telas largas.
class GradeAtalhos extends StatelessWidget {
  final List<Widget> filhos;
  const GradeAtalhos({super.key, required this.filhos});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final colunas = c.maxWidth > 700 ? 4 : (c.maxWidth > 460 ? 3 : 2);
      return GridView.count(
        crossAxisCount: colunas,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: filhos,
      );
    });
  }
}

/// Seleção dos dias Seg–Sex.
class SeletorDia extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;
  final List<String> dias;
  const SeletorDia({
    super.key,
    required this.valor,
    required this.onChanged,
    required this.dias,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final d in dias)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(d),
                selected: d == valor,
                showCheckmark: false,
                selectedColor: Cores.azul,
                labelStyle: TextStyle(
                  color: d == valor ? Colors.white : Cores.texto,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => onChanged(d),
              ),
            ),
        ],
      ),
    );
  }
}

/// Campo de seleção (DropDown) com rótulo e mensagem de erro.
class CampoSelecao extends StatelessWidget {
  final String rotulo;
  final String? valor;
  final List<String> opcoes;
  final ValueChanged<String?>? onChanged;
  final String? erro;
  final IconData? icone;
  const CampoSelecao({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
    this.erro,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final v = (valor != null && opcoes.contains(valor)) ? valor : null;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: rotulo,
        errorText: erro,
        prefixIcon: icone == null ? null : Icon(icone),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      isEmpty: v == null,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: v,
          isExpanded: true,
          hint: const Text('Selecione'),
          items: [
            for (final o in opcoes)
              DropdownMenuItem<String>(value: o, child: Text(o)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
