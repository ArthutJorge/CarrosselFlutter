import 'dart:convert';
import 'package:http/http.dart' as http;
import './monitor.dart';

class MonitorService {
  final String apiUrl = 'http://localhost:9090/monitores';

  Future<List<Monitor>> fetchMonitores() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((json) => Monitor.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load monitores');
    }
  }

  Future<Monitor> fetchMonitorDetail(String nome) async {
    final response = await http.get(Uri.parse('$apiUrl/$nome'));

    if (response.statusCode == 200) {
      return Monitor.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load monitor detail');
    }
  }
}
