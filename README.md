# Jornada ETE

Aplicativo da **ETE Antônio Dourado Cavalcanti** que reúne num só lugar a rotina
escolar: quadro de horários, calendário de provas, avisos e eventos da gestão,
cardápio e informações da escola. Há duas áreas, uma para **estudantes** e outra
para **professores**.

Versão em Flutter + Firebase reescrita a partir do protótipo do FlutterFlow,
com todas as correções da análise aplicadas.

## Baixar o APK

Cada envio para a branch `main` gera um APK automaticamente (GitHub Actions):

1. Abra a aba **Releases** do repositório e baixe o `jornada-ete.apk` mais recente.
2. No celular Android, abra o arquivo e permita **"instalar apps de fontes desconhecidas"**.

Também é possível gerar manualmente: aba **Actions → Gerar APK → Run workflow**.

## Primeira configuração (uma vez só)

1. **Regras do Firestore.** Abra o console do Firebase (projeto `compettec-ui6cbh`)
   → **Firestore Database → Regras**, cole o conteúdo de [`firestore.rules`](firestore.rules)
   e clique em **Publicar**.
   > Atenção: se você publicar regras pelo FlutterFlow depois, elas substituem estas.
2. **Login por e-mail.** Em **Authentication → Método de login**, deixe
   **E-mail/senha** ativado.
3. **Promover professores.** Todo cadastro nasce como `estudante`. Quem se cadastrou
   como professor aparece com `solicitou_professor = true` na coleção `usuarios`.
   No console, edite o documento e mude o campo `tipo` para `professor`.
4. **Turmas.** Entre como professor → **Início → Turmas → Carregar turmas da escola**.
   Isso cadastra as 12 turmas do integrado e as 6 do subsequente.

## Coleções do Firestore

| Coleção | Campos principais |
|---|---|
| `usuarios` (ID = uid) | `display_name`, `email`, `tipo`, `turma`, `matricula`, `solicitou_professor` |
| `turmas` | `nome`, `ordem`, `modalidade` (integrado = 9 aulas por dia; subsequente = 5 aulas por noite) |
| `horarios` (ID = turma_dia_aula) | `aulas` (disciplina), `conteudo`, `horario` ("1ª aula · 07:40"), `dia_semana`, `turma`, `professor`, `professor_nome` |
| `provas` | `disciplina`, `tipo`, `turma`, `data`, `conteudo`, `professor`, `professor_nome` |
| `avisos` | `titulo`, `mensagem`, `tipo`, `turma`, `data`, `autor`, `autor_nome`, `criado_em` |
| `cardapio` | `dia_semana`, `refeicao`, `itens` |

Nenhuma consulta precisa de índice composto: o app usa só filtros de igualdade
e ordena os resultados no próprio celular.

## Estrutura do código

```
lib/
  main.dart               inicialização (Firebase, idioma pt-BR, tema)
  tema.dart               paleta e estilos únicos
  constantes.dart         dias, 9 aulas, turmas padrão, contatos, textos da escola
  dados/modelos.dart      classes Usuario, Horario, Prova, Aviso, ItemCardapio, Turma
  dados/repositorio.dart  todo o acesso ao Firestore (com checagem de conflitos)
  widgets/                componentes reutilizáveis (cards, seletores, grade do dia)
  telas/                  uma tela por arquivo
tool/                     scripts usados pelo GitHub Actions
```

## Compilar no computador (opcional)

Com o Flutter instalado:

```bash
flutter create --platforms=android --org com.mycompany --project-name jornada_ete .
python3 tool/gerar_firebase_options.py com.mycompany.appete
python3 tool/ajustar_android.py com.mycompany.appete
flutter run            # ou: flutter build apk --release
```
