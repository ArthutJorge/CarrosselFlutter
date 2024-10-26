class Cardapio {
  final String dia;
  final Prato almoco;
  final Prato jantar;

  Cardapio({
    required this.dia,
    required this.almoco,
    required this.jantar,
  });
}

class Prato {
  final String principal;
  final List<String> acompanhamento;
  final String observacao;

  Prato({
    required this.principal,
    required this.acompanhamento,
    required this.observacao,
  });
}
