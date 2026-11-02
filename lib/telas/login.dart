import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dados/repositorio.dart';
import '../tema.dart';
import '../widgets/campo_turma.dart';
import '../widgets/comuns.dart';

String erroDeAutenticacao(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail. Use a aba Entrar.';
      case 'weak-password':
        return 'Senha fraca. Use pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
    }
  }
  return mensagemDeErro(e);
}

String? validarEmail(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Informe o e-mail.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
    return 'E-mail inválido.';
  }
  return null;
}

/// Login e cadastro. Corrige: calendário aberto pelo campo de e-mail,
/// ausência de validação, cadastro sem nome/turma e mensagens em inglês.
class LoginTela extends StatelessWidget {
  final String perfil; // "estudante" ou "professor"
  const LoginTela({super.key, required this.perfil});

  @override
  Widget build(BuildContext context) {
    final professor = perfil == 'professor';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(professor ? 'Acesso do professor' : 'Acesso do estudante'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Cores.amarelo,
            tabs: [Tab(text: 'Entrar'), Tab(text: 'Criar conta')],
          ),
        ),
        body: TabBarView(
          children: [
            const _FormEntrar(),
            _FormCadastro(professor: professor),
          ],
        ),
      ),
    );
  }
}

class _FormEntrar extends StatefulWidget {
  const _FormEntrar();
  @override
  State<_FormEntrar> createState() => _FormEntrarState();
}

class _FormEntrarState extends State<_FormEntrar> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultar = true;
  bool _carregando = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );
      if (!mounted) return;
      // Volta para a raiz; o PortaoAuth mostra o menu. Sem "voltar" para o login.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) mostrarAviso(context, erroDeAutenticacao(e), erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _esqueciSenha() async {
    final erro = validarEmail(_email.text);
    if (erro != null) {
      mostrarAviso(context, 'Digite seu e-mail no campo acima primeiro.', erro: true);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
      if (mounted) {
        mostrarAviso(context, 'Enviamos um link de redefinição para ${_email.text.trim()}.');
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, erroDeAutenticacao(e), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Moldura(
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Entre com seu e-mail e senha',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: validarEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senha,
                obscureText: _ocultar,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _entrar(),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _ocultar ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(_ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                  ),
                ),
                validator: (v) => (v ?? '').isEmpty ? 'Informe a senha.' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _carregando ? null : _esqueciSenha,
                  child: const Text('Esqueci minha senha'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _carregando ? null : _entrar,
                child: _carregando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCadastro extends StatefulWidget {
  final bool professor;
  const _FormCadastro({required this.professor});
  @override
  State<_FormCadastro> createState() => _FormCadastroState();
}

class _FormCadastroState extends State<_FormCadastro> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  final _matricula = TextEditingController();
  String? _turma;
  String? _erroTurma;
  bool _ocultar = true;
  bool _carregando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirma.dispose();
    _matricula.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    final formOk = _form.currentState!.validate();
    final turmaOk = widget.professor || (_turma != null && _turma!.isNotEmpty);
    setState(() => _erroTurma = turmaOk ? null : 'Selecione sua turma.');
    if (!formOk || !turmaOk) return;

    setState(() => _carregando = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );
      final user = cred.user!;
      await user.updateDisplayName(_nome.text.trim());
      await Repo.criarUsuario(
        uid: user.uid,
        email: _email.text.trim(),
        nome: _nome.text.trim(),
        turma: widget.professor ? '' : _turma!,
        matricula: _matricula.text.trim(),
        solicitouProfessor: widget.professor,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) mostrarAviso(context, erroDeAutenticacao(e), erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Moldura(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.professor ? 'Cadastro de professor(a)' : 'Cadastro de estudante',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (widget.professor) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Cores.azulClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Por segurança, o acesso de professor é liberado pela gestão '
                  'da escola após o cadastro. Até lá, você usa o app como estudante.',
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v ?? '').trim().length < 3 ? 'Informe seu nome.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: validarEmail,
            ),
            if (!widget.professor) ...[
              const SizedBox(height: 12),
              CampoTurma(
                valor: _turma,
                erro: _erroTurma,
                onChanged: (v) => setState(() {
                  _turma = v;
                  _erroTurma = null;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _matricula,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Matrícula (opcional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _senha,
              obscureText: _ocultar,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Senha (mínimo 6 caracteres)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _ocultar ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(_ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                ),
              ),
              validator: (v) => (v ?? '').length < 6 ? 'Use pelo menos 6 caracteres.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirma,
              obscureText: _ocultar,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Confirmar senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) => v != _senha.text ? 'As senhas não conferem.' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _carregando ? null : _criar,
              child: _carregando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centraliza o formulário e limita a largura em tablets.
class _Moldura extends StatelessWidget {
  final Widget child;
  const _Moldura({required this.child});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    );
  }
}
