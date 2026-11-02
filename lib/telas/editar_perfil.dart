import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../widgets/campo_turma.dart';
import '../widgets/comuns.dart';

/// "Suas informações": agora o botão Salvar grava de verdade
/// (no protótipo ele só executava print).
class EditarPerfilTela extends StatefulWidget {
  final Usuario usuario;
  const EditarPerfilTela({super.key, required this.usuario});
  @override
  State<EditarPerfilTela> createState() => _EditarPerfilTelaState();
}

class _EditarPerfilTelaState extends State<EditarPerfilTela> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario.nome);
  late final _matricula = TextEditingController(text: widget.usuario.matricula);
  late String? _turma = widget.usuario.turma.isEmpty ? null : widget.usuario.turma;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _matricula.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final nome = _nome.text.trim();
      await Repo.atualizarPerfil(
        widget.usuario.uid,
        nome: nome,
        matricula: _matricula.text.trim(),
        turma: widget.usuario.ehProfessor ? null : _turma,
      );
      await FirebaseAuth.instance.currentUser?.updateDisplayName(nome);
      if (!mounted) return;
      mostrarAviso(context, 'Dados atualizados.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Suas informações')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v ?? '').trim().length < 3 ? 'Informe seu nome.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: u.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'E-mail (não pode ser alterado)',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 12),
              if (!u.ehProfessor) ...[
                CampoTurma(
                  valor: _turma,
                  onChanged: (v) => setState(() => _turma = v),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _matricula,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de matrícula',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _salvando ? null : _salvar,
                child: Text(_salvando ? 'Salvando...' : 'Salvar alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
