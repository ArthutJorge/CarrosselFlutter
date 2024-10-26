class Monitor {
  final String nome;
  final String avatar;
  final Map<String, List<String>> horarios;

  Monitor({
    required this.nome,
    required this.avatar,
    required this.horarios,
  });

  // Instancia os monitores atráves do json enviado como parâmetro
  factory Monitor.fromJson(Map<String, dynamic> json) {
    // Converta o mapa de horários para garantir que todas as listas sejam de Strings
    Map<String, List<String>> horariosConvertidos = (json['horarios'] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, List<String>.from(value));
    });

    return Monitor(
      nome: json['nome'],
      avatar: json['avatar'],
      horarios: horariosConvertidos,
    );
  }
}
