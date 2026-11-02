import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../widgets/campo_turma.dart';
import '../widgets/comuns.dart';

/// Publicar aviso/evento/atividade (no protótipo, o card "Publicar aviso"
/// não tinha ação).
class PublicarAvisoTela extends StatefulWidget {
  final Usuario autor;
  const PublicarAvisoTela({super.key, required this.autor});
  @override
  State<PublicarAvisoTela> createState() => _PublicarAvisoTelaState();
}

class _PublicarAvisoTelaState extends State<PublicarAvisoTela> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _mensagem = TextEditingController();
  String _tipo = tiposDeAviso.first;
  String? _turma = todasAsTurmas;
  DateTime? _data;
  bool _salvando = false;

  @override
  void dispose() {
    _titulo.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _publicar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await Repo.publicarAviso(
        autor: widget.autor,
        titulo: _titulo.text.trim(),
        mensagem: _mensagem.text.trim(),
        tipo: _tipo,
        turma: _turma ?? todasAsTurmas,
        data: _data,
      );
      if (!mounted) return;
      mostrarAviso(context, 'Publicado!');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar aviso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SeletorDia(
                valor: _tipo,
                dias: tiposDeAviso,
                onChanged: (t) => setState(() => _tipo = t),
              ),
              const SizedBox(height: 12),
              CampoTurma(
                rotulo: 'Para quem',
                valor: _turma,
                incluirTodas: true,
                onChanged: (v) => setState(() => _turma = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titulo,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o título.' : null,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _mensagem,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Mensagem'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Escreva a mensagem.' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _escolherData,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data do evento/atividade (opcional)',
                    prefixIcon: const Icon(Icons.event_outlined),
                    suffixIcon: _data == null
                        ? null
                        : IconButton(
                            tooltip: 'Remover data',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _data = null),
                          ),
                  ),
                  child: Text(_data == null
                      ? 'Sem data'
                      : DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_data!)),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _salvando ? null : _publicar,
                icon: const Icon(Icons.send),
                label: Text(_salvando ? 'Publicando...' : 'Publicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
