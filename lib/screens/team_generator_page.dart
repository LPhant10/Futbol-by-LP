import 'package:flutter/material.dart';

import 'players_generate_screen.dart';
import 'match_screen.dart';
import 'generated_teams_screen.dart';
import 'payment_calculator_screen.dart'; // Corregido el nombre del archivo


class TeamGeneratorPage extends StatelessWidget {
  const TeamGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imagen de fondo que ocupa toda la pantalla
        Positioned.fill(
          child: Opacity(
            opacity: 0.3, // Ajusta la opacidad si deseas
            child: Image.asset(
              "assets/fondoP.jpg", // Ruta de la imagen
              fit:
                  BoxFit
                      .cover, // Esto asegura que la imagen cubra toda la pantalla
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        // Scaffold con fondo transparente para que la imagen de fondo sea visible
        Scaffold(
          backgroundColor: Colors.transparent, // Permite ver la imagen de fondo

          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Row(
                    children: [
                      Icon(Icons.sports_soccer, color: Colors.white, size: 30),
                      SizedBox(width: 8),
                      Text(
                        'PICHANGA by LP ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      Icon(Icons.sports_soccer, color: Colors.white, size: 30),
                    ],
                  ),
                ),
                // Expande la columna para centrar los botones en la pantalla
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize
                              .min, // Asegura que los botones no ocupen toda la pantalla
                      children: [
                        SizedBox(
                          width: 200, // Tamaño fijo para todos los botones
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayersGenerateScreen(),
                                ),
                              );
                            },
                            child: Text("Pichangeros"),
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GeneratedTeamsScreen(),
                                ),
                              );
                            },
                            child: Text("Ver Equipos Generados"),
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MatchScreen(),
                                ),
                              );
                            },
                            child: Text("Ir a Partido"),
                          ),
                        ),

                        // En TeamGeneratorPage.dart
                        SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {


                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => PaymentCalculatorScreen(
                                        /* totalPlayers:
                                            0, */ // <= Se pasa un valor por defecto
                                            
                                        fromEndMatch: false, allPlayers: [],
                                      ),
                                ),
                              );
                            },
                            
                            child: Text("Pagos"),
                          ),
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
    );
  }
}
