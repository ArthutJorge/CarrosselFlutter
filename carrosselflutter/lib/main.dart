import 'package:carrosselflutter/monitoria.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('pt_BR', null).then((_) {
    runApp(const MyApp());
  });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cotuca Pocket',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotuca Pocket'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2, // Define o grid 2x2
            crossAxisSpacing: 20, // Espaçamento horizontal
            mainAxisSpacing: 20,  // Espaçamento vertical
            children: [
              _buildGridButton(
                context,
                icon: Icons.school,
                label: 'Monitoria',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MonitoriaPage()),
                  );
                },
              ),
              _buildGridButton(
                context,
                icon: Icons.restaurant,
                label: 'Bandeco',
                onTap: () {
                  // Ação do botão Bandeco
                },
              ),
              _buildGridButton(
                context,
                icon: Icons.meeting_room,
                label: 'Salas',
                onTap: () {
                  // Ação do botão Salas
                },
              ),
              _buildGridButton(
                context,
                icon: Icons.more_horiz,
                label: 'Em Breve...',
                onTap: () {
                  // Ação futura
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent, // Cor de fundo
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Borda arredondada
        ),
        padding: const EdgeInsets.all(16), // Espaçamento interno
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.white),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 18, color: Colors.white)),
        ],
      ),
    );
  }
}
