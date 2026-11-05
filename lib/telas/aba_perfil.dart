import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../servicos/notificacoes.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import 'cadastro_horarios.dart';
import 'cadastro_provas.dart';
import 'contatos.dart';
import 'editar_perfil.dart';
import 'excluir_conta.dart';
import 'info_escola.dart';
import 'publicar_aviso.dart';
import 'turmas.dart';

/// Perfil com os dados reais (antes: "Lucas", "Juliana" e fotos de banco de
/// imagens fixos) e o botão Sair, que não existia.
class AbaPerfil extends StatelessWidget {
  final Usuario usuario;
  const AbaPerfil({super.key, required this.usuario});

  Future<void> _sair(BuildContext context) async {
    final ok = await confirmar(context,
        titulo: 'Sair da conta',
        mensagem: 'Deseja mesmo sair do Jornada ETEADC?',
        textoConfirmar: 'Sair');
    if (!ok) return;
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    await Notificacoes.desativar();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    void abrir(Widget t) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => t));

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Cores.borda),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Cores.azul,
                  child: Text(
                    u.iniciais,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  u.nome.isEmpty ? 'Sem nome' : u.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(u.ehProfessor ? 'Professor(a)' : 'Estudante'),
                  backgroundColor: Cores.azulClaro,
                  side: BorderSide.none,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Bloco(children: [
            _Linha(icone: Icons.mail_outline, rotulo: 'E-mail', valor: u.email),
            if (!u.ehProfessor)
              _Linha(
                icone: Icons.groups_outlined,
                rotulo: 'Turma',
                valor: u.turma.isEmpty ? 'Não informada' : u.turma,
              ),
            _Linha(
              icone: Icons.badge_outlined,
              rotulo: 'Matrícula',
              valor: u.matricula.isEmpty ? 'Não informada' : u.matricula,
            ),
          ]),
          const SizedBox(height: 12),
          _Bloco(children: [
            _Opcao(
              icone: Icons.edit_outlined,
              texto: 'Editar meus dados',
              onTap: () => abrir(EditarPerfilTela(usuario: u)),
            ),
            if (u.ehProfessor) ...[
              _Opcao(
                icone: Icons.edit_calendar_outlined,
                texto: 'Cadastrar horários',
                onTap: () => abrir(CadastroHorariosTela(professor: u)),
              ),
              _Opcao(
                icone: Icons.post_add,
                texto: 'Cadastrar provas',
                onTap: () => abrir(CadastroProvasTela(professor: u)),
              ),
              _Opcao(
                icone: Icons.add_alert_outlined,
                texto: 'Publicar aviso',
                onTap: () => abrir(PublicarAvisoTela(autor: u)),
              ),
              _Opcao(
                icone: Icons.groups_outlined,
                texto: 'Turmas',
                onTap: () => abrir(const TurmasTela()),
              ),
            ],
            _Opcao(
              icone: Icons.apartment_outlined,
              texto: 'Informações da escola',
              onTap: () => abrir(const InfoEscolaTela()),
            ),
            _Opcao(
              icone: Icons.contact_phone_outlined,
              texto: 'Contatos',
              onTap: () => abrir(const ContatosTela()),
            ),
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Cores.vermelho,
              side: const BorderSide(color: Cores.vermelho),
            ),
            onPressed: () => _sair(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: Cores.textoSecundario),
              onPressed: () => abrir(ExcluirContaTela(usuario: u)),
              child: const Text('Excluir minha conta'),
            ),
          ),
          Center(
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: Cores.textoSecundario),
              onPressed: () => abrirLink(context, urlPrivacidade),
              child: const Text('Política de privacidade'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  final List<Widget> children;
  const _Bloco({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(children: children),
    );
  }
}

class _Linha extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  const _Linha({required this.icone, required this.rotulo, required this.valor});
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icone, color: Cores.azul),
        title: Text(rotulo, style: const TextStyle(fontSize: 12, color: Cores.textoSecundario)),
        subtitle: Text(valor, style: const TextStyle(fontSize: 16, color: Cores.texto)),
      );
}

class _Opcao extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;
  const _Opcao({required this.icone, required this.texto, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icone, color: Cores.azul),
        title: Text(texto),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}
