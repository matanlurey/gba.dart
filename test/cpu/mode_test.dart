import 'package:gba/src/cpu/mode.dart';
import 'package:binary/binary.dart';
import 'package:test/test.dart';

void main() {
  group('should have correct bits for Arm7TdmiProcessorMode:', () {
    test('user', () {
      expect(Arm7TdmiProcessorMode.user.bits.toBinary(), '1' '0000');
    });

    test('fiq', () {
      expect(Arm7TdmiProcessorMode.fiq.bits.toBinary(), '1' '0001');
    });

    test('irq', () {
      expect(Arm7TdmiProcessorMode.irq.bits.toBinary(), '1' '0010');
    });

    test('svc', () {
      expect(Arm7TdmiProcessorMode.svc.bits.toBinary(), '1' '0011');
    });

    test('und', () {
      expect(Arm7TdmiProcessorMode.und.bits.toBinary(), '1' '1011');
    });

    test('system', () {
      expect(Arm7TdmiProcessorMode.system.bits.toBinary(), '1' '1111');
    });
  });
}
