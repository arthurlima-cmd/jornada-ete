import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../tema.dart';
import '../widgets/cartao_evento.dart';
import '../widgets/comuns.dart';

/// Agenda anual da escola (substitui a página Cardápio).
/// Estudantes consultam; professores cadastram eventos e alteram datas.
class AgendaTela extends StatefulWidget {
  final Usuario usuario;
  const AgendaTela({super.key, required this.usuario});
  @override
  State<AgendaTela> createState() => _AgendaTelaState();
}

class _AgendaTelaState extends State<AgendaTela> {
  late final Stream<List<EventoAgenda>> _eventos = Repo.eventosAgenda();
  int _ano = DateTime.now().year;
  bool _salvandoModelo = false;

  bool get _prof => widget.usuario.ehProfessor;

  /// Eventos anuais de modelo, mostrados enquanto a agenda está vazia.
  List<EventoAgenda> _modelo(int ano) => [
        for (final e in eventosAnuais)
          EventoAgenda(
            id: '',
            titulo: e.titulo,
            descricao: e.descricao,
            data: DateTime(ano, e.mes, e.dia),
            horaInicio: e.inicio,
            horaFim: e.fim,
            local: e.local,
            categoria: e.categoria,
          ),
      ];

  Future<void> _salvarModelo() async {
    setState(() => _salvandoModelo = true);
    try {
      final n = await Repo.salvarEventosAnuais(_ano, widget.usuario);
      if (mounted) mostrarAviso(context, '$n eventos salvos na agenda de $_ano.');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _salvandoModelo = false);
    }
  }

  Future<void> _abrirForm([EventoAgenda? existente]) async {
    final r = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FormEvento(
        autor: widget.usuario,
        existente: existente,
        anoInicial: _ano,
      ),
    );
    if (r != null && mounted) mostrarAviso(context, r);
  }

  void _detalhes(EventoAgenda e) {
    final d = e.data;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.titulo,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (d != null)
              _Linha(Icons.event,
                  _maiuscula(DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR').format(d))),
            if (e.horario.isNotEmpty) _Linha(Icons.schedule, e.horario),
            if (e.local.isNotEmpty) _Linha(Icons.place_outlined, e.local),
            if (e.descricao.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(e.descricao, style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      floatingActionButton: _prof
          ? FloatingActionButton.extended(
              onPressed: () => _abrirForm(),
              icon: const Icon(Icons.add),
              label: const Text('Novo evento'),
            )
          : null,
      body: StreamBuilder<List<EventoAgenda>>(
        stream: _eventos,
        builder: (context, snap) {
          if (snap.hasError) return ErroCarregar(erro: snap.error);
          if (!snap.hasData) return const Carregando();

          final todos = snap.data!;
          final usandoModelo = todos.isEmpty;
          final lista = usandoModelo
              ? _modelo(_ano)
              : todos.where((e) => e.data?.year == _ano).toList();
          final hoje = DateUtils.dateOnly(DateTime.now());

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Ano anterior',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _ano--),
                  ),
                  Text('$_ano',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  IconButton(
                    tooltip: 'Próximo ano',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _ano++),
                  ),
                ],
              ),
              if (usandoModelo)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Cores.azulClaro,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estes são os eventos anuais de modelo da escola.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (_prof) ...[
                        const SizedBox(height: 4),
                        Text('Salve-os na agenda de $_ano para poder alterar as '
                            'datas e acrescentar novos eventos.'),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _salvandoModelo ? null : _salvarModelo,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(_salvandoModelo
                              ? 'Salvando...'
                              : 'Salvar na agenda de $_ano'),
                        ),
                      ],
                    ],
                  ),
                ),
              if (lista.isEmpty)
                EstadoVazio(
                  icone: Icons.event_busy_outlined,
                  mensagem: 'Nenhum evento em $_ano.',
                  detalhe: _prof ? 'Toque em "Novo evento" para cadastrar.' : null,
                ),
              for (final e in lista)
                CartaoEvento(
                  evento: e,
                  passado: e.data != null && e.data!.isBefore(hoje),
                  onTap: (!usandoModelo && _prof) ? () => _abrirForm(e) : () => _detalhes(e),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _maiuscula(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _Linha extends StatelessWidget {
  final IconData icone;
  final String texto;
  const _Linha(this.icone, this.texto);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icone, size: 20, color: Cores.azul),
            const SizedBox(width: 10),
            Expanded(child: Text(texto, style: const TextStyle(fontSize: 16))),
          ],
        ),
      );
}

