import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/services/audio_metadata_utils.dart';

void main() {
  group('replayGainToVolume', () {
    test('null returns 1.0', () {
      expect(replayGainToVolume(null), 1.0);
    });

    test('0 dB returns 1.0', () {
      expect(replayGainToVolume(0), closeTo(1.0, 0.001));
    });

    test('-6 dB roughly halves volume', () {
      // -6 dB ≈ 0.5
      expect(replayGainToVolume(-6), closeTo(0.5, 0.02));
    });

    test('+6 dB roughly doubles volume', () {
      // +6 dB ≈ 2.0
      expect(replayGainToVolume(6), closeTo(2.0, 0.02));
    });

    test('-3 dB is about 0.7', () {
      expect(replayGainToVolume(-3), closeTo(0.708, 0.01));
    });

    test('+3 dB is about 1.4', () {
      expect(replayGainToVolume(3), closeTo(1.412, 0.01));
    });

    test('clamps to minimum 0.25', () {
      // -20 dB would be 0.1, but should clamp to 0.25
      expect(replayGainToVolume(-20), 0.25);
      expect(replayGainToVolume(-50), 0.25);
    });

    test('clamps to maximum 2.0', () {
      // +10 dB would be ~3.16, but should clamp to 2.0
      expect(replayGainToVolume(10), 2.0);
      expect(replayGainToVolume(20), 2.0);
    });

    test('typical replaygain values', () {
      // most tracks fall between -10 and +5 dB
      expect(replayGainToVolume(-8), closeTo(0.398, 0.01));
      expect(replayGainToVolume(-5), closeTo(0.562, 0.01));
      expect(replayGainToVolume(-2), closeTo(0.794, 0.01));
      expect(replayGainToVolume(2), closeTo(1.259, 0.01));
    });
  });
}
