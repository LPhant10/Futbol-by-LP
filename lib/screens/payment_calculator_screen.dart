import 'package:flutter/material.dart';

class PaymentCalculatorScreen extends StatefulWidget {
  final int? initialPlayers;
  final bool fromEndMatch;
  final int winnersCount; // 1 = un solo ganador, >1 = empate
  final List<String> allPlayers; // Para el control de pagos individual

  const PaymentCalculatorScreen({
    super.key,
    this.initialPlayers,
    this.fromEndMatch = false,
    this.winnersCount = 0,
    required this.allPlayers,
  });

  @override
  _PaymentCalculatorScreenState createState() =>
      _PaymentCalculatorScreenState();
}

class _PaymentCalculatorScreenState extends State<PaymentCalculatorScreen> {
  final TextEditingController jugadoresController = TextEditingController();
  final TextEditingController canchaController = TextEditingController();
  final TextEditingController apuestaController = TextEditingController();

  String resultado = "";

  /// Lista booleana para controlar si cada jugador ya pagó.
  late List<bool> paidStatus;

  @override
  void initState() {
    super.initState();

    // Si initialPlayers no es null, se precarga el campo.
    if (widget.initialPlayers != null) {
      jugadoresController.text = widget.initialPlayers.toString();
    }
    // Inicializamos la lista de pagos con el tamaño de allPlayers.
    paidStatus = List<bool>.filled(widget.allPlayers.length, false);
  }

  /// Lógica de "Empate" o "Ganador único" (sin especificar cuántos ganadores).
  void calcularPagoRapido({required bool empate}) {
    int totalJugadores = int.tryParse(jugadoresController.text) ?? 0;
    double precioCancha = double.tryParse(canchaController.text) ?? 0.0;
    //double apuesta = double.tryParse(apuestaController.text) ?? 0.0;

    if (totalJugadores <= 0) {
      setState(() {
        resultado = "Por favor, ingrese valores válidos";
      });
      return;
    }
    double costoPorJugador = precioCancha / totalJugadores;

    if (empate) {
      // Caso Empate: todos pagan lo mismo (solo la cancha).
      setState(() {
        resultado =
            "Total jugadores: $totalJugadores\n"
            "Cada jugador paga (cancha): S/ ${costoPorJugador.toStringAsFixed(2)}\n"
            "(La apuesta se anula o se reparte entre todos)";
      });
    }
  }

  /// Lógica "personalizada": si el usuario ingresa cuántos ganadores hubo.
  void calcularPagoPersonalizado(int ganadores) {
    int totalJugadores = int.tryParse(jugadoresController.text) ?? 0;
    double precioCancha = double.tryParse(canchaController.text) ?? 0.0;
    double apuesta = double.tryParse(apuestaController.text) ?? 0.0;

    if (totalJugadores <= 0 || precioCancha <= 0 || apuesta < 0) {
      setState(() {
        resultado = "Por favor, ingrese valores válidos.";
      });
      return;
    }

    if (ganadores < 0 || ganadores > totalJugadores) {
      setState(() {
        resultado = "Cantidad de ganadores inválida.";
      });
      return;
    }

    // Cada jugador paga su parte de la cancha
    double costoPorJugador = precioCancha / totalJugadores;

    if (ganadores == totalJugadores) {
      // En caso de empate, todos pagan solo su parte de la cancha
      setState(() {
        resultado =
            "Empate. Todos pagan: S/ ${costoPorJugador.toStringAsFixed(2)}";
      });
      return;
    }

    int perdedores = totalJugadores - ganadores;
    double pagoPerdedor = costoPorJugador + apuesta;

    // Dinero total acumulado por las apuestas de los perdedores
    double dineroDisponible = perdedores * apuesta;

    // Cada ganador recibe una parte equitativa del dinero acumulado
    double gananciaPorGanador = dineroDisponible / ganadores;

    // Los ganadores pagan su parte de la cancha pero reciben su ganancia
    double pagoGanador = (costoPorJugador - gananciaPorGanador).clamp(
      0,
      costoPorJugador,
    );

    // Ganancia neta de los ganadores
    double gananciaNeta = (gananciaPorGanador - costoPorJugador).clamp(
      0,
      gananciaPorGanador,
    );

    setState(() {
      resultado =
          "Total jugadores → $totalJugadores\n"
          "Cada jugador paga su parte de la cancha → S/ ${costoPorJugador.toStringAsFixed(2)}\n"
          "Perdedores pagan su apuesta completa → S/ ${pagoPerdedor.toStringAsFixed(2)}\n"
          "Ganadores pagan solo su cancha → S/ ${pagoGanador.toStringAsFixed(2)}\n"
          // "Ganadores reciben → S/ ${gananciaPorGanador.toStringAsFixed(2)}\n"
          "Ganancia total - su cancha: S/ ${gananciaNeta.toStringAsFixed(2)}";
    });
  }

