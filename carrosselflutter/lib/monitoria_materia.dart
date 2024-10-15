import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'models/monitor.dart';
import 'services/monitor_service.dart';
import 'components.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MonitoriaMateriaPage extends StatefulWidget {
  final String materia;
  const MonitoriaMateriaPage({super.key, required this.materia});

  @override
  _MonitoriaMateriaPageState createState() => _MonitoriaMateriaPageState();
}

class _MonitoriaMateriaPageState extends State<MonitoriaMateriaPage> {
  late List<Monitor> _monitoresPorMateria;
  final MonitorService _monitorService = MonitorService();
  bool _isLoading = true;
  String? _selectedMateria;

  final Map<String, String> materias = {
  'alimentos': 'Alimentos',
  'artes': 'Artes',
  'biologia': 'Biologia',
  'educacaoFisica': 'Educação Física',
  'eletroeletronica': 'Eletroeletrônica',
  'enfermagem': 'Enfermagem',
  'fisica': 'Física',
  'humanas': 'Humanas',
  'ingles': 'Inglês',
  'informatica': 'Informática',
  'matematica': 'Matemática',
  'meioAmbiente': 'Meio Ambiente',
  'mecatronica': 'Mecatrônica',
  'quimica': 'Química',
  'segurancaTrabalho': 'Segurança do Trabalho',
  'portugues': 'Português',
};

  @override
  void initState() {
    super.initState();
    _selectedMateria = widget.materia;
    _fetchMonitores();
  }

  Future<void> _fetchMonitores() async {
    await _monitorService.fetchMonitores();
    setState(() {
      _monitoresPorMateria =
          _monitorService.getMonitoresPorMateria(_selectedMateria!);
      _isLoading = false;
    });
  }

  void _onMateriaChanged(String? newMateria) {
    setState(() {
      _selectedMateria = newMateria;
      _isLoading = true;
    });
    _fetchMonitores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Monitoria - ${StringCasingExtension(widget.materia).capitalize()}'), // Usa capitalize aqui
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedMateria,
              items: materias.keys.map((materiaKey) {
                return DropdownMenuItem<String>(
                  value: materiaKey,
                  child: Text(
                    materias[materiaKey]!,
                  ),
                );
              }).toList(),
              onChanged: _onMateriaChanged,
              isExpanded: true,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _monitoresPorMateria.isEmpty
                    ? const Center(child: Text('Nenhum monitor encontrado.'))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 50),
                            SizedBox(
                              height: 200,
                              child: MonitorCarousel(
                                  monitores: _monitoresPorMateria,
                                  onMonitorTap: (monitor) =>
                                      _navigateToMonitorDetails(monitor),
                                  calendarioTipo: _monitorService
                                      .getCalendarioTipoPorMateria(
                                          _selectedMateria!)),
                            ),
                            const SizedBox(height: 30),
                            MonitorScheduleTable(
                              monitores: _monitoresPorMateria,
                              observacao: _monitorService
                                  .getObservacaoPorMateria(_selectedMateria!),
                              horarios: _monitorService
                                  .getHorariosPorMateria(_selectedMateria!),
                                  monitorService: _monitorService,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _navigateToMonitorDetails(Monitor monitor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonitorDetailView(
          monitor: monitor,
          calendarioTipo:
              _monitorService.getCalendarioTipoPorMateria(_selectedMateria!),
        ),
      ),
    );
  }
}

// Extensão para capitalizar a primeira letra de uma string
extension StringCasingExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}


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
  final List<String> diasDaSemana = [
    "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"
  ];

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
      Color cor = _gerarCor(i); // Gere a cor procedimentalmente
      _coresMap[nomeMonitor] = cor;
    }
  }
