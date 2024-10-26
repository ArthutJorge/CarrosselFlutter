import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cardapio.dart';
import '../services/cardapio_service.dart';

class BandecoPage extends StatefulWidget {
  const BandecoPage({Key? key}) : super(key: key);

  @override
  _BandecoPageState createState() => _BandecoPageState();
}

class _BandecoPageState extends State<BandecoPage> {
  late CardapioService cardapioService;
  late Future<void> futureCardapios;
  late String diaAtual;

  // Usando uma lista para armazenar as datas
  late List<String> diasList;

  @override
  void initState() {
    super.initState();
    cardapioService = CardapioService();
    futureCardapios = cardapioService.fetchCardapios();
    diaAtual = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Dia atual sempre no formato correto
    diasList = _criarListaDiasDaSemana(); // Inicializa a lista de dias
  }

  List<String> _criarListaDiasDaSemana() {
    List<String> list = [];
    DateTime hoje =  DateTime.now();
    int diaIndex = hoje.weekday; // 1 = segunda, ..., 7 = domingo

    // Adiciona dias à lista com base no dia da semana atual
    if (diaIndex == 6) { // Sábado
      for (int i = 0; i < 9; i++) {
        DateTime dia = hoje.add(Duration(days: i));
        list.add(DateFormat('yyyy-MM-dd').format(dia));
      }
    } else if (diaIndex == 7) { // Domingo
      for (int i = 0; i < 8; i++) {
        DateTime dia = hoje.add(Duration(days: i));
        list.add(DateFormat('yyyy-MM-dd').format(dia));
      }
    } else { // De segunda a sexta
      for (int i = 0; i < 7; i++) {
        DateTime dia = hoje.add(Duration(days: i));
        list.add(DateFormat('yyyy-MM-dd').format(dia));
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cardápio do Dia'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<void>(
        future: futureCardapios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildDiasDaSemana(),
                  _buildCardapioDoDia(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDiasDaSemana() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    height: 60,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: diasList.map((diaData) {
          // Formato da data que está sendo comparado
          String diaNome = DateFormat('EEEE', 'pt_BR').format(DateTime.parse(diaData)); 

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  diaAtual = diaData; // Atualiza diaAtual para o dia selecionado
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: diaData == diaAtual ? Colors.redAccent : Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              child: Text(
                diaNome.capitalize(), // Usando um método para capitalizar o texto
                style: TextStyle(
                  color: diaData == diaAtual ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

  Widget _buildCardapioDoDia() {
    Cardapio? cardapio = cardapioService.getCardapioPorDia(diaAtual);
    if (cardapio == null) {
      return const Center(child: Text('Não há cardápios disponíveis para hoje.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard('Almoço', cardapio.almoco.principal,
              cardapio.almoco.acompanhamento, cardapio.almoco.observacao),
          if (cardapio.jantar.principal.isNotEmpty)
            _buildCard('Jantar', cardapio.jantar.principal,
                cardapio.jantar.acompanhamento, cardapio.jantar.observacao),
        ],
      ),
    );
  }

  Widget _buildCard(String refeicao, String principal,
      List<String> acompanhamentos, String observacao) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.only(bottom: 20.0),
      color: const Color.fromARGB(255, 240, 240, 240),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(refeicao,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                )),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 20, color: Colors.black87),
                children: [
                  const TextSpan(
                      text: 'Principal: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                  TextSpan(text: principal),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...acompanhamentos.map((acompanhamento) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Colors.redAccent,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  acompanhamento,
                  style: const TextStyle(fontSize: 20, color: Colors.black87),
                ),
              ),
            )),
            const SizedBox(height: 20),
            if (observacao.isNotEmpty)
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 18, color: Colors.black54),
                  children: [
                    const TextSpan(
                        text: 'Observação: ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                    TextSpan(text: observacao),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Extensão para capitalizar o primeiro caractere
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }
}