  //
  @override
  void dispose() {
    jugadoresController.dispose();
    canchaController.dispose();
    apuestaController.dispose();
    super.dispose();
  }
  //

  @override
  Widget build(BuildContext context) {
    bool hayUnSoloGanador = (widget.winnersCount == 1);

    return GestureDetector(
      onTap: () {
    FocusManager.instance.primaryFocus?.unfocus();
  },
      child: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset("assets/pagos.jpg", fit: BoxFit.cover),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            /*  appBar: AppBar(
              title: Text("Calculadora de Pagos by LPhant"),
              backgroundColor: Colors.red,
            ), */
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
          
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Row(
                      children: [
                        SizedBox(height: 25),
                        Icon(
                          Icons.monetization_on_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PAGOS ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        Icon(
                          Icons.monetization_on_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campo "Cantidad de jugadores"
                          TextField(
                            controller: jugadoresController,
                            readOnly: widget.fromEndMatch,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cantidad de jugadores',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                          SizedBox(height: 12),
                          // Campo "Precio de la cancha"
                          TextField(
                            controller: canchaController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Precio de la cancha',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                          SizedBox(height: 12),
                          // Campo "Cantidad de apuesta por jugador"
                          TextField(
                            controller: apuestaController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cantidad de apuesta por jugador',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                          SizedBox(height: 20),
          
                          // Botones principales
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Si winnersCount == 1 => “un solo ganador”
                                  // Sino => se asume empate
                                  if (hayUnSoloGanador) {
                                    calcularPagoRapido(empate: false);
                                  } else {
                                    calcularPagoRapido(empate: true);
                                  }
                                },
                                child: Text("Empate"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) {
                                      final ganadoresController =
                                          TextEditingController();
                                      return AlertDialog(
                                        title: Text(
                                          "Ingrese cantidad de ganadores",
                                        ),
                                        content: TextField(
                                          controller: ganadoresController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: "N° de ganadores",
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              FocusManager.instance.primaryFocus?.unfocus();
                                              FocusScope.of(dialogContext).unfocus();
                                              int ganadores =
                                                  int.tryParse(
                                                    ganadoresController.text,
                                                  ) ??
                                                  0;
                                              Navigator.pop(context);
                                              if (ganadores > 0) {
                                                calcularPagoPersonalizado(
                                                  ganadores,
                                                );
                                              }
                                            },
                                            child: Text("OK"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text("Gana un equipo"),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
          
                          // Resultado
                          Text(
                            resultado,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
          
                          // Control de pagos
                          Text(
                            "Control de Pagos:",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: widget.allPlayers.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: Checkbox(
                                  value: paidStatus[index],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      paidStatus[index] = value ?? false;
                                    });
                                  },
                                ),
                                title: Text(
                                  widget.allPlayers[index],
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailing:
                                    paidStatus[index]
                                        ? Text(
                                          "PAGADO",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : SizedBox(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}