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
      int duracaoMonitoria = _monitorService.getDuracaoMonitoriaPorMateria(materia);
      List<Monitor> monitoresPorMateria = _monitorService.getMonitoresPorMateria(materia);

      for (var monitor in monitoresPorMateria) {
        List<String>? horariosDoDia = monitor.horarios[diaDaSemana];

        if (horariosDoDia != null && horariosDoDia.isNotEmpty) {
          for (String horario in horariosDoDia) {
            DateTime inicioHorario = DateFormat.Hm().parse(horario.split(' - ')[0]);
            DateTime inicioHorarioCompleto = DateTime(now.year, now.month,now.day, inicioHorario.hour, inicioHorario.minute);
            DateTime fimHorario = inicioHorarioCompleto.add(Duration(minutes: duracaoMonitoria));

            // Agrupando por disponibilidade 
            if (now.isAfter(inicioHorarioCompleto) && now.isBefore(fimHorario)) { // se está disponível
              if (!_disponiveisAgora.containsKey(materia)) { 
                _disponiveisAgora[materia] = []; // inicializa a lista se a chave não existir
              }
              _disponiveisAgora[materia]!.add(monitor);
              break;
            }
            // Agrupando por disponibilidade mais tarde
            else if (inicioHorarioCompleto.isAfter(now)) {
              if (!_disponiveisMaisTarde.containsKey(materia)) {
                _disponiveisMaisTarde[materia] = []; // inicializa a lista se a chave não existir
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
                            builder: (context) => const MonitoriaMateriaPage(materia: 'alimentos')), // lista de monitores de alimentos (pela ordem alfabética)
                      );
                    },
                    child: const Text('Ver Monitoria por matéria'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCarousel(Map<String, List<Monitor>> monitoresMap, String title, Color cardColor, bool isAvailableLater) {
    final PageController _pageController = PageController(viewportFraction: 0.75);
    // Verifica se o mapa de monitores está vazio para avisar ao usuário
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
                    ? "Não há monitores disponíveis mais tarde de hoje."
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

                  // horário mais cedo que monitoria está disponível até horário mais tarde que ela dura em seguida
                  String disponibilidadeComum = _getCardAvailabilityText(monitores, materia);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MonitoriaMateriaPage(materia: materia), // clicar em uma matéria vai para a página de monitoria dela
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
                            // exibe o nome da matéria em cima do card
                            Text(
                              materiasComAcento[materia]!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // exibe os avatares dos monitores em linha
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: monitores
                                  .map((monitor) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundImage:
                                              NetworkImage(monitor.avatar),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            // Exibir os nomes dos monitores em linha separados por vírgula
                            Text(
                              monitores
                                  .map((monitor) => monitor.nome)
                                  .join(", "),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Spacer(), // coloca o texto de disponibilidade só no fundo
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
                  onPressed: () { // volta
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
                  onPressed: () { // avança
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

  String _getCardAvailabilityText(List<Monitor> monitores, String materia) {
    DateTime now = DateTime.now();
    String diaDaSemana = DateFormat('EEEE', 'pt_BR').format(now).replaceAll("-feira", "").trim();

    DateTime? fimDisponibilidade;
    DateTime? inicioDisponibilidade;
    String? localAtual;
    int duracaoMonitoria = _monitorService.getDuracaoMonitoriaPorMateria(materia);

   // horário mais cedo até o mais tarde consecutivo
    for (var monitor in monitores) { 
      if (monitor.horarios[diaDaSemana] != null) {
        List<String> horarios = monitor.horarios[diaDaSemana]!;

        for (int i = 0; i < horarios.length; i++) {
          List<String> horarioLocal = horarios[i].split(' - ');
          String horarioSemLocal = horarioLocal[0];
          String local = horarioLocal.length > 1 ? horarioLocal[1].trim() : '';

          // converte para dateTime
          DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
          DateTime inicioHorarioCompleto = DateTime(now.year, now.month,now.day, inicioHorario.hour, inicioHorario.minute);
          DateTime fimHorario = inicioHorarioCompleto.add(Duration(minutes: duracaoMonitoria));

          // Verificar se agora está entre o horário de início e fim
          if (now.isAfter(inicioHorarioCompleto) && now.isBefore(fimHorario)) {
            fimDisponibilidade = fimHorario;
            localAtual = local;

            // Verificar horários consecutivos
            for (int j = i + 1; j < horarios.length; j++) {
              List<String> proximoHorarioLocal = horarios[j].split(' - ');
              String proximoHorarioSemLocal = proximoHorarioLocal[0];
              DateTime proximoInicioHorario = DateFormat.Hm('pt_BR').parse(proximoHorarioSemLocal);
              DateTime proximoInicioCompleto = DateTime(now.year,now.month,now.day,proximoInicioHorario.hour,proximoInicioHorario.minute);

              // monitorias de 45 minutos tem 15 minutos de intervalo
              if (duracaoMonitoria == 45 &&
                  fimHorario.isAfter(proximoInicioCompleto.subtract(const Duration(minutes: 15)))) {
                fimDisponibilidade = proximoInicioCompleto.add(const Duration(minutes: 45));
              } else {
                break;
              }
            }

            return 'Disponível agora até ${DateFormat.Hm('pt_BR').format(fimDisponibilidade!)} - $localAtual';
          } else if (inicioHorarioCompleto.isAfter(now) &&
              inicioDisponibilidade == null) {
            inicioDisponibilidade = inicioHorarioCompleto;
            localAtual = local;
            break;
          }
        }
      }
    }

    if (fimDisponibilidade != null) {
      return 'Disponível agora até ${DateFormat.Hm('pt_BR').format(fimDisponibilidade)} - $localAtual';
    } else if (inicioDisponibilidade != null) {
      return 'Disponível às ${DateFormat.Hm('pt_BR').format(inicioDisponibilidade)} - $localAtual';
    } else {
      return 'Não disponível hoje';
    }
  }
}