Color _gerarCor(int index) {
  double hue = (index * 137.5) % 360; 
  double saturation = 0.8; // Mantém a saturação alta para cores mais intensas
  double lightness = 0.4;  // Mantém a luminosidade baixa para evitar cores claras
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor(); // Cria a cor
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
              dataRowHeight: 30,
              columns: [
                const DataColumn(label: Center(child: Text(''))),
                ...diasDaSemana.map((dia) => DataColumn(
                      label: Flexible(
                        child: Center(
                          child: Text(
                            dia,
                            style: TextStyle(
                              fontSize: 11,
                              color: dia == diaAtual ? Colors.red : Colors.black,
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
                            color: horario == horarioMaisProximo
                                ? Colors.red
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    ...diasDaSemana.map((dia) {
                      String monitoresNoHorario =
                          _obterMonitoresPorDiaEHorario(dia, horario);
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
    List<String> dias = [
      "Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"
    ];
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
    return DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, hour, minute);
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
            text: monitor + (i < monitores.length - 1 ? ', ' : ''), // Usa o monitor completo, incluindo a sala
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

  // Função para abrir o link dinamicamente
  void _abrirLink(String url) async {
    final Uri uri = Uri.parse(url); // Cria um Uri a partir da string
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri); // Abre o link dinâmico
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    String textoAntesDoLink = observacao;
    String? link;
    String textoDepoisDoLink = '';

    // Verifica se a observação contém um link
    if (observacao.contains('->')) {
      final partes = observacao.split('->');
      textoAntesDoLink = partes.first.trim(); // Parte antes do link
      link = partes.last.trim(); // Parte do link

      if (link.contains('\n')) {
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
            const TextSpan(
              text: ' -> ',
            ),
            TextSpan(
              text: link,
              style: const TextStyle(color: Colors.blue),
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

class MonitorDetailView extends StatelessWidget {
  final Monitor monitor;
  final int calendarioTipo; // Novo parâmetro

  const MonitorDetailView({
    super.key,
    required this.monitor,
    required this.calendarioTipo, // Adicionado aqui
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horários de ${monitor.nome}'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(monitor.avatar),
            ),
            const SizedBox(height: 20),
            Text(
              monitor.nome,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Horários:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: monitor.horarios.length,
                itemBuilder: (context, index) {
                  String dia = monitor.horarios.keys.elementAt(index);
                  List<String> horarios = monitor.horarios[dia]!;

                  // Verifica se há horários para o dia
                  if (horarios.isEmpty) {
                    return const SizedBox
                        .shrink(); // Não exibe nada se não houver horários
                  }

                  // Agrupar horários seguidos
                  List<String> groupedHorarios = _groupHorarios(horarios);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        StringCasingExtension(dia).capitalize(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: groupedHorarios.map((horario) {
                          return Text(
                            horario,
                            style: const TextStyle(fontSize: 16),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _groupHorarios(List<String> horarios) {
    // Ordena os horários
    horarios.sort((a, b) => DateFormat.Hm('pt_BR')
        .parse(a)
        .compareTo(DateFormat.Hm('pt_BR').parse(b)));

    List<String> grouped = [];
    String? currentStart;
    String? currentEnd;
    String? currentLocation;

    for (String horario in horarios) {
      final parts = horario.split(' ');
      String time = parts[0];
      String location = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      // Se não estamos agrupando, inicie um novo grupo
      if (currentStart == null) {
        currentStart = time;
        currentEnd = time;
        currentLocation = location;
      } else {
        // Verifica se o horário atual é consecutivo ao último
        DateTime lastEndTime = DateFormat.Hm('pt_BR')
            .parse(currentEnd!)
            .add(Duration(minutes: calendarioTipo));

        DateTime currentTimeParsed = DateFormat.Hm('pt_BR').parse(time);

        // Agrupa se os horários são consecutivos ou estão no mesmo local
        if ((currentTimeParsed.isAtSameMomentAs(lastEndTime) ||
            (currentTimeParsed.isAfter(lastEndTime) &&
                currentTimeParsed
                    .isBefore(lastEndTime.add(const Duration(minutes: 30))) &&
                (currentLocation == location ||
                    currentLocation!.isEmpty ||
                    location.isEmpty)))) {
          currentEnd = time; // Atualiza o fim do horário
        } else {
          // Adiciona o grupo atual e inicia um novo
          grouped.add(
              '$currentStart-${DateFormat.Hm('pt_BR').format(DateFormat.Hm('pt_BR').parse(currentEnd).add(const Duration(minutes: 45)))}${currentLocation!.isNotEmpty ? ' $currentLocation' : ''}');
          currentStart = time;
          currentEnd = time;
          currentLocation = location;
        }
      }
    }

    // Adiciona o último grupo se existir
    if (currentStart != null && currentEnd != null) {
      grouped.add(
          '$currentStart-${DateFormat.Hm('pt_BR').format(DateFormat.Hm('pt_BR').parse(currentEnd).add(const Duration(minutes: 45)))}${currentLocation!.isNotEmpty ? ' $currentLocation' : ''}');
    }

    return grouped;
  }
}
