import 'package:cotucapocket/monitoria_calendario.dart';
import 'package:flutter/material.dart';
import 'models/monitor.dart';
import 'services/monitor_service.dart';
import 'components.dart';
import 'package:intl/intl.dart';

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
        title: Text(
            'Monitoria - ${materias[_selectedMateria!]}'), 
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
                                  onMonitorTap: (monitor) => _navigateToMonitorDetails(monitor),
                                  duracaoMonitoria: _monitorService.getDuracaoMonitoriaPorMateria(_selectedMateria!)),
                            ),
                            const SizedBox(height: 30),
                            MonitorScheduleTable(
                              monitores: _monitoresPorMateria,
                              observacao: _monitorService.getObservacaoPorMateria(_selectedMateria!),
                              horarios: _monitorService.getHorariosPorMateria(_selectedMateria!),
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
          duracaoMonitoria: _monitorService.getDuracaoMonitoriaPorMateria(_selectedMateria!),
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}

class MonitorDetailView extends StatelessWidget {
  final Monitor monitor;
  final int duracaoMonitoria; 

  const MonitorDetailView({
    super.key,
    required this.monitor,
    required this.duracaoMonitoria, 
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
        .parse(a.split(' ')[0])
        .compareTo(DateFormat.Hm('pt_BR').parse(b.split(' ')[0])));

    List<String> grouped = [];
    String? currentStart;
    String? currentEnd;
    String? currentLocation;

    for (String horario in horarios) {
      final parts = horario.split(' ');
      String time = parts[0];
      String location = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      // Se não esta agrupando, crie um novo grupo
      if (currentStart == null) {
        currentStart = time;
        currentEnd = time;
        currentLocation = location;
      } else {
        DateTime lastEndTime = DateFormat.Hm('pt_BR').parse(currentEnd!); 
        DateTime currentTimeParsed = DateFormat.Hm('pt_BR').parse(time);

        // Agrupa se os horários estão no mesmo local (se existir) e consecutivos
        if ((currentTimeParsed.isAtSameMomentAs(lastEndTime) ||
            (currentTimeParsed.isAfter(lastEndTime) &&
                currentTimeParsed.isBefore(lastEndTime.add(Duration(minutes: 61))) && 
                (currentLocation == location ||currentLocation!.isEmpty || location.isEmpty)))) {
          currentEnd = time; // Atualiza o fim do horário
        } else {
          // Adiciona o grupo atual e inicia um novo
          grouped.add(
              '$currentStart-${DateFormat.Hm('pt_BR').format(DateFormat.Hm('pt_BR').parse(currentEnd).add(Duration(minutes: duracaoMonitoria)))}${currentLocation!.isNotEmpty ? ' $currentLocation' : ''}');
          currentStart = time;
          currentEnd = time;
          currentLocation = location;
        }
      }
    }

    // Adiciona o último grupo se existir
    if (currentStart != null && currentEnd != null) {
      grouped.add(
          '$currentStart-${DateFormat.Hm('pt_BR').format(DateFormat.Hm('pt_BR').parse(currentEnd).add(Duration(minutes: duracaoMonitoria)))}${currentLocation!.isNotEmpty ? ' $currentLocation' : ''}');
    }

    return grouped;
  }
}
