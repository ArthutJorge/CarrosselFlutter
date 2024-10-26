import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'models/monitor.dart';
import 'services/monitor_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MonitorScheduleTable extends StatefulWidget {
  final List<Monitor> monitores;
  final List<String> horarios;
  final String observacao;
  final MonitorService monitorService;

  const MonitorScheduleTable({
    super.key,
    required this.monitores,
    required this.horarios,
    required this.observacao,
    required this.monitorService,
  });

  @override
  _MonitorScheduleTableState createState() => _MonitorScheduleTableState();
}

class _MonitorScheduleTableState extends State<MonitorScheduleTable> {
  final List<String> diasDaSemana = ["Segunda","Terça","Quarta","Quinta","Sexta","Sábado"];
  final Map<String, Color> _coresMap = {};

  @override
  void initState() {
    super.initState();
    _atribuirCoresParaMonitores();
  }

  void _atribuirCoresParaMonitores() {
    _coresMap.clear();
    List<Monitor> todosMonitores = widget.monitorService.getTodosMonitores();

    for (int i = 0; i < todosMonitores.length; i++) {
      String nomeMonitor = todosMonitores[i].nome.split('-').first.trim();
      Color cor = _gerarCor(i); // gera cor com alta saturação e baixo brilho para ser legível
      _coresMap[nomeMonitor] = cor;
    }
  }

  Color _gerarCor(int index) {
    double hue = (index * 137.5) % 360;
    double saturation = 0.8; 
    double lightness = 0.4; 
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor(); 
  }

