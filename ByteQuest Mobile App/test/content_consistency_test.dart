import 'package:bytequest/data/mission_content_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('COC 2 identification answer keys exist in their option sets', () {
    final questions = MissionContentData.getCOC2M1Questions();

    for (final question in questions) {
      expect(
        question.options,
        contains(question.correctAnswer),
        reason: '${question.id} has an impossible answer key',
      );
    }
  });

  test('RJ45 practice components and targets use one shared sequence', () {
    final sequence = MissionContentData.getCOC2M2WireSequence();

    expect(sequence, hasLength(8));
    expect(sequence.toSet(), hasLength(8));
    expect(sequence.every((color) => color.trim().isNotEmpty), isTrue);
  });

  test('COC2 IP scenario rejects IPv4 octets outside 0 to 255', () {
    final config = MissionContentData.getCOC2M5ConfigData();
    final ipConfig = config['ipAddress'] as Map<String, dynamic>;
    final validation = RegExp(ipConfig['validation'] as String);

    expect(validation.hasMatch('192.168.1.100'), isTrue);
    expect(validation.hasMatch('192.168.1.255'), isTrue);
    expect(validation.hasMatch('192.168.1.256'), isFalse);
    expect(validation.hasMatch('192.168.1.999'), isFalse);
    expect(validation.hasMatch('192.168.1.01'), isFalse);
  });
}
