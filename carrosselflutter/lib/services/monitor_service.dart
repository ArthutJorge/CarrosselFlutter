import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/monitor.dart';

class MonitorService {
  final String apiUrl = 'http://localhost:9090/monitores';

  Map<String, List<Monitor>> monitoresPorMateria = {};
  Map<String, List<String>> horariosPorMateria = {}; // Para armazenar os horários de cada matéria
  Map<String, String> observacaoPorMateria = {}; // Para armazenar as observações de cada matéria
  Map<String, int> calendarioTipoPorMateria = {};

  Future<void> fetchMonitores() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> body = json.decode(response.body);

      body.forEach((materia, dadosDaMateria) {
        if (dadosDaMateria is Map<String, dynamic>) {
          calendarioTipoPorMateria[materia] = dadosDaMateria['calendarioTipo'];
          horariosPorMateria[materia] = List<String>.from(dadosDaMateria['horarios']);
          observacaoPorMateria[materia] = dadosDaMateria['observacao'] ?? "";

          List<Monitor> monitoresList = [];
          for (var monitorJson in dadosDaMateria['monitores']) {
            Monitor monitor = Monitor.fromJson(monitorJson);
            monitoresList.add(monitor);
          }
          monitoresPorMateria[materia] = monitoresList;
        }
      });
    } else {
      throw Exception('Falha ao carregar monitores');
    }
  }

  List<Monitor> getMonitoresPorMateria(String materia) {
    return monitoresPorMateria[materia] ?? [];
  }

  List<String> getHorariosPorMateria(String materia) {
    return horariosPorMateria[materia] ?? [];
  }

  String getObservacaoPorMateria(String materia) {
    return observacaoPorMateria[materia] ?? "";
  }

  int getCalendarioTipoPorMateria(String materia) {
  if (calendarioTipoPorMateria.containsKey(materia)) {
    return calendarioTipoPorMateria[materia] ?? 30; 
  }
  return 45; 
}

  List<Monitor> getTodosMonitores() {
    List<Monitor> todosMonitores = [];
    monitoresPorMateria.forEach((materia, monitores) {
      todosMonitores.addAll(monitores);
    });
    return todosMonitores;
  }
}