import 'package:flutter/material.dart';
import 'models/monitor.dart';
import 'services/monitor_service.dart';
import 'components.dart'; // Certifique-se de que seus componentes estão importados corretamente
import 'package:intl/intl.dart';

class MonitoriaMateriaPage extends StatefulWidget {
  final String materia;
  MonitoriaMateriaPage({required this.materia});

  @override
  _MonitoriaMateriaPageState createState() => _MonitoriaMateriaPageState();
}

class _MonitoriaMateriaPageState extends State<MonitoriaMateriaPage> {
  late List<Monitor> _monitoresPorMateria;
  final MonitorService _monitorService = MonitorService();
  bool _isLoading = true;
  String? _selectedMateria;

  final List<String> materias = ['matematica', 'ingles', 'fisica', 'educacaoFisica', 'artes', 'historia', 'portugues', 'biologia', 'quimica', 'segurancaTrabalho', 'meioAmbiente', 'mecatronica', 'informatica', 'enfermagem', 'eletronica', 'alimentos'
  ];

  @override
  void initState() {
    super.initState();
    _selectedMateria = widget.materia;
    _fetchMonitores();
  }

  Future<void> _fetchMonitores() async {
    await _monitorService.fetchMonitores();
    setState(() {
      _monitoresPorMateria = _monitorService.getMonitoresPorMateria(_selectedMateria!);
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
        title: Text('Monitoria - ${StringCasingExtension(widget.materia).capitalize()}'), // Usa capitalize aqui
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedMateria,
              items: materias.map((materia) {
                return DropdownMenuItem<String>(
                  value: materia,
                  child: Text(
                    StringCasingExtension(materia.replaceAll(RegExp(r'([A-Z])'), ' ').trim()).capitalize(),
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
                                onMonitorTap: (monitor) => _navigateToMonitorDetails(monitor),
                                calendarioTipo: _monitorService.getCalendarioTipoPorMateria(_selectedMateria!)
                              ),
                            ),
                            const SizedBox(height: 30),
                            MonitorScheduleTable(monitores: _monitoresPorMateria, 
                            calendarioTipo: _monitorService.getCalendarioTipoPorMateria(_selectedMateria!),),
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
        builder: (context) => MonitorDetailView(monitor: monitor, calendarioTipo: _monitorService.getCalendarioTipoPorMateria(_selectedMateria!), ),
      ),
    );
  }
}

// Extensão para capitalizar a primeira letra de uma string
extension StringCasingExtension on String {
  String capitalize() {
    return this.isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}


class MonitorScheduleTable extends StatelessWidget {
  final List<Monitor> monitores;
  final int calendarioTipo; // Adiciona calendárioTipo como parâmetro

  MonitorScheduleTable({super.key, required this.monitores, required this.calendarioTipo});


  List<String> _gerarHorarios() {
    
    if (calendarioTipo == 30) {
      List<String> horarios = [];
      DateTime inicio = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 7, 30);
      
      for (int i = 0; i < 31; i++) {
        horarios.add('${inicio.hour}:${inicio.minute.toString().padLeft(2, '0')}');
        inicio = inicio.add(Duration(minutes: 30));
      }
      return horarios;
    } else {
      // Retorna horários padrão
      return [
        "7:30", "8:15", "9:00", "10:00", "10:45", "11:30", "12:15", 
        "13:30", "14:15", "15:00", "16:00", "16:45", "17:30", "18:15", 
        "19:00", "19:45", "20:30", "21:30", "22:15"
      ];
    }
  }

  final List<String> diasDaSemana = [
    "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"
  ];

 @override
Widget build(BuildContext context) {
  List<String> horariosList = _gerarHorarios(); // Gera horários com base no tipo de calendário
  String diaAtual = _obterDiaAtual();
  String horarioMaisProximo = _obterHorarioMaisProximo(horariosList);

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
                    ))),
                  )),
            ],
            rows: horariosList.map((horario) {
              return DataRow(
                cells: [
                  DataCell(Center(
                      child: Text(
                    horario,
                    style: TextStyle(
                      fontSize: 9,
                      color: horario == horarioMaisProximo
                          ? Colors.red
                          : Colors.black,
                    ),
                  ))),
                  ...diasDaSemana.map((dia) {
                    String monitoresNoHorario =
                        _obterMonitoresPorDiaEHorario(dia, horario);
                    return DataCell(
                      Center(
                        child: SizedBox(
                          width: 90,
                          child: Text(
                            monitoresNoHorario.isNotEmpty
                                ? monitoresNoHorario
                                : '-',
                            style: TextStyle(fontSize: 10),
                            overflow: TextOverflow.visible,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 10), // Espaçamento entre a tabela e o texto
          const Text(
            '** - Monitoria online Discord',
            style: TextStyle(fontSize: 12), // Ajuste o tamanho conforme necessário
          ),
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
    Duration menorDiferenca = Duration(hours: 23, minutes: 59);

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

    for (var monitor in monitores) {
      List<String> horariosFiltrados =
          monitor.horarios[dia.toLowerCase()] ?? [];

      for (String h in horariosFiltrados) {
        final parts = h.split(' ');
        String time = parts[0];
        String location = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        if (time == horario) {
          if (location.isNotEmpty) {
            monitoresDisponiveis.add('${monitor.nome} $location');
          } else {
            monitoresDisponiveis.add(monitor.nome);
          }
        }
      }
    }

    return monitoresDisponiveis.join(", ");
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
                    return const SizedBox.shrink(); // Não exibe nada se não houver horários
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
      String location = parts.length > 1
          ? parts.sublist(1).join(' ')
          : '';

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
                    .isBefore(lastEndTime.add(Duration(minutes: 30))) &&
                (currentLocation == location ||
                    currentLocation!.isEmpty ||
                    location.isEmpty)))) {
          currentEnd = time; // Atualiza o fim do horário
        } else {
          // Adiciona o grupo atual e inicia um novo
          grouped.add(
              '${currentStart}-${DateFormat.Hm('pt_BR').format(DateFormat.Hm('pt_BR').parse(currentEnd!).add(Duration(minutes: 45)))}${currentLocation!.isNotEmpty ? ' $currentLocation' : ''}');
          currentStart = time;
          currentEnd = time;
          currentLocation = location;
        }
      }
    }

    // Adiciona o último grupo se existir
    if (currentStart != null && currentEnd != null) {
      grouped.add(
          '${currentStart}-${DateFormat.Hm('pt_BR').format(DateFormat.Hm('pt_BR').parse(currentEnd!).add(Duration(minutes: 45)))}${currentLocation!.isNotEmpty ? ' $currentLocation' : ''}');
    }

    return grouped;
  }
}
