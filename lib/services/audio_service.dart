// Lógica para reproducir sonidos usando la nueva API

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  Future<void> playSound(String assetName) async {
    final player = AudioPlayer();
    await player.play(AssetSource(assetName));
  }
}
