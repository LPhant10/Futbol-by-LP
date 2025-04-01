import 'package:flutter/material.dart';
import 'players_generate_screen.dart';
import 'match_screen.dart';
import 'generated_teams_screen.dart';
import 'payment_calculator_screen.dart.dart';

class TeamGeneratorPage extends StatelessWidget {
  const TeamGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/fondoP.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.5),
            BlendMode.dstATop,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Para ver el fondo
        appBar: AppBar(
          title: Center(child: Text("⚽ PICHANGA by LP ⚽", style: TextStyle(color: Colors.white))),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200, // Tamaño fijo para todos los botones
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlayersGenerateScreen()),
                    );
                  },
                  child: Text("Jugadores"),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GeneratedTeamsScreen()),
                    );
                  },
                  child: Text("Ver Equipos Guardados"),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MatchScreen()),
                    );
                  },
                  child: Text("Ir a Partido"),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PaymentCalculatorScreen()),
                    );
                  },
                  child: Text("Pagos"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
