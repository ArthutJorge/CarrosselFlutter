import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/monitor.dart';

class MonitorService {
  final String apiUrl = 'https://cotuca-pocket-api.vercel.app/monitores';

  Map<String, List<Monitor>> monitoresPorMateria = {};
  Map<String, List<String>> horariosPorMateria = {}; 
  Map<String, String> observacaoPorMateria = {}; 
  Map<String, int> duracaoMonitoriaPorMateria = {};

  Future<void> fetchMonitores() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> body = json.decode(response.body);

      body.forEach((materia, dadosDaMateria) {
        if (dadosDaMateria is Map<String, dynamic>) {
          duracaoMonitoriaPorMateria[materia] = dadosDaMateria['duracaoMonitoria'];
          horariosPorMateria[materia] = List<String>.from(dadosDaMateria['horarios']);
          observacaoPorMateria[materia] = dadosDaMateria['observacao'];

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

  int getDuracaoMonitoriaPorMateria(String materia) {
  if (duracaoMonitoriaPorMateria.containsKey(materia)) {
    return duracaoMonitoriaPorMateria[materia] ?? 30; 
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