  @override
  Widget build(BuildContext context) {
    String diaAtual = _obterDiaAtual();
    String horarioMaisProximo = _obterHorarioMaisProximo(widget.horarios);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 225,
        ),
        child: Column(
          children: [
            DataTable(
              columnSpacing: 5,
              dataRowMaxHeight: 30,
              dataRowMinHeight: 20,
              columns: [
                const DataColumn(label: Center(child: Text(''))),
                ...diasDaSemana.map((dia) => DataColumn(
                      label: Flexible(
                        child: Center(
                          child: Text(
                            dia,
                            style: TextStyle(
                              fontSize: 11,
                              color: dia == diaAtual ? Colors.red : Colors.black, // dia da semana atual fica em vermelho
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
              rows: widget.horarios.map((horario) {
                return DataRow(
                  cells: [
                    DataCell(
                      Center(
                        child: Text(
                          horario,
                          style: TextStyle(
                            fontSize: 9,
                            color: horario == horarioMaisProximo ? Colors.red : Colors.black, // horário mais próximo fica vermelho
                          ),
                        ),
                      ),
                    ),
                    ...diasDaSemana.map((dia) {
                      String monitoresNoHorario = _obterMonitoresPorDiaEHorario(dia, horario); // conteudo da célula
                      return DataCell(
                        Center(
                          child: SizedBox(
                            width: 90,
                            child: _buildMonitoresText(monitoresNoHorario),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 10), // Espaçamento entre a tabela e o texto
            ObservacaoWidget(observacao: widget.observacao),
          ],
        ),
      ),
    );
  }

  String _obterDiaAtual() {
    DateTime now = DateTime.now();
    List<String> dias = ["Domingo","Segunda","Terça","Quarta","Quinta","Sexta","Sábado"];
    return dias[now.weekday % 7];
  }

  String _obterHorarioMaisProximo(List<String> horariosList) {
    DateTime now = DateTime.now();
    String horarioMaisProximo = horariosList.first;
    Duration menorDiferenca = const Duration(hours: 23, minutes: 59);

    for (String horario in horariosList) {
      DateTime horarioAtual = _parseHorario(horario);
      Duration diferenca = horarioAtual.difference(now).abs();

      if (diferenca < menorDiferenca) {
        menorDiferenca = diferenca;
        horarioMaisProximo = horario;
      }
    }
    return horarioMaisProximo;
  }

  DateTime _parseHorario(String horario) {
    List<String> parts = horario.split(":");
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
  }

  String _obterMonitoresPorDiaEHorario(String dia, String horario) {
    List<String> monitoresDisponiveis = [];
    Map<String, String> monitoresESalas = {};

    // Mapeia monitores com as salas
    for (var monitor in widget.monitores) {
      List<String> horariosFiltrados =
          monitor.horarios[dia.toLowerCase()] ?? [];

      for (String h in horariosFiltrados) {
        final parts = h.split(' ');
        String time = parts[0];
        String location = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        if (time == horario) {
          monitoresESalas[monitor.nome] = location;
        }
      }
    }

    String salaComum = '';
    bool mesmaSala = true;
    for (var entry in monitoresESalas.entries) {
      String nome = entry.key;
      String sala = entry.value;

      monitoresDisponiveis.add(nome);

      if (salaComum.isEmpty) {
        salaComum = sala;
      } else if (salaComum != sala) {
        mesmaSala = false;
      }
    }

    // Se todos os monitores estão na mesma sala e há uma sala definida
    if (mesmaSala && salaComum.isNotEmpty) {
      return '${monitoresDisponiveis.join(", ")} $salaComum';
    }

    // Caso contrário, lista cada monitor com sua respectiva sala (ou sem sala se não definida)
    return monitoresDisponiveis.map((monitor) {
      String sala = monitoresESalas[monitor] ?? '';
      return sala.isNotEmpty ? '$monitor $sala' : monitor;
    }).join(", ");
  }

  Widget _buildMonitoresText(String monitoresNoHorario) {
    List<String> monitores = monitoresNoHorario.split(", ");
    List<InlineSpan> spans = [];

    for (int i = 0; i < monitores.length; i++) {
      String monitor = monitores[i];

      // Pega apenas o nome antes do '-' para a cor
      String nomeMonitor = monitor.split('-').first.trim();

      if (nomeMonitor.isNotEmpty) {
        Color cor = _coresMap[nomeMonitor] ?? Colors.black; // Cor padrão se não encontrado
        spans.add(
          TextSpan(
            text: monitor + (i < monitores.length - 1 ? ', ' : ''), // separação entre monitores
            style: TextStyle(color: cor),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 10),
        children: spans,
      ),
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
    );
  }
}

class ObservacaoWidget extends StatelessWidget {
  final String observacao;

  const ObservacaoWidget({required this.observacao, super.key});

  void _abrirLink(String url) async {
    final Uri uri = Uri.parse(url); // Cria um Uri a partir da string
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri); // Abre o link
    } 
  }

  @override
  Widget build(BuildContext context) {
    String textoAntesDoLink = observacao;
    String? link;
    String textoDepoisDoLink = '';

    // Verifica se a observação contém um link (marcado pelo ->)
    if (observacao.contains('->')) {
      final partes = observacao.split('->');
      textoAntesDoLink = partes.first.trim(); // Parte antes do link
      link = partes.last.trim(); // Parte do link

      if (link.contains('\n')) { // vê se pulou de linha
        final partesLink = link.split('\n');
        link = partesLink.first.trim();
        textoDepoisDoLink =
            partesLink.sublist(1).join('\n').trim(); // Parte após o link
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Colors.black),
        children: [
          TextSpan(
            text: textoAntesDoLink,
          ),
          if (link != null) ...[
            const TextSpan(text: ' -> ',),
            TextSpan(
              text: link,
              style: const TextStyle(color: Colors.blue), // texto com link em azul
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _abrirLink(link!); // Abre o link dinâmico
                },
            ),
          ],
          if (textoDepoisDoLink.isNotEmpty) ...[
            const TextSpan(text: '\n'), // Adiciona uma quebra de linha
            TextSpan(
              text: textoDepoisDoLink,
              style: const TextStyle(
                  color: Colors.black), // Mantém o texto após o link em preto
            ),
          ],
        ],
      ),
    );
  }
}