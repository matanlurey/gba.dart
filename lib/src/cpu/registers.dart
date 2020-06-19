import 'dart:typed_data';

import 'package:binary/binary.dart';
import 'package:gba/src/util.dart';

import 'mode.dart';

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

  /// Create a new default [Arm7TdmiRegisters] instance and state.
  factory Arm7TdmiRegisters() {
    final data = Uint32List(totalRegisters);
    data[_cpsr] = Arm7TdmiProcessorMode.user.bits;
    return Arm7TdmiRegisters._(data);
  }

  /// Creates a new [Arm7TdmiRegisters] encapsulating memory storage.
  ///
  /// A defensive copy of [data] is made.
  ///
  /// See [toData] for the expectations in the data format.
  Arm7TdmiRegisters.from(Uint32List data) : _data = Uint32List.fromList(data) {
    if (data.length != totalRegisters) {
      throw ArgumentError.value(
        data,
        'data',
        'Must have exact length of $totalRegisters.',
      );
    }
    _cpsrWrapper = CPSR._(this);
  }

  Arm7TdmiRegisters._(this._data) {
    _cpsrWrapper = CPSR._(this);
  }

  /// Returns a debuggable label for the given [index].
  String labelRegister(int index) {
    RangeError.checkValueInInterval(index, 0, 15);
    if (index <= 7) {
      return 'r$index';
    }
    final mode = cpsr.mode;
    if (index >= 8 && index <= 12) {
      if (mode == Arm7TdmiProcessorMode.fiq) {
        return 'r${index}_fiq';
      } else {
        return 'r$index';
      }
    }
    if (index >= 13 && index <= 14) {
      switch (mode) {
        case Arm7TdmiProcessorMode.user:
        case Arm7TdmiProcessorMode.system:
          return index == 13 ? 'SP' : 'LR';
        case Arm7TdmiProcessorMode.fiq:
          return 'r${index}_fiq';
        case Arm7TdmiProcessorMode.svc:
          return 'r${index}_svc';
        case Arm7TdmiProcessorMode.abt:
          return 'r${index}_abt';
        case Arm7TdmiProcessorMode.irq:
          return 'r${index}_irq';
        case Arm7TdmiProcessorMode.und:
          return 'r${index}_und';
        default:
          throw StateError('Invalid mode: $mode');
      }
    }
    if (index == 15) {
      return 'PC';
    }
    throw StateError('Execution should never occur here: $index.');
  }

  /// If a specific operating mode is in effect, returns [index] re-written.
  int _redirectToBankedRegister(int index) {
    // r0 -> r7 is not directed. PC is not directed. CPSR is not directed.
    if (index <= 7 || index == 15 || index == 16) {
      return index;
    }
    // r8 -> r12 is redirected in FIQ mode.
    final mode = cpsr.mode;
    if (index >= 8 && index <= 12) {
      if (mode == Arm7TdmiProcessorMode.fiq) {
        // r8 -- index 8 -- index 17 (+9)
        return index + 9;
      } else {
        return index;
      }
    }
    // r13 -> r14 is redirected in FIQ, SVC, ABT, IRQ, UND.
    if (index >= 13 && index <= 14) {
      switch (mode) {
        case Arm7TdmiProcessorMode.user:
        case Arm7TdmiProcessorMode.system:
          return index;
        case Arm7TdmiProcessorMode.fiq:
          // r13 -- index 13 -- index 21 (+9)
          return index + 9;
        case Arm7TdmiProcessorMode.svc:
          // r13 -- index 13 -- index 25 (+12)
          return index + 12;
        case Arm7TdmiProcessorMode.abt:
          // r13 -- index 13 -- index 28 (+15)
          return index + 15;
        case Arm7TdmiProcessorMode.irq:
          // r13 -- index 13 -- index 31 (+18)
          return index + 18;
        case Arm7TdmiProcessorMode.und:
          // r13 -- index 13 -- index 34 (+21)
          return index + 21;
        default:
          throw StateError('Invalid mode: $mode');
      }
    }
    throw RangeError.range(index, 0, 16);
  }

  /// An unchecked version of `operator []` for internal use.
  Uint32 _read(int index) {
    return _data[_redirectToBankedRegister(index)].asUint32();
  }

  /// An unchecked version of `operator []=` for internal use.
  void _write(int index, Uint32 value) {
    _data[_redirectToBankedRegister(index)] = value.value;
  }

  /// Reads the data stored at register [index], from `0` to `15`.
  ///
  /// `0` to `12` are considered the "general purpose" registers, and each has
  /// the same functionality and performance, i.e. there is no "fast
  /// accumulator" for arithmetic operations, and no "special pointer register"
  /// for memory addressing.
  ///
  /// However, in [CPSR.thumb] mode, only r0 -> r7 ("lo registers") may be
  /// accessed freely, while r8 -> 12, and up ("hi registers") can only be
  /// accesssed by some instructions.
  ///
  /// See [sp] for `13`, [lr] for `14`, [pc] for `15`, and [cpsr] for `16`.
  Uint32 operator [](int index) {
    if (index > 15) {
      throw RangeError.value(index, 'index', 'Can only access up to r15.');
    }
    return _read(index);
  }

  /// Writes the data to store at register [index], from `0` to `15`.
  ///
  /// `0` to `12` are considered the "general purpose" registers, and each has
  /// the same functionality and performance, i.e. there is no "fast
  /// accumulator" for arithmetic operations, and no "special pointer register"
  /// for memory addressing.
  ///
  /// However, in [CPSR.thumb] mode, only r0 -> r7 ("lo registers") may be
  /// accessed freely, while r8 -> 12, and up ("hi registers") can only be
  /// accesssed by some instructions.
  ///
  /// See [sp] for `13`, [lr] for `14`, [pc] for `15`, and [cpsr] for `16`.
  void operator []=(int index, Uint32 value) {
    if (index > 15) {
      throw RangeError.value(index, 'index', 'Can only access up to r15.');
    }
    return _write(index, value);
  }

  static const _sp = 13;

  /// The value at `r13`, also known as the _Stack Pointer_ (register).
  ///
  /// Used primarily for maintaining the address of the stack. While in `ARM`
  /// state the user may decide to use `r13` and/or other register(s) as stack
  /// pointer(s), or as a general purpose register.
  ///
  /// There's a separate `r13` register for each [CPSR.mode], and (when used as
  /// `SP`) each exception handler **must** use its own stack.
  ///
  /// The default value (initialized by the BIOS) differs depending on the mode:
  /// ```txt
  /// User/System:  0x03007F00
  /// IRQ:          0x03007FA0
  /// Supervisor:   0x03007FE0
  /// ```
  Uint32 get sp => _read(_sp);
  set sp(Uint32 sp) => _write(_sp, sp);

  static const _lr = 14;

  /// The value at `r14`, also known as the _Link Register_.
  ///
  /// Used primarily to store the address following a `BL` (_Branch with Link_)
  /// instruction (as used in function calls) - i.e. the old value of [pc] is
  /// saved in this register.
  ///
  /// > NOTE: In `ARM` mode, `r14` may be used as a general purpose register
  /// > also, provided that usage as a `LR` regsiter isn't required.
  Uint32 get lr => _read(_lr);
  set lr(Uint32 lr) => _write(_lr, lr);

  static const _pc = 15;

  /// The value at `r15`, also known as the _Program Counter_.
  ///
  /// Because the ARM7/TDMI uses a 3-stage pipeline ("fetch", "decode"
  /// "execute"), this register always contains an address which is 2
  /// instructions ahead of the one currrently being executed.
  Uint32 get pc => _read(_pc);
  set pc(Uint32 pc) => _write(_pc, pc);

  static const _cpsr = 16;

  /// The value at `r16`, also known as the _Current Program Status Regsiter_.
  ///
  /// This contains the status bits relevant to the CPU. See [CPSR].
  CPSR get cpsr => _cpsrWrapper;
  CPSR _cpsrWrapper;

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
}