/// Formulário de cadastro/edição de evento (professores).
class _FormEvento extends StatefulWidget {
  final Usuario autor;
  final EventoAgenda? existente;
  final int anoInicial;
  const _FormEvento({
    required this.autor,
    required this.existente,
    required this.anoInicial,
  });
  @override
  State<_FormEvento> createState() => _FormEventoState();
}

class _FormEventoState extends State<_FormEvento> {
  final _form = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.existente?.titulo ?? '');
  late final _descricao = TextEditingController(text: widget.existente?.descricao ?? '');
  late final _local = TextEditingController(text: widget.existente?.local ?? '');
  late String _categoria = widget.existente?.categoria ?? 'geral';
  late DateTime? _data = widget.existente?.data;
  late String _inicio = widget.existente?.horaInicio.isNotEmpty == true
      ? widget.existente!.horaInicio
      : '08:00';
  late String _fim = widget.existente?.horaFim.isNotEmpty == true
      ? widget.existente!.horaFim
      : '15:00';
  String? _erroData;
  bool _salvando = false;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _local.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final base = _data ??
        (widget.anoInicial == DateTime.now().year
            ? DateTime.now()
            : DateTime(widget.anoInicial, 1, 1));
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 2),
      lastDate: DateTime(base.year + 3, 12, 31),
    );
    if (d != null) {
      setState(() {
        _data = d;
        _erroData = null;
      });
    }
  }

  TimeOfDay _paraHora(String h) {
    final p = h.split(':');
    return TimeOfDay(
      hour: int.tryParse(p.first) ?? 8,
      minute: p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0,
    );
  }

  String _deHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _escolherHora(bool inicio) async {
    final t = await showTimePicker(
      context: context,
      initialTime: _paraHora(inicio ? _inicio : _fim),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null) return;
    setState(() {
      if (inicio) {
        _inicio = _deHora(t);
      } else {
        _fim = _deHora(t);
      }
    });
  }

  Future<void> _salvar() async {
    final ok = _form.currentState!.validate();
    setState(() => _erroData = _data == null ? 'Escolha a data.' : null);
    if (!ok || _data == null) return;
    setState(() => _salvando = true);
    try {
      await Repo.salvarEvento(
        id: widget.existente?.id,
        autor: widget.autor,
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        data: _data!,
        horaInicio: _inicio,
        horaFim: _fim,
        local: _local.text.trim(),
        categoria: _categoria,
      );
      if (mounted) Navigator.of(context).pop('Evento salvo!');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final e = widget.existente;
    if (e == null) return;
    final ok = await confirmar(context,
        titulo: 'Excluir evento',
        mensagem: 'Excluir "${e.titulo}" da agenda?',
        textoConfirmar: 'Excluir');
    if (!ok) return;
    try {
      await Repo.excluirEvento(e.id);
      if (mounted) Navigator.of(context).pop('Evento excluído.');
    } catch (err) {
      if (mounted) mostrarAviso(context, mensagemDeErro(err), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    final estilo = estiloDe(_categoria);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + teclado),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existente == null ? 'Novo evento' : 'Editar evento',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titulo,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome do evento'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricao,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Descrição (ex.: Homenagem especial!)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: estilo.fundo,
                  child: Icon(estilo.icone, color: estilo.cor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampoSelecao(
                    rotulo: 'Categoria (ícone e cor)',
                    valor: categoriasAgenda[_categoria],
                    opcoes: categoriasAgenda.values.toList(),
                    onChanged: (v) => setState(() {
                      _categoria = categoriasAgenda.entries
                          .firstWhere((e) => e.value == v,
                              orElse: () => const MapEntry('geral', 'Outro'))
                          .key;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _escolherData,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data',
                  errorText: _erroData,
                  prefixIcon: const Icon(Icons.event_outlined),
                ),
                child: Text(_data == null
                    ? 'Toque para escolher'
                    : _maiuscula(DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR')
                        .format(_data!))),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: () => _escolherHora(true),
                    icon: const Icon(Icons.schedule),
                    label: Text('Início $_inicio'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: () => _escolherHora(false),
                    icon: const Icon(Icons.schedule),
                    label: Text('Fim $_fim'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _local,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Local (ex.: Pátio, Auditório, Quadra)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar'),
            ),
            if (widget.existente != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Cores.vermelho),
                onPressed: _salvando ? null : _excluir,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir evento'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
