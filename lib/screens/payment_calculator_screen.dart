// lib/screens/payment_calculator_screen.dart
import 'package:flutter/material.dart';

class PaymentCalculatorScreen extends StatefulWidget {
  @override
  _PaymentCalculatorScreenState createState() =>
      _PaymentCalculatorScreenState();
}

class _PaymentCalculatorScreenState extends State<PaymentCalculatorScreen> {
  final TextEditingController jugadoresController = TextEditingController();
  final TextEditingController canchaController = TextEditingController();
  final TextEditingController apuestaController = TextEditingController();

  String resultado = "";

  void calcularPago({bool empate = true, int ganadores = 0}) {
    int totalJugadores = int.tryParse(jugadoresController.text) ?? 0;
    double precioCancha = double.tryParse(canchaController.text) ?? 0.0;
    double apuesta = double.tryParse(apuestaController.text) ?? 0.0;

    if (totalJugadores > 0) {
      double costoPorJugador = precioCancha / totalJugadores;

      if (empate) {
        setState(() {
          resultado =
              "Cada jugador paga (cancha): S/ ${costoPorJugador.toStringAsFixed(2)}";
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
          child: Stack(
            children: [
              Opacity(
                opacity: 0.3, // Ajusta la opacidad (0.0 - 1.0)
                child: Image.asset(
                  "assets/pagos.jpg",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ],
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent, // Permite ver la imagen de fondo
          body: SafeArea(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start, // Alinea los elementos a la izquierda
              children: [
                SizedBox(height: 40), 
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                ),// Espacio en blanco arriba
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
                

                SizedBox(height: 10), // Espacio después del título
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start, // Alinea los textos a la izquierda
                        children: [
                          TextField(
                            controller: jugadoresController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cantidad de jugadores',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                          SizedBox(height: 12),
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
                                      TextEditingController
                                      ganadoresController =
                                          TextEditingController();
                                      return AlertDialog(
                                        title: Text(
                                          "Ingrese cantidad de ganadores",
                                        ),
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
                                              int ganadores =
                                                  int.tryParse(
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
                                              style: TextStyle(
                                                color: Colors.green,
                                              ),
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
                          SizedBox(height: 20),
                          Text(
                            resultado,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
