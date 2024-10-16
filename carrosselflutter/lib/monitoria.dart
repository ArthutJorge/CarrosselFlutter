import 'package:flutter/material.dart';
import 'models/monitor.dart';
import 'services/monitor_service.dart';
import 'monitoria_materia.dart';
import 'package:intl/intl.dart';

class MonitoriaPage extends StatefulWidget {
  const MonitoriaPage({super.key});

  @override
  _MonitoriaPageState createState() => _MonitoriaPageState();
}

class _MonitoriaPageState extends State<MonitoriaPage> {
  final MonitorService _monitorService = MonitorService();
  Map<String, List<Monitor>> _disponiveisAgora = {};
  Map<String, List<Monitor>> _disponiveisMaisTarde = {};
  bool _isLoading = true;

  final Map<String, String> materiasComAcento = {
    'matematica': 'Matemática',
    'ingles': 'Inglês',
    'fisica': 'Física',
    'educacaoFisica': 'Educação Física',
    'artes': 'Artes',
    'humanas': 'Humanas',
    'portugues': 'Português',
    'biologia': 'Biologia',
    'quimica': 'Química',
    'segurancaTrabalho': 'Segurança do Trabalho',
    'meioAmbiente': 'Meio Ambiente',
    'mecatronica': 'Mecatrônica',
    'informatica': 'Informática',
    'enfermagem': 'Enfermagem',
    'eletronica': 'Eletrônica',
    'alimentos': 'Alimentos',
  };

  final List<String> materias = [
    'matematica',
    'ingles',
    'fisica',
    'educacaoFisica',
    'artes',
    'humanas',
    'portugues',
    'biologia',
    'quimica',
    'segurancaTrabalho',
    'meioAmbiente',
    'mecatronica',
    'informatica',
    'enfermagem',
    'eletronica',
    'alimentos'
  ];
  @override
  void initState() {
    super.initState();
    _fetchMonitores();
  }

  Future<void> _fetchMonitores() async {
    await _monitorService.fetchMonitores();
    _disponiveisAgora = {};
    _disponiveisMaisTarde = {};

    DateTime now = DateTime.now();
    String diaDaSemana = _getDiaDaSemana(now);

    for (var materia in materias) {
      List<Monitor> monitoresPorMateria =
          _monitorService.getMonitoresPorMateria(materia);

      for (var monitor in monitoresPorMateria) {
        List<String>? horariosDoDia = monitor.horarios[diaDaSemana];

        if (horariosDoDia != null && horariosDoDia.isNotEmpty) {
          for (String horario in horariosDoDia) {
            DateTime inicioHorario =
                DateFormat.Hm().parse(horario.split(' - ')[0]);
            DateTime inicioHorarioCompleto = DateTime(now.year, now.month,
                now.day, inicioHorario.hour, inicioHorario.minute);
            DateTime fimHorario =
                inicioHorarioCompleto.add(const Duration(minutes: 45));

            // Agrupando por disponibilidade agora
            if (now.isAfter(inicioHorarioCompleto) &&
                now.isBefore(fimHorario)) {
              if (!_disponiveisAgora.containsKey(materia)) {
                _disponiveisAgora[materia] = [];
              }
              _disponiveisAgora[materia]!.add(monitor);
              break;
            }
            // Agrupando por disponibilidade mais tarde
            else if (inicioHorarioCompleto.isAfter(now)) {
              if (!_disponiveisMaisTarde.containsKey(materia)) {
                _disponiveisMaisTarde[materia] = [];
              }
              _disponiveisMaisTarde[materia]!.add(monitor);
              break;
            }
          }
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getDiaDaSemana(DateTime data) {
    return DateFormat('EEEE', 'pt_BR')
        .format(data)
        .replaceAll("-feira", "")
        .trim();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoria'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildCarousel(_disponiveisAgora, "Disponíveis Agora",
                      Colors.green[100]!, false),
                  _buildCarousel(_disponiveisMaisTarde,
                      "Disponíveis Mais Tarde", Colors.yellow[100]!, true),
                  const SizedBox(height: 16), // Espaço antes do botão
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MonitoriaMateriaPage(
                                materia: 'alimentos')),
                      );
                    },
                    child: const Text('Ver Monitoria por matéria'),
                  ),
                ],
              ),
            ),
    );
  }

Widget _buildCarousel(Map<String, List<Monitor>> monitoresMap, String title,
    Color cardColor, bool isAvailableLater) {
      
    final PageController _pageController = PageController(viewportFraction: 0.75);
  // Verifica se o mapa de monitores está vazio
  if (monitoresMap.isEmpty) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.grey,
              size: 60,
            ),
            const SizedBox(height: 8),
            Text(
              isAvailableLater
                  ? "Não há monitores disponíveis hoje."
                  : "Não há monitores disponíveis agora.",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: monitoresMap.length,
              itemBuilder: (context, index) {
                String materia = monitoresMap.keys.elementAt(index);
                List<Monitor> monitores = monitoresMap[materia]!;

                // Obter a disponibilidade comum
                String disponibilidadeComum = _getCardAvailabilityText(monitores);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonitoriaMateriaPage(materia: materia),
                      ),
                    );
                  },
                  child: Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // Exibir o nome da matéria em cima do card
                          Text(
                            materiasComAcento[materia]!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Exibir os avatares dos monitores em linha
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: monitores
                                .map((monitor) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundImage: NetworkImage(monitor.avatar),
                                      ),
                                    ))
                                .toList(),
                          ),
                          // Exibir os nomes dos monitores em linha separados por vírgula
                          Text(
                            monitores.map((monitor) => monitor.nome).join(", "),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Spacer(), // Para empurrar o texto para o fundo
                          Text(
                            disponibilidadeComum,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
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
    ],
  );
}


  String _getCardAvailabilityText(List<Monitor> monitores) {
    DateTime now = DateTime.now();
    String diaDaSemana = _getDiaDaSemana(now);

    DateTime? fimDisponibilidade;
    DateTime? inicioDisponibilidade;

    for (var monitor in monitores) {
      List<String> horarios = monitor.horarios[diaDaSemana]!;
      for (String horario in horarios) {
        List<String> horarioLocal = horario.split(' - ');
        String horarioSemLocal = horarioLocal[0];
        DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
        DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day,
            inicioHorario.hour, inicioHorario.minute);
        DateTime fimHorario =
            inicioHorarioCompleto.add(const Duration(minutes: 45));

        if (now.isAfter(inicioHorarioCompleto) && now.isBefore(fimHorario)) {
          // Monitor disponível agora
          fimDisponibilidade = fimHorario;
          break;
        } else if (inicioHorarioCompleto.isAfter(now)) {
          // Monitor disponível mais tarde
          inicioDisponibilidade = inicioHorarioCompleto;
          break;
        }
      }
    }

    if (fimDisponibilidade != null) {
      return 'Disponível agora até ${DateFormat.Hm('pt_BR').format(fimDisponibilidade)}';
    } else if (inicioDisponibilidade != null) {
      return 'Disponível às ${DateFormat.Hm('pt_BR').format(inicioDisponibilidade)}';
    } else {
      return 'Não disponível hoje';
    }
  }
}