/// Encapsulates acccess to `r16` in [Registers].
class CPSR {
  final Arm7TdmiRegisters _registers;

  const CPSR._(this._registers);

  /// Raw value of the register.
  Uint32 get value => _registers._read(Arm7TdmiRegisters._cpsr);
  set value(Uint32 value) => _registers._write(Arm7TdmiRegisters._cpsr, value);

  /// The operating mode, bits `4` -> `0` in the CPSR.
  Arm7TdmiProcessorMode get mode {
    final value = this.value.bitRange(4, 0).value;
    for (final mode in Arm7TdmiProcessorMode.values) {
      if (mode.bits == value) {
        return mode;
      }
    }
    throw StateError('Unexpected mode bits: ${value.toBinaryPadded(5)}.');
  }

  set mode(Arm7TdmiProcessorMode newMode) {
    switch (newMode) {
      case Arm7TdmiProcessorMode.user:
      case Arm7TdmiProcessorMode.system:
        break;
      default:
        _saveCPSR(newMode);
    }
    // Actually write the current bits.
    value = value.replaceBitRange(4, 0, newMode.bits);
  }

  static const _spsrFiq = 24;
  static const _spsrSvc = 27;
  static const _spsrAbt = 30;
  static const _spsrIrq = 33;
  static const _spsrUnd = 36;

