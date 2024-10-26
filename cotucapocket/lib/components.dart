import 'package:flutter/material.dart';
import 'models/monitor.dart';
import 'package:intl/intl.dart';

class MonitorCarousel extends StatelessWidget {
  final List<Monitor> monitores;
  final Function(Monitor) onMonitorTap;
  final int duracaoMonitoria;

  const MonitorCarousel({
    super.key,
    required this.monitores,
    required this.onMonitorTap,
    required this.duracaoMonitoria,
  });

  @override
  Widget build(BuildContext context) {
    final PageController pageController =
        PageController(viewportFraction: 0.75); // cada card ocupa 0.75 da tela

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder( // cria um carroussel
            controller: pageController,
            itemCount: monitores.length, 
            itemBuilder: (context, index) {
              final monitor = monitores[index]; // monitor atual 
              return GestureDetector(
                onTap: () => onMonitorTap(monitor), // ao clicar aparece seus horários individuais
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: _getCardColor(monitor), // cor do card
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(monitor.avatar),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        monitor.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getCardAvailabilityText(monitor),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: () { // volta
                pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
          Positioned(
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: () { // avança
                pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCardColor(Monitor monitor) {
    DateTime now = DateTime.now();
    String diaDaSemana =
        DateFormat('EEEE', 'pt_BR').format(now).replaceAll("-feira", "").trim(); // pega os dias da semana sem o -feira

    // Verifica se o monitor está disponível agora
    if (monitor.horarios[diaDaSemana] != null) {
      for (String horario in monitor.horarios[diaDaSemana]!) {
        // Considera apenas o horário antes do traço
        String horarioSemLocal = horario.split(' - ')[0];
        DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
        DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
        DateTime fimHorario = inicioHorarioCompleto
            .add(Duration(minutes: duracaoMonitoria)); // inicio horário + duração da monitoria

        if (now.isAfter(inicioHorarioCompleto) && now.isBefore(fimHorario)) { // se está depois do horário de inicio e antes do de fim
          return Colors.green[100]!;
        }
      }
    }

    // Se não está disponível agora, verifica se vai estar disponível mais tarde de hoje
    List<String>? horariosFuturos = monitor.horarios[diaDaSemana];
    if (horariosFuturos != null) {
      for (String horario in horariosFuturos) {
        // Considera apenas o horário antes do traço
        String horarioSemLocal = horario.split(' - ')[0];
        DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
        DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day,
            inicioHorario.hour, inicioHorario.minute);
        if (inicioHorarioCompleto.isAfter(now)) { // se há uma monitoria depois de agora e hoje
          return Colors.yellow[100]!;
        }
      }
    }
    // se não há monitorias hoje
    return Colors.grey[300]!;
  }

  String _getCardAvailabilityText(Monitor monitor) {
    DateTime now = DateTime.now();
    String diaDaSemana =
        DateFormat('EEEE', 'pt_BR').format(now).replaceAll("-feira", "").trim(); // remove o feira

    if (monitor.horarios[diaDaSemana] != null) {  // se há horários nesse dia
      List<String> horarios = monitor.horarios[diaDaSemana]!;
      DateTime fimDisponibilidade;

      for (int i = 0; i < horarios.length; i++) {
        // Considera o horário e o local
        List<String> horarioLocal = horarios[i].split(' - ');
        String horarioSemLocal = horarioLocal[0];
        String local = horarioLocal.length > 1 ? horarioLocal[1].trim() : ''; // pega o local se ele existir 

        // converte horário para DateTime
        DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
        DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
        DateTime fimHorario = inicioHorarioCompleto.add(Duration(minutes: duracaoMonitoria));

        // Verifica se agora está entre o horário de início e fim da monitoria
        if (now.isAfter(inicioHorarioCompleto) && now.isBefore(fimHorario)) {
          fimDisponibilidade = fimHorario;

          // Verifica se há monitorias seguidas para agrupar e calcular o horário de fim dessa sequencia
          for (int j = i + 1; j < horarios.length; j++) {
            List<String> proximoHorarioLocal = horarios[j].split(' - ');
            String proximoHorarioSemLocal = proximoHorarioLocal[0];
            DateTime proximoInicioHorario =
                DateFormat.Hm('pt_BR').parse(proximoHorarioSemLocal);
            DateTime proximoInicioCompleto = DateTime(now.year,now.month,now.day,proximoInicioHorario.hour,proximoInicioHorario.minute);
            
            // monitorias de 45 minutos tem intervalo de 15 minutos
            if (duracaoMonitoria == 45 && fimHorario.isAfter(proximoInicioCompleto .subtract(const Duration(minutes: 15)))) {
                fimDisponibilidade = proximoInicioCompleto.add(const Duration(minutes: 45));
            } else {
              break; // se não é de 45 minutos não tem intervalo
            }
          }

          return 'Disponível agora até ${DateFormat.Hm('pt_BR').format(fimDisponibilidade)} - $local';
        }
      }

      // Se não está disponível agora
      for (String horario in horarios) {
        List<String> horarioLocal = horario.split(' - ');
        String horarioSemLocal = horarioLocal[0];

        DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
        DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day,inicioHorario.hour, inicioHorario.minute);

        if (inicioHorarioCompleto.isAfter(now)) {
          return 'Disponível às $horario';
        }
      }
    }

    // se não está disponível hoje
    return 'Não disponível hoje';
  }
}
