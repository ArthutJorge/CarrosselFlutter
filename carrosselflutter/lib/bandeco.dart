import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cardapio.dart';
import '../services/cardapio_service.dart'; // Certifique-se de que o import está correto

class BandecoPage extends StatefulWidget {
  const BandecoPage({Key? key}) : super(key: key);

  @override
  _BandecoPageState createState() => _BandecoPageState();
}

class _BandecoPageState extends State<BandecoPage> {
  late CardapioService cardapioService;
  late Future<void> futureCardapios;
  late String diaAtual;

  // Mapeamento dos dias da semana para suas respectivas datas
  late Map<String, String> diasMap;

  @override
  void initState() {
    super.initState();
    cardapioService = CardapioService();
    futureCardapios = cardapioService.fetchCardapios();
    diaAtual = DateFormat('yyyy-MM-dd')
        .format(DateTime.now()); // Dia atual sempre no formato correto
    diasMap = _criarMapaDiasDaSemana(); // Inicializa o mapa
  }

  Map<String, String> _criarMapaDiasDaSemana() {
    Map<String, String> map = {};
    DateTime hoje = DateTime.now();

    // Criar um mapeamento dos dias da semana
    List<String> diasDaSemana = [
      'segunda',
      'terça',
      'quarta',
      'quinta',
      'sexta',
      'sábado',
      'domingo'
    ];

    for (int i = 0; i < diasDaSemana.length; i++) {
      DateTime dia = hoje
          .add(Duration(days: i - 2)); // Ajuste para o dia atual mantenha o -2
      String chave = DateFormat('yyyy-MM-dd').format(dia);
      map[diasDaSemana[i]] = chave; // Adiciona ao mapa
    }
    return map;
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
            return SingleChildScrollView( // Adiciona scroll para evitar overflow
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
        // Habilita o scroll horizontal
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Centraliza horizontalmente
          children: diasMap.keys.map((diaNome) {
            String diaData = diasMap[diaNome]!; // Obtém a data correspondente

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    diaAtual = diaData; // Atualiza o dia atual quando o botão é pressionado
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      diaData == diaAtual ? Colors.redAccent : Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                ),
                child: Text(
                  diaNome.capitalize(), // Exibe o nome do dia
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
      return const Center(
          child: Text('Não há cardápios disponíveis para hoje.'));
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
    elevation: 6, // Sombra mais intensa para destaque
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0), // Bordas mais arredondadas
    ),
    margin: const EdgeInsets.only(bottom: 20.0), // Aumenta o espaçamento entre os cards
    color: const Color.fromARGB(255, 240, 240, 240), // Cor de fundo do card
    child: Padding(
      padding: const EdgeInsets.all(20.0), // Aumenta o padding interno do card
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(refeicao,
              style: const TextStyle(
                fontSize: 28, // Tamanho maior para o título
                fontWeight: FontWeight.bold,
                color: Colors.redAccent, // Cor do título
              )),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 20, color: Colors.black87), // Estilo padrão para o texto
              children: [
                const TextSpan(
                    text: 'Principal: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent)), // Título em negrito
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
                color: Colors.redAccent.withOpacity(0.3), // Fundo leve para os acompanhamentos
                borderRadius: BorderRadius.circular(12.0), // Bordas arredondadas
                border: Border.all(
                  color: Colors.redAccent, // Borda com cor para mais destaque
                  width: 1.5, // Largura da borda
                ),
              ),
              padding: const EdgeInsets.all(14.0), // Aumenta o padding do container
              child: Text(
                acompanhamento,
                style: const TextStyle(fontSize: 20, color: Colors.black87), // Texto com cor escura
              ),
            ),
          )),
          const SizedBox(height: 20),
          if (observacao.isNotEmpty)
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 18, color: Colors.black54), // Estilo padrão para observação
                children: [
                  const TextSpan(
                      text: 'Observação: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)), // Título em negrito
                  TextSpan(text: observacao),
                ],
              ),
            ),
        ],
      ),
    ),
  );
    }}


// Extensão para capitalizar o primeiro caractere
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }
}
