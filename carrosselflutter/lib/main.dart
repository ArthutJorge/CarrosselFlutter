import 'package:flutter/material.dart';
import 'monitor.dart';
import 'monitor_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monitores DPD',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final MonitorService _monitorService = MonitorService();
  late Future<List<Monitor>> _monitores;

  final PageController _pageController = PageController(viewportFraction: 0.4);
  late List<Monitor> _monitoresList = [];

  @override
  void initState() {
    super.initState();
    _monitores = _monitorService.fetchMonitores();
  }

  void _navigateToMonitorDetails(Monitor monitor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonitorDetailView(monitor: monitor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Monitores DPD')),
      body: FutureBuilder<List<Monitor>>(
        future: _monitores,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum monitor encontrado.'));
          }

          _monitoresList = snapshot.data!;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Área dos cards com tamanho fixo
                Container(
                  height: 180, // Definindo a altura fixa
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _monitoresList.length,
                    itemBuilder: (context, index) {
                      final monitor = _monitoresList[index];
                      return GestureDetector(
                        onTap: () => _navigateToMonitorDetails(monitor),
                        child: Container(
                          width: 150,
                          height: 150, // Mantendo os cards quadrados
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                blurRadius: 5,
                                spreadRadius: 2,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(monitor.avatar),
                                backgroundColor: Colors.grey[200],
                              ),
                              SizedBox(height: 10),
                              Text(
                                monitor.nome,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Espaço para as setas de navegação
                SizedBox(height: 20), // Espaço entre os cards e as setas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MonitorDetailView extends StatelessWidget {
  final Monitor monitor;

  const MonitorDetailView({Key? key, required this.monitor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(monitor.nome)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(monitor.avatar),
            ),
            SizedBox(height: 20),
            Text(
              'Horários de Monitoria:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: monitor.horarios.length,
                itemBuilder: (context, index) {
                  final dia = monitor.horarios.keys.elementAt(index);
                  final horarios = monitor.horarios[dia]!.join(', ');
                  return ListTile(
                    title: Text(dia),
                    subtitle: Text(horarios),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
