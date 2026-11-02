// Jornada ETE — notificação automática de avisos, eventos e atividades.
//
// Quando um documento é criado na coleção "avisos", envia uma notificação
// (Firebase Cloud Messaging) para os celulares inscritos no tópico:
//   - "todos"           se o aviso é para "Todas as turmas"
//   - "turma_<turma>"   se é para uma turma (ex.: "1º TDG A" -> turma_1TDGA)
// O app inscreve cada celular nesses tópicos (lib/servicos/notificacoes.dart).
//
// Publicar (uma vez; exige o plano Blaze do Firebase):
//   cd functions && npm install && cd ..
//   npx -y firebase-tools@latest deploy --only functions --project compettec-ui6cbh

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

const TODAS = "Todas as turmas";
const EMOJI = { Aviso: "📢", Evento: "📅", Atividade: "📝" };

// Igual ao slug() do app (lib/constantes.dart).
const slug = (texto) => String(texto || "").replace(/[^A-Za-z0-9]/g, "");

exports.notificarAviso = functions
  .runWith({ memory: "256MB", timeoutSeconds: 30 })
  .firestore.document("avisos/{avisoId}")
  .onCreate(async (snap, context) => {
    const aviso = snap.data() || {};
    const tipo = aviso.tipo || "Aviso";
    const turma = aviso.turma || TODAS;
    const topico = turma === TODAS ? "todos" : `turma_${slug(turma)}`;

    const titulo = `${EMOJI[tipo] || "📢"} ${tipo}: ${aviso.titulo || ""}`.trim();
    let corpo = String(aviso.mensagem || "");
    if (corpo.length > 240) corpo = corpo.slice(0, 237) + "...";

    const id = await admin.messaging().send({
      topic: topico,
      notification: { title: titulo, body: corpo },
      data: { tipo: "aviso", avisoId: context.params.avisoId },
      android: {
        priority: "high",
        notification: { icon: "ic_stat_notificacao", color: "#091540", sound: "default" },
      },
      apns: { payload: { aps: { sound: "default" } } },
    });
    functions.logger.info(`Notificação enviada para "${topico}"`, { id, tipo, turma });
  });
