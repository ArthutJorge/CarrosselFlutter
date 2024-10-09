import 'package:flutter/material.dart';
import 'monitor.dart';
import 'monitor_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('pt_BR', null).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monitores DPD',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final MonitorService _monitorService = MonitorService();
  late Future<List<Monitor>> _monitores;
  final PageController _pageController = PageController(viewportFraction: 0.75);

  @override
  void initState() {
    super.initState();
    _monitores = _monitorService.fetchMonitores();
  }

  void _navigateToMonitorDetails(Monitor monitor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonitorDetailView(monitor: monitor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitores DPD'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _monitores = _monitorService.fetchMonitores();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Monitor>>(
        future: _monitores,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum monitor encontrado.'));
          }

          List<Monitor> _monitoresList = snapshot.data!;

          return SingleChildScrollView( // Permite scroll vertical na página
            child: Column(
              children: [
                // Espaço para as setas de navegação
                const SizedBox(height: 50), // Espaço vazio para setas

                // Parte superior - carrossel
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: _monitoresList.length,
                        itemBuilder: (context, index) {
                          final monitor = _monitoresList[index];
                          return GestureDetector(
                            onTap: () => _navigateToMonitorDetails(monitor),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: _getCardColor(monitor),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage: NetworkImage(monitor.avatar),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    monitor.nome,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _getCardAvailabilityText(monitor),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        left: 16,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_left),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Parte inferior - tabela de horários
                MonitorScheduleTable(monitores: _monitoresList),
                const SizedBox(height: 30)
              ],
            ),
          );
        },
      ),
    );
  }

Color _getCardColor(Monitor monitor) {
  DateTime now = DateTime.now();
  String diaDaSemana = DateFormat('EEEE', 'pt_BR').format(now).replaceAll("-feira", "").trim();

  // Verificar se o monitor está disponível agora
  if (monitor.horarios[diaDaSemana] != null) {
    for (String horario in monitor.horarios[diaDaSemana]!) {
      DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horario);
      DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
      DateTime fimHorario = inicioHorarioCompleto.add(Duration(minutes: 45));

      if (now.isAfter(inicioHorarioCompleto) && now.isBefore(fimHorario)) {
        // Se está trabalhando agora, retorna verde
        return Colors.green[100]!;
      }
    }
  }

  // Verificar horários futuros
  List<String>? horariosFuturos = monitor.horarios[diaDaSemana];
  if (horariosFuturos != null) {
    for (String horario in horariosFuturos) {
      DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horario);
      DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
      if (inicioHorarioCompleto.isAfter(now)) {
        // Se há um horário futuro, retorna amarelo
        return Colors.yellow[100]!;
      }
    }
  }

  // Se não há horários disponíveis hoje, retorna cinza
  return Colors.grey[300]!;
}

String _getCardAvailabilityText(Monitor monitor) {
  DateTime now = DateTime.now();
  String diaDaSemana = DateFormat('EEEE', 'pt_BR').format(now).replaceAll("-feira", "").trim();
  
  if (monitor.horarios[diaDaSemana] != null) {
    List<String> horarios = monitor.horarios[diaDaSemana]!;
    DateTime fimDisponibilidade;

    for (int i = 0; i < horarios.length; i++) {
      DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarios[i]);
      DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
      DateTime fimHorario = inicioHorarioCompleto.add(Duration(minutes: 45));

      // Verificar se agora está entre o horário de início e fim
      if (now.isAfter(inicioHorarioCompleto) && now.isBefore(fimHorario)) {
        // Se está trabalhando agora, calcula o fim do horário
        fimDisponibilidade = fimHorario;
        
        // Verifica se há horários consecutivos
        for (int j = i + 1; j < horarios.length; j++) {
          DateTime proximoInicioHorario = DateFormat.Hm('pt_BR').parse(horarios[j]);
          DateTime proximoInicioCompleto = DateTime(now.year, now.month, now.day, proximoInicioHorario.hour, proximoInicioHorario.minute);

          // Verifica a tolerância de 15 minutos
          if (fimHorario.isAfter(proximoInicioCompleto.subtract(Duration(minutes: 15)))) {
            // Se está dentro do intervalo tolerado, atualiza o fim da disponibilidade
            fimDisponibilidade = proximoInicioCompleto.add(Duration(minutes: 45));
          } else {
            // Se o intervalo não é tolerado, sai do loop
            break;
          }
        }
        return 'Disponível agora até ${DateFormat.Hm('pt_BR').format(fimDisponibilidade)}';
      }
    }

    // Verificar horários futuros
    for (String horario in horarios) {
      DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horario);
      DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
      if (inicioHorarioCompleto.isAfter(now)) {
        return 'Disponível às $horario';
      }
    }
  }

  // Se não há horários disponíveis hoje
  return 'Não disponível hoje';
}



}



class MonitorScheduleTable extends StatelessWidget {
  final List<Monitor> monitores;

  MonitorScheduleTable({super.key, required this.monitores});

  final List<String> horariosList = [
    "7:30", "8:15", "9:00", "10:00", "10:45", "11:30", "12:15", "13:30",
    "14:15", "15:00", "16:00", "16:45", "17:30", "18:15", "19:00",
    "19:45", "20:30", "21:30", "22:15"
  ];

  final List<String> diasDaSemana = [
    "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Habilita o scroll horizontal
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 700, // Define uma largura mínima para a tabela
        ),
        child: DataTable(
          columnSpacing: 10, // Espaçamento entre colunas
          columns: [
            const DataColumn(label: Text('')),
            ...diasDaSemana.map((dia) => DataColumn(label: Text(dia))),
          ],
          rows: horariosList.map((horario) {
            return DataRow(
              cells: [
                DataCell(Text(horario)),
                ...diasDaSemana.map((dia) {
                  String monitoresNoHorario = _obterMonitoresPorDiaEHorario(dia, horario);
                  return DataCell(Text(monitoresNoHorario.isNotEmpty ? monitoresNoHorario : '-'));
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _obterMonitoresPorDiaEHorario(String dia, String horario) {
    List<String> monitoresDisponiveis = [];

    for (var monitor in monitores) {
      if (monitor.horarios[dia.toLowerCase()]?.contains(horario) ?? false) {
        monitoresDisponiveis.add(monitor.nome);
      }
    }

    return monitoresDisponiveis.join(", ");
  }
}

class MonitorDetailView extends StatelessWidget {
  final Monitor monitor;

  const MonitorDetailView({super.key, required this.monitor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horários de ${monitor.nome}'),
        centerTitle: true,
        backgroundColor: Colors.redAccent, // Cor do AppBar
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
            Text(
              'Horários:',
              style: const TextStyle(
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

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        dia.capitalize(), // Método para capitalizar a primeira letra
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        horarios.join(', '),
                        style: const TextStyle(fontSize: 16),
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
}

// Extensão para capitalizar a primeira letra de uma string
extension StringCasingExtension on String {
  String capitalize() {
    return this.isEmpty
        ? this
        : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}
