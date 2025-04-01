import 'package:flutter/material.dart';

class PaymentCalculatorScreen extends StatefulWidget {
  /// Cantidad de jugadores que vendrá precargada si se ingresa desde el resultado final.
  final int? initialPlayers;
  /// Indica si se ingresa desde el EndMatchScreen (true) o desde otro lugar (false).
  final bool fromEndMatch;

  const PaymentCalculatorScreen({
    Key? key,
    this.initialPlayers,       // puede ser null si no viene del EndMatch
    this.fromEndMatch = false, // por defecto false
  }) : super(key: key);

  @override
  _PaymentCalculatorScreenState createState() => _PaymentCalculatorScreenState();
}

class _PaymentCalculatorScreenState extends State<PaymentCalculatorScreen> {
  final TextEditingController jugadoresController = TextEditingController();
  final TextEditingController canchaController = TextEditingController();
  final TextEditingController apuestaController = TextEditingController();

  String resultado = "";

  @override
  void initState() {
    super.initState();
    // Si initialPlayers no es null, se precarga en el TextField
    if (widget.initialPlayers != null) {
      jugadoresController.text = widget.initialPlayers.toString();
    }
  }

  void calcularPago({bool empate = true, int ganadores = 0}) {
    int totalJugadores = int.tryParse(jugadoresController.text) ?? 0;
    double precioCancha = double.tryParse(canchaController.text) ?? 0.0;
    double apuesta = double.tryParse(apuestaController.text) ?? 0.0;

    if (totalJugadores > 0) {
      double costoPorJugador = precioCancha / totalJugadores;

      if (empate) {
        setState(() {
          resultado = "Cada jugador paga (cancha): "
              "S/ ${costoPorJugador.toStringAsFixed(2)}";
        });
      } else {
        int perdedores = totalJugadores - ganadores;
        double pagoPerdedores = costoPorJugador + apuesta;
        double pagoGanadores = costoPorJugador;
        double gananciaGanadores =
            (apuesta * perdedores / ganadores) - costoPorJugador;
        if (gananciaGanadores < 0) {
          pagoGanadores = gananciaGanadores.abs();
          gananciaGanadores = 0;
        }

        setState(() {
          resultado =
              "Total jugadores: $totalJugadores\n"
              "Cada jugador paga (cancha): S/ ${costoPorJugador.toStringAsFixed(2)}\n"
              "Jugadores perdedores pagan: S/ ${pagoPerdedores.toStringAsFixed(2)}\n"
              "Jugadores ganadores pagan: S/ ${pagoGanadores.toStringAsFixed(2)}\n"
              "Jugadores ganadores ganan: S/ ${gananciaGanadores.toStringAsFixed(2)}";
        });
      }
    } else {
      setState(() {
        resultado = "Por favor, ingrese valores válidos";
      });
    }
  }

  @override
  void dispose() {
    jugadoresController.dispose();
    canchaController.dispose();
    apuestaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imagen de fondo
        Positioned.fill(
          child: Opacity(
            opacity: 0.3, // Ajusta la opacidad (0.0 - 1.0)
            child: Image.asset(
              "assets/pagos.jpg",
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),

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

                          // Botones de Empate / Gana un equipo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => calcularPago(empate: true),
                                child: Text(
                                  'Empate',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      TextEditingController ganadoresController =
                                          TextEditingController();
                                      return AlertDialog(
                                        title: Text("Ingrese cantidad de ganadores"),
                                        content: TextField(
                                          controller: ganadoresController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: "Cantidad de ganadores",
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              int ganadores = int.tryParse(
                                                    ganadoresController.text,
                                                  ) ??
                                                  0;
                                              int totalJugadores =
                                                  int.tryParse(
                                                    jugadoresController.text,
                                                  ) ??
                                                  0;
                                              if (ganadores > 0 &&
                                                  ganadores < totalJugadores) {
                                                calcularPago(
                                                  empate: false,
                                                  ganadores: ganadores,
                                                );
                                                Navigator.pop(context);
                                              }
                                            },
                                            child: Text(
                                              "Aceptar",
                                              style: TextStyle(color: Colors.green),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text(
                                  'Gana un equipo',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                          Center(child: SizedBox(height: 20)),

                          // Resultado
                          Text(
                            resultado,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              ),
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
      ],
    );
  }
}
