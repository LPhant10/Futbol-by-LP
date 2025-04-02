import 'package:flutter/material.dart';
import 'players_generate_screen.dart';
import 'match_screen.dart';
import 'generated_teams_screen.dart';
import 'payment_calculator_screen.dart';

class TeamGeneratorPage extends StatelessWidget {
  const TeamGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: 0.3,
            duration: Duration(milliseconds: 300),
            child: Image.asset(
              "assets/fondoP.jpg",
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
              children: [
                SizedBox(height: 50),

                // TÍTULO CENTRADO
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.sports_soccer, color: Colors.white, size: 30),
                      SizedBox(width: 8),
                      Text(
                        'PICHANGA by LP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.sports_soccer, color: Colors.white, size: 30),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // BOTONES
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildZeroTransitionButton(context, "Pichangeros", const PlayersGenerateScreen()),
                        buildZeroTransitionButton(context, "Ver Equipos Generados", const GeneratedTeamsScreen()),
                        buildZeroTransitionButton(context, "Ir a Partido", const MatchScreen()),
                        buildZeroTransitionButton(
                          context,
                          "Pagos",
                          const PaymentCalculatorScreen(
                            fromEndMatch: false,
                            allPlayers: [],
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

  /// Botón con push sin transición (elimina parpadeo)
 Widget buildZeroTransitionButton(BuildContext context, String label, Widget screen) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => screen,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        child: Text(label),
      ),
    ),
  );
}

}
