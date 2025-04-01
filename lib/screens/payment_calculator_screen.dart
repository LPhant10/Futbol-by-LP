import 'package:flutter/material.dart';

class PaymentCalculatorScreen extends StatefulWidget {
  final int? initialPlayers;
  final bool fromEndMatch;
  final int winnersCount; // 1 = un solo ganador, >1 = empate
  final List<String> allPlayers; // Para el control de pagos individual

  const PaymentCalculatorScreen({
    Key? key,
    this.initialPlayers,
    this.fromEndMatch = false,
    this.winnersCount = 0,
    required this.allPlayers,
  }) : super(key: key);

  @override
  _PaymentCalculatorScreenState createState() => _PaymentCalculatorScreenState();
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
    double apuesta = double.tryParse(apuestaController.text) ?? 0.0;

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
        resultado = "Total jugadores: $totalJugadores\n"
            "Cada jugador paga (cancha): S/ ${costoPorJugador.toStringAsFixed(2)}\n"
            "(La apuesta se anula o se reparte entre todos)";
      });
    } else {
      // Caso "Un solo ganador" => supondremos 1 ganador y (totalJugadores - 1) perdedores.
      int ganadores = 1;
      int perdedores = totalJugadores - ganadores;

      double pagoPerdedor = costoPorJugador + apuesta;
      // Apuesta total = perdedores * apuesta
      double descuento = (perdedores * apuesta) / ganadores; 
      // Pago del ganador (con clamp a 0 si excede)
      double pagoGanador = costoPorJugador - descuento;
      if (pagoGanador < 0) {
        pagoGanador = 0;
      }

      // Ganancia extra si sobró
      double sobra = (perdedores * apuesta) - (descuento * ganadores);
      // Normalmente quedaría en 0, pero si el descuento superó el costo, sobraría algo.

      setState(() {
        resultado = "Total jugadores: $totalJugadores\n"
            "Cada jugador paga (cancha): S/ ${costoPorJugador.toStringAsFixed(2)}\n"
            "Jugadores perdedores pagan: S/ ${pagoPerdedor.toStringAsFixed(2)}\n"
            "Jugador ganador paga: S/ ${pagoGanador.toStringAsFixed(2)}\n"
            "Jugador ganador gana: S/ ${sobra.toStringAsFixed(2)}";
      });
    }
  }

  /// Lógica "personalizada": si el usuario ingresa cuántos ganadores hubo.
  void calcularPagoPersonalizado(int ganadores) {
    int totalJugadores = int.tryParse(jugadoresController.text) ?? 0;
    double precioCancha = double.tryParse(canchaController.text) ?? 0.0;
    double apuesta = double.tryParse(apuestaController.text) ?? 0.0;

    if (totalJugadores <= 0) {
      setState(() {
        resultado = "Por favor, ingrese valores válidos";
      });
      return;
    }
    if (ganadores <= 0 || ganadores >= totalJugadores) {
      setState(() {
        resultado = "Cantidad de ganadores inválida (0 o mayor al total).";
      });
      return;
    }

    double costoPorJugador = precioCancha / totalJugadores;
    int perdedores = totalJugadores - ganadores;

    double pagoPerdedor = costoPorJugador + apuesta;

    // Apuesta total de los perdedores
    double apuestaTotal = perdedores * apuesta;
    // Descuento que se reparte entre los ganadores
    double descuento = apuestaTotal / ganadores;
    double pagoGanador = costoPorJugador - descuento;
    if (pagoGanador < 0) {
      pagoGanador = 0; // No pueden pagar negativo
    }

    // Sobra si el descuento superó el costo
    double sobra = apuestaTotal - (descuento * ganadores);

    setState(() {
      resultado = "Total jugadores: $totalJugadores\n"
          "Cada jugador paga (cancha): S/ ${costoPorJugador.toStringAsFixed(2)}\n"
          "Jugadores perdedores pagan: S/ ${pagoPerdedor.toStringAsFixed(2)}\n"
          "Jugadores ganadores pagan: S/ ${pagoGanador.toStringAsFixed(2)}\n"
          "Jugadores ganadores ganan: S/ ${sobra.toStringAsFixed(2)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hayUnSoloGanador = (widget.winnersCount == 1);

    return Stack(
      children: [
        // Imagen de fondo
        Positioned.fill(
          child: Opacity(
            opacity: 0.3,
            child: Image.asset(
              "assets/pagos.jpg",
              fit: BoxFit.cover,
            ),
          ),
        ),
       /*  Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text("Calculadora de Pagos by LPhant"),
            backgroundColor: Colors.red,
          ),
          body: SafeArea(
            child: Column(
              children: [
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
                        SizedBox(height: 20), */
                         Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botón de retroceso
                SizedBox(height: 10),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '💰 PAGOS!! 💰',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campo "Cantidad de jugadores"
                          TextField(
                            controller: jugadoresController,
                            readOnly: widget.fromEndMatch, 
                            // si fromEndMatch es true, el usuario NO puede cambiar
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
                              child: Text("Empate" ),
                              style: ElevatedButton.styleFrom(
                                
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final ganadoresController =
                                        TextEditingController();
                                    return AlertDialog(
                                      title: Text("Ingrese cantidad de ganadores"),
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
                                            int ganadores = int.tryParse(
                                                    ganadoresController.text) ??
                                                0;
                                            Navigator.pop(context);
                                            if (ganadores > 0) {
                                              calcularPagoPersonalizado(ganadores);
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
                              trailing: paidStatus[index]
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
                ),
            
              ],
          ),
        ),
                         ),
      ]
    );
      
  }
}
