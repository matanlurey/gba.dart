import 'package:binary/binary.dart';

enum ThumbBinaryOpcodeFormat {
  // ---------------------------------------------------------------------------
  // Register Opterations (ALU, BLX)
  // ---------------------------------------------------------------------------

  /// Move Shifted Register.
  moveShiftedRegister,

  /// Add or Subtract.
  addOrSubtract,

  /// Move, Compare, Add, Subtract Immediate.
  moveOrCompareOrAddOrSubtractImmediate,

  /// ALU Operations.
  aluOperations,

  /// Hi Register Operations or Branch Exchange.
  hiRegisterOperationsOrBranchExchange,

  // ---------------------------------------------------------------------------
  // Memory Load/Store (LDR/STR)
  // ---------------------------------------------------------------------------

  /// Load PC-Relative (for loading immediates from the literal pool).
  loadPcRelative,

  /// Load or Store with Register Offset.
  loadOrStoreWithRegisterOffset,

  /// Load or Store Sign-Extended Byte/Half-Word.
  loadOrStoreSignExtendedByteOrHalfWord,

  /// Load or Store with Immediate Offset.
  loadOrStoreWithImmediateOffset,

  /// Load or Store Half-Word.
  loadOrStoreHalfWord,

  /// Load or Store SP-Relative.
  loadOrStoreSpRelative,

  // ---------------------------------------------------------------------------
  // Memory Addressing (ADD PC/SP)
  // ---------------------------------------------------------------------------

  /// Get Relative Address.
  getRelativeAddress,

  /// Add Offset to Stack Pointer.
  addOffsetToStackPointer,

  // ---------------------------------------------------------------------------
  // Memory Multiple Load/Store (PUSH/POP and LDM/STM)
  // ---------------------------------------------------------------------------

  /// Push or Pop Registers.
  pushOrPopRegisters,

  /// Multiple Load or Store.
  multipleLoadOrStore,

  // ---------------------------------------------------------------------------
  // Jumps and Calls
  // ---------------------------------------------------------------------------

  /// Conditional Branch.
  conditionalBranch,

  /// Unconditional Branch.
  unconditionalBranch,

  /// Long Branch with Link.
  longBranchWithLink,

  /// Software Interrupt and Breakpoint.
  softwareInterruptAndBreakpoint,
}

extension ThumbBinaryOpcodeFormatX on ThumbBinaryOpcodeFormat {
  /// Matches a [ThumbBinaryOpcodeFormat] type given an [encoded] instruction.
  static ThumbBinaryOpcodeFormat match(Uint32 encoded) {
    for (var i = ThumbBinaryOpcodeFormat.values.length - 1; i >= 0; i--) {
      final format = ThumbBinaryOpcodeFormat.values[i];
      if (encoded.value & format.mask == format.mask) {
        return format;
      }
    }
    throw StateError('No match found: ${encoded.toBinaryPadded()}');
  }

  static final _masks = [
    ('0000' '0000' '0000' '0000'.parseBits()), // 01: Move Shifted Register.
    ('0001' '1100' '0000' '0000'.parseBits()), // 02: Add And Subtract.
    ('0010' '0000' '0000' '0000'.parseBits()), // 03: Move, Compare, Add, ...
    ('0100' '0000' '0000' '0000'.parseBits()), // 04: ALU Operation.
    ('0100' '0100' '0000' '0000'.parseBits()), // 05: High Register ...
    ('0100' '1000' '0000' '0000'.parseBits()), // 06: PC-Relative Load.
    ('0101' '0000' '0000' '0000'.parseBits()), // 07: Load And Store With ...
    ('0101' '0010' '0000' '0000'.parseBits()), // 08: Load And Store Sign-...
    ('0110' '0000' '0000' '0000'.parseBits()), // 09: Load And Store With ...
    ('1000' '0000' '0000' '0000'.parseBits()), // 10: Load And Store Half-World.
    ('1001' '0000' '0000' '0000'.parseBits()), // 11: SP-Relative Load And ...
    ('1010' '0000' '0000' '0000'.parseBits()), // 12: Load Address.
    ('1011' '0000' '0000' '0000'.parseBits()), // 13: Add Offset To Stack ...
    ('1011' '0100' '0000' '0000'.parseBits()), // 14: Push And Pop Registers.
    ('1100' '0000' '0000' '0000'.parseBits()), // 15: Multiple Load And Store.
    ('1101' '0000' '0000' '0000'.parseBits()), // 16: Conditional Branch.
    ('1101' '1111' '0000' '0000'.parseBits()), // 17: Software Interrupt.
    ('1110' '0000' '0000' '0000'.parseBits()), // 18: Unconditional Branch.
    ('1111' '0000' '0000' '0000'.parseBits()), // 19: Long Branch With Link.
  ];

  /// Mask value to match this format in an encoded instruction.
  int get mask => _masks[index];
}
