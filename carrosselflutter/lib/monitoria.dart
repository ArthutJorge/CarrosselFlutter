import 'package:carrosselflutter/services/monitor_service.dart';
import 'package:flutter/material.dart';
import 'monitoria_materia.dart'; // Sua página de Monitoria

class MonitoriaPage extends StatefulWidget {
  @override
  _MonitoriaPageState createState() => _MonitoriaPageState();
}

class _MonitoriaPageState extends State<MonitoriaPage> {
  List<dynamic> _monitores = []; // Lista para armazenar monitores
  List<dynamic> _disponiveisAgora = []; // Lista para monitores disponíveis agora
  List<dynamic> _disponiveisMaisTarde = []; // Lista para monitores disponíveis mais tarde

  @override
  void initState() {
    super.initState();
    _fetchMonitores();
  }

  Future<void> _fetchMonitores() async {
    // Simulação de um fetch de dados
    var monitorService = MonitorService();

    _classificarMonitores();
    setState(() {}); // Atualiza o estado após o fetch
  }

  void _classificarMonitores() {
    // Obtenha o horário atual
    final agora = DateTime.now();
    final horaAtual = '${agora.hour}:${agora.minute}';

    _disponiveisAgora.clear();
    _disponiveisMaisTarde.clear();

    for (var materia in _monitores) {
      for (var monitor in materia['monitores']) {
        String nome = monitor['nome'];
        String avatar = monitor['avatar'];
        List<String> horarios = monitor['horarios']['hoje']; // Considera que há um campo 'hoje' para os horários

        // Verifica os horários e classifica os monitores
        for (var horario in horarios) {
          var partes = horario.split(' - ');
          var inicio = partes[0];
          // Verifica se o monitor está disponível agora
          if (_isDisponivelAgora(horaAtual, inicio)) {
            _disponiveisAgora.add({
              'nome': nome,
              'avatar': avatar,
              'horario': inicio,
              'disponibilidade': 'Agora',
            });
          } else {
            _disponiveisMaisTarde.add({
              'nome': nome,
              'avatar': avatar,
              'horario': inicio,
              'disponibilidade': 'Mais tarde',
            });
          }
        }
      }
    }
  }

  bool _isDisponivelAgora(String horaAtual, String inicio) {
    // Lógica para determinar se o monitor está disponível agora
    return horaAtual.compareTo(inicio) >= 0; // Simples comparação de strings
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoria'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carrossel de Monitores Disponíveis Agora
            _buildCarrossel(_disponiveisAgora, 'Disponíveis Agora'),
            SizedBox(height: 20),
            // Carrossel de Monitores Disponíveis Mais Tarde
            _buildCarrossel(_disponiveisMaisTarde, 'Disponíveis Mais Tarde'),
            SizedBox(height: 20),
            // Botão para buscar por matéria
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MonitoriaMateriaPage(materia: 'informatica')),
                );
              },
              child: Text('Buscar por Matéria'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarrossel(List<dynamic> monitores, String title) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Container(
          height: 150, // Altura do carrossel
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: monitores.length,
            itemBuilder: (context, index) {
              final monitor = monitores[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MonitoriaMateriaPage(materia: 'informatica'),
                    ),
                  );
                },
                child: Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(monitor['avatar']),
                        radius: 30,
                      ),
                      SizedBox(height: 10),
                      Text(monitor['nome']),
                      Text(monitor['disponibilidade']),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