  /// Writes a copy of the CPSR to SPSR_{mode} (where `{mode}` is [mode]).
  void _saveCPSR(Arm7TdmiProcessorMode mode) {
    int index;
    switch (mode) {
      case Arm7TdmiProcessorMode.fiq:
        index = _spsrFiq;
        break;
      case Arm7TdmiProcessorMode.svc:
        index = _spsrSvc;
        break;
      case Arm7TdmiProcessorMode.abt:
        index = _spsrAbt;
        break;
      case Arm7TdmiProcessorMode.irq:
        index = _spsrIrq;
        break;
      case Arm7TdmiProcessorMode.und:
        index = _spsrUnd;
        break;
      default:
        throw StateError('Invalid: $mode');
    }
    _registers._data[index] = value.value;
  }

  static const _T = 5;
  static const _F = 6;
  static const _I = 7;
  static const _V = 28;
  static const _C = 29;
  static const _Z = 30;
  static const _N = 31;

  /// Thumb state indicator.
  ///
  /// If set (`true`), the CPU is in `THUMB` state. Otherwise it operates in
  /// normal `ARM` state. Software should never attempted to modify this bit
  /// itself.
  bool get thumb => value.isSet(_T);
  set thumb(bool thumb) {
    value = thumb ? value.setBit(_T) : value.clearBit(_T);
  }

  /// FIQ interrupt disable.
  ///
  /// Set this (to `true`) in order to disable FIQ interrupts.
  bool get disableFiq => value.isSet(_F);
  set disableFiq(bool disable) {
    value = disable ? value.setBit(_F) : value.clearBit(_F);
  }

  /// IRQ interrupt disable.
  ///
  /// Set this (to `true`) in order to disable IRQ interrupts.
  ///
  /// > NOTE: On the GBA this is set by default whenevner IRQ mode is entered.
  bool get disableIrq => value.isSet(_I);
  set disableIrq(bool disable) {
    value = disable ? value.setBit(_I) : value.clearBit(_I);
  }

  /// Overflow (`V`) condition code.
  bool get overflow => value.isSet(_V);
  set overflow(bool overflow) {
    value = overflow ? value.setBit(_V) : value.clearBit(_V);
  }

  /// Carry/Borrow/Extend (`C`) condition code.
  bool get carryBorrowExtend => value.isSet(_C);
  set carryBorrowExtend(bool carryBorrowExtend) {
    value = carryBorrowExtend ? value.setBit(_C) : value.clearBit(_C);
  }

  /// Overflow (`Z`) condition code.
  bool get zeroEqual => value.isSet(_Z);
  set zeroEqual(bool zeroEqual) {
    value = zeroEqual ? value.setBit(_Z) : value.clearBit(_Z);
  }

  /// Negative/Less than (`N`) condition code.
  bool get negativeLessThan => value.isSet(_N);
  set negativeLessThan(bool negativeLessThan) {
    value = negativeLessThan ? value.setBit(_N) : value.clearBit(_N);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'CPSR {${value.toBinaryPadded()}}';
    } else {
      return super.toString();
    }
  }
}
