import 'package:flutter/material.dart';
import 'models/monitor.dart';
import 'package:intl/intl.dart';

class MonitorCarousel extends StatelessWidget {
  final List<Monitor> monitores;
  final Function(Monitor) onMonitorTap;
  final int calendarioTipo; // Novo parâmetro

  const MonitorCarousel({
    Key? key,
    required this.monitores,
    required this.onMonitorTap,
    required this.calendarioTipo, // Adicionado aqui
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PageController _pageController = PageController(viewportFraction: 0.75);

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: monitores.length,
            itemBuilder: (context, index) {
              final monitor = monitores[index];
              return GestureDetector(
                onTap: () => onMonitorTap(monitor),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: _getCardColor(monitor),
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
              onPressed: () {
                _pageController.previousPage(
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
              onPressed: () {
                _pageController.nextPage(
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
    String diaDaSemana = DateFormat('EEEE', 'pt_BR').format(now).replaceAll("-feira", "").trim();

    // Verificar se o monitor está disponível agora
    if (monitor.horarios[diaDaSemana] != null) {
      for (String horario in monitor.horarios[diaDaSemana]!) {
        // Considera apenas o horário antes do traço
        String horarioSemLocal = horario.split(' - ')[0];
        DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
        DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
        DateTime fimHorario = inicioHorarioCompleto.add(Duration(minutes: calendarioTipo)); // Usando calendarioTipo

        if (now.isAfter(inicioHorarioCompleto) && now.isBefore(fimHorario)) {
          // Se está trabalhando agora, retorna verde
          return Colors.green[100]!;
        }
      }
    }

    // Verificar horários futuros
    List<String>? horariosFuturos = monitor.horarios[diaDaSemana];
    if (horariosFuturos != null) {
      for (String horario in horariosFuturos) {
        // Considera apenas o horário antes do traço
        String horarioSemLocal = horario.split(' - ')[0];
        DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
        DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
        if (inicioHorarioCompleto.isAfter(now)) {
          // Se há um horário futuro, retorna amarelo
          return Colors.yellow[100]!;
        }
      }
    }

    // Se não há horários disponíveis hoje, retorna cinza
    return Colors.grey[300]!;
  }

  String _getCardAvailabilityText(Monitor monitor) {
    DateTime now = DateTime.now();
    String diaDaSemana = DateFormat('EEEE', 'pt_BR').format(now).replaceAll("-feira", "").trim();

    if (monitor.horarios[diaDaSemana] != null) {
      List<String> horarios = monitor.horarios[diaDaSemana]!;
      DateTime fimDisponibilidade;

      for (int i = 0; i < horarios.length; i++) {
        // Considera apenas o horário antes do traço
        String horarioSemLocal = horarios[i].split(' - ')[0];
        DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
        DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
        DateTime fimHorario = inicioHorarioCompleto.add(Duration(minutes: calendarioTipo)); // Usando calendarioTipo

        // Verificar se agora está entre o horário de início e fim
        if (now.isAfter(inicioHorarioCompleto) && now.isBefore(fimHorario)) {
          // Se está trabalhando agora, calcula o fim do horário
          fimDisponibilidade = fimHorario;

          // Verifica se há horários consecutivos
          for (int j = i + 1; j < horarios.length; j++) {
            String proximoHorarioSemLocal = horarios[j].split(' - ')[0];
            DateTime proximoInicioHorario = DateFormat.Hm('pt_BR').parse(proximoHorarioSemLocal);
            DateTime proximoInicioCompleto = DateTime(now.year, now.month, now.day, proximoInicioHorario.hour, proximoInicioHorario.minute);

            // Verifica a tolerância de 15 minutos se o calendário for de 45 minutos
            if (calendarioTipo == 45 && fimHorario.isAfter(proximoInicioCompleto.subtract(Duration(minutes: 15)))) {
              // Se está dentro do intervalo tolerado, atualiza o fim da disponibilidade
              fimDisponibilidade = proximoInicioCompleto.add(Duration(minutes: 45));
            } else if (calendarioTipo == 30) {
              // Para 30 minutos, não há tolerância
              break; // Sair do loop
            } else {
              break; // Se o intervalo não é tolerado, sai do loop
            }
          }
          return 'Disponível agora até ${DateFormat.Hm('pt_BR').format(fimDisponibilidade)}';
        }
      }

      // Verificar horários futuros
      for (String horario in horarios) {
        // Considera apenas o horário antes do traço
        String horarioSemLocal = horario.split(' - ')[0];
        DateTime inicioHorario = DateFormat.Hm('pt_BR').parse(horarioSemLocal);
        DateTime inicioHorarioCompleto = DateTime(now.year, now.month, now.day, inicioHorario.hour, inicioHorario.minute);
        if (inicioHorarioCompleto.isAfter(now)) {
          return 'Disponível às $horarioSemLocal'; // Exibe o horário sem o local
        }
      }
    }

    // Se não há horários disponíveis hoje
    return 'Não disponível hoje';
  }
}
