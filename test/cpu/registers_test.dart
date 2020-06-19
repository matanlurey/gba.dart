import 'package:gba/src/cpu/mode.dart';
import 'package:gba/src/cpu/registers.dart';
import 'package:test/test.dart';

void main() {
  test('should default to an initial state with "user" set', () {
    final registers = Arm7TdmiRegisters();
    expect(registers.cpsr.mode, Arm7TdmiProcessorMode.user);
  });

  test('should be able to write and read the mode bits', () {
    final registers = Arm7TdmiRegisters();
    registers.cpsr.mode = Arm7TdmiProcessorMode.svc;
    expect(registers.cpsr.mode, Arm7TdmiProcessorMode.svc);
  });
}
