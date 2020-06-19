import 'package:gba/src/cpu/registers.dart';

/// Emulates a 16.78 MHz ARM7/TDMI RISC processor.
class Arm7TdmiProcessor {
  // ignore: unused_field
  final Arm7TdmiRegisters _registers;

  Arm7TdmiProcessor({
    Arm7TdmiRegisters registers,
  }) : this._(registers ?? Arm7TdmiRegisters());

  Arm7TdmiProcessor._(this._registers) : assert(_registers != null);
}
