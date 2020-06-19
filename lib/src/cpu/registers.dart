import 'dart:typed_data';

import 'package:binary/binary.dart';

/// Encapsulates the registers available to the ARM7/TDMI processor.
///
/// There are a total of 16 "user-visible" registers, 1 processor internal
/// register (the CPSR, or Current Program Status Register), and 20 additional
/// ("banked") registers that are swapped in for user-visible registers when the
/// CPU changes to various privilege modes:
/// ```md
/// | System/User | FIQ      | Supervisor | Abort    | IRQ      | Undefined |
/// |-------------|----------|------------|----------|----------|-----------|
/// | r0          | r0       | r0         | r0       | r0       | r0        |
/// | r1          | r1       | r1         | r1       | r1       | r1        |
/// | r2          | r2       | r2         | r2       | r2       | r2        |
/// | r3          | r3       | r3         | r3       | r3       | r3        |
/// | r4          | r4       | r4         | r4       | r4       | r4        |
/// | r5          | r5       | r5         | r5       | r5       | r5        |
/// | r6          | r6       | r6         | r6       | r6       | r6        |
/// | r7          | r7       | r7         | r7       | r7       | r7        |
/// | r8          | r8_fiq   | r8         | r8       | r8       | r8        |
/// | r9          | r9_fiq   | r9         | r9       | r9       | r9        |
/// | r10         | r10_fiq  | r10        | r10      | r10      | r10       |
/// | r11         | r11_fiq  | r11        | r11      | r11      | r11       |
/// | r12         | r12_fiq  | r12        | r12      | r12      | r12       |
/// | r13 (SP)    | r13_fiq  | r13_svc    | r13_abt  | r13_irq  | r13_und   |
/// | r14 (LR)    | r14_fiq  | r14_svc    | r14_abt  | r14_irq  | r14_und   |
/// | r15 (PC)    | r15      | r15        | r15      | r15      | r15       |
/// | CPSR        | CPSR     | CPSR       | CPSR     | CPSR     | CPSR      |
/// | --          | SPSR_fiq | SPSR_svc   | SPSR_abt | SPSR_irq | SPSR_und  |
/// ```
class Arm7TdmiRegisters {
  static const userVisibleRegisters = 16 + 1;
  static const bankedRegisters = 20;
  static const totalRegisters = userVisibleRegisters + bankedRegisters;

  final Uint32List _data;

  /// Creates a new [Arm7TdmiRegisters] encapsulating memory storage.
  ///
  /// See [toData] for the expectations in the data format.
  Arm7TdmiRegisters(this._data) : assert(_data.length == totalRegisters);

  /// Returns a defensive copy of the underlying memory representation.
  ///
  /// ```txt
  /// - 00 -> 15: r0 -> 15.
  /// - 16:       CPSR
  /// - 17 -> 23: r8_fiq -> r14_fiq
  /// - 24:       SPSR_fiq
  /// - 25 -> 26: r13_svc -> r14_svc
  /// - 27:       SPSR_svc
  /// - 28 -> 29: r13_abt -> r14_abt
  /// - 30:       SPSR_abt
  /// - 31 -> 32: r13_irq -> r14_irq
  /// - 33:       SPSR_irq
  /// - 34 -> 35: r13_und -> r14_und
  /// - 36:       SPSR_und
  /// ```
  Uint32List toData() => Uint32List.fromList(_data);

  /// If a specific operating mode is in effect, returns [index] re-written.
  int _redirectToBankedRegister(int index) => index;

  /// An unchecked version of `operator []` for internal use.
  Int32 _read(int index) {
    return _data[_redirectToBankedRegister(index)].asInt32();
  }

  /// An unchecked version of `operator []=` for internal use.
  void _write(int index, Int32 value) {
    _data[_redirectToBankedRegister(index)] = value.value;
  }

  /// Reads the data stored at register [index], from `0` to `15`.
  Int32 operator [](int index) {
    if (index > 15) {
      throw RangeError.value(index, 'index', 'Can only access up to r15.');
    }
    return _read(index);
  }

  /// Writes the data to store at register [index], from `0` to `15`.
  void operator []=(int index, Int32 value) {
    if (index > 15) {
      throw RangeError.value(index, 'index', 'Can only access up to r15.');
    }
    return _write(index, value);
  }

  static const _sp = 13;

  /// The value at `r13`, also known as the _Stack Pointer_ (register).
  ///
  /// Used primarily for maintaining the address of the stack.
  ///
  /// The default value (initialized by the BIOS) differs depending on the mode:
  /// ```txt
  /// User/System:  0x03007F00
  /// IRQ:          0x03007FA0
  /// Supervisor:   0x03007FE0
  /// ```
  Int32 get sp => _read(_sp);
  set sp(Int32 sp) => _write(_sp, sp);

  static const _lr = 14;

  /// The value at `r14`, also known as the _Link Register_.
  ///
  /// Used primarily to store the address following a "bl" (_branch and link_)
  /// instruction (as used in function calls).
  Int32 get lr => _read(_lr);
  set lr(Int32 lr) => _write(_lr, lr);

  static const _pc = 15;

  /// The value at `r15`, also known as the _Program Counter_.
  ///
  /// Because the ARM7/TDMI uses a 3-stage pipeline ("fetch", "decode"
  /// "execute"), this register always contains an address which is 2
  /// instructions ahead of the one currrently being executed.
  Int32 get pc => _read(_pc);
  set pc(Int32 pc) => _write(_pc, pc);
}
