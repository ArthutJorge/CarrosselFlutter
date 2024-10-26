import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cardapio.dart';

class CardapioService {
  final String apiUrl = 'http://localhost:9090/cardapio';  // https://cotuca-pocket-api.vercel.app/cardapio
  Map<String, Cardapio> cardapiosPorDia = {};

  Future<Map<String, Cardapio>> fetchCardapios() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) { // se foi bem sucedido
      Map<String, dynamic> body = json.decode(response.body);

      body.forEach((dia, dadosDoDia) {
        Prato almoco = Prato(
          principal: dadosDoDia['Almoço']['principal'],
          acompanhamento: List<String>.from(dadosDoDia['Almoço']['acompanhamento']),
          observacao: dadosDoDia['Almoço']['observacao'] ?? "",
        );

        Prato jantar = Prato(
          principal: dadosDoDia['Jantar']['principal'],
          acompanhamento: List<String>.from(dadosDoDia['Jantar']['acompanhamento']),
          observacao: dadosDoDia['Jantar']['observacao'] ?? "",
        );

        cardapiosPorDia[dia] = Cardapio(dia: dia, almoco: almoco, jantar: jantar);
      });

      return cardapiosPorDia; // Retorna o mapa de cardápios
    } else {
      throw Exception('Falha ao carregar cardápios');
    }
  }

  Cardapio? getCardapioPorDia(String dia) {
    return cardapiosPorDia[dia];
  }

  List<Cardapio> getTodosCardapios() {
    return cardapiosPorDia.values.toList();
  }
}
