import 'package:binary/binary.dart';
import 'package:meta/meta.dart';

/// Represents a decoded `THUMB` instruction based on `ARMv4T` architecture.
abstract class ThumbInstruction {
  /// Returns a [ThumbInstruction] by decoding a 16-bit [encoded] value.
  ///
  /// Throws a [FormatException] if unrecognized.
  factory ThumbInstruction.decode(Uint16 encoded) {
    ThumbInstruction decoded;
    for (final format in ThumbDecoder.formats) {
      decoded = format.decode(encoded);
      if (decoded != null) {
        return decoded;
      }
    }
    throw FormatException('Not a valid ARMv4T THUMB instruction', encoded);
  }
}

/// Decodes byte-encoded instructions into [ThumbInstruction] instances.
///
/// See http://infocenter.arm.com/help/topic/com.arm.doc.ddi0210c/graphics/thumb_instruction_set_formats.svg.
@visibleForTesting
abstract class ThumbDecoder {
  /// Known THUMB-formats that require different decoders.
  static final formats = <ThumbDecoder>[
    MoveShiftedRegister(),
    AddAndSubtract(),
    MoveCompareAddAndSubtractImmediate(),
    ALUOperation(),
    HighRegisterOperationsAndBranchExchange(),
    PCRelativeLoad(),
    LoadAndStoreWithRelativeOffset(),
    LoadAndStoreHalfword(),
    LoadAndStoreWithImmediateOffset(),
    SPRelativeLoadAndStore(),
    LoadAddress(),
    AddOffsetToStackPointer(),
    PushAndPopRegisters(),
    MultipleLoadAndStore(),
    ConditionalBranch(),
    SoftwareInterrupt(),
    UnconditionalBranch(),
    LongBranchWithLink(),
  ];

  /// Name of the instruction format.
  final String name;

  /// Format type integer.
  final int value;

  /// A mask value used to determine if decoded can be processed for this type.
  final int mask;

  const ThumbDecoder._(this.value, this.name, this.mask)
      : assert(name != null),
        assert(value != null),
        assert(mask != null);

  @nonVirtual
  ThumbInstruction decode(Uint16 encoded) {
    return shouldDecode(encoded) ? _decode(encoded) : null;
  }

  @nonVirtual
  bool shouldDecode(Uint16 encoded) => encoded.value & mask == mask;

  /// Implementation of [decode].
  ThumbInstruction _decode(Uint16 encoded) => throw UnimplementedError();
}

@visibleForTesting
class MoveShiftedRegister extends ThumbDecoder {
  MoveShiftedRegister()
      : super._(
          01,
          'Move shifted register',
          '111'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class AddAndSubtract extends ThumbDecoder {
  AddAndSubtract()
      : super._(
          02,
          'Add and subtract',
          '000111'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class MoveCompareAddAndSubtractImmediate extends ThumbDecoder {
  MoveCompareAddAndSubtractImmediate()
      : super._(
          03,
          'Move, compare, add, and subtract immediate',
          '001'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class ALUOperation extends ThumbDecoder {
  ALUOperation()
      : super._(
          04,
          'ALU operation',
          '01'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class HighRegisterOperationsAndBranchExchange extends ThumbDecoder {
  HighRegisterOperationsAndBranchExchange()
      : super._(
          05,
          'High register operations and branch exchange',
          '010001'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class PCRelativeLoad extends ThumbDecoder {
  PCRelativeLoad()
      : super._(
          06,
          'PC-relative load',
          '01001'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class LoadAndStoreWithRelativeOffset extends ThumbDecoder {
  LoadAndStoreWithRelativeOffset()
      : super._(
          07,
          'Load and store with relative offset',
          '0101'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class LoadAndStoreSignExtendedByteAndHalfword extends ThumbDecoder {
  LoadAndStoreSignExtendedByteAndHalfword()
      : super._(
          08,
          'Load and store sign-extended byte and halfword',
          '0101001'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class LoadAndStoreWithImmediateOffset extends ThumbDecoder {
  LoadAndStoreWithImmediateOffset()
      : super._(
          09,
          'Load and store with immediate offset',
          '011'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class LoadAndStoreHalfword extends ThumbDecoder {
  LoadAndStoreHalfword()
      : super._(
          10,
          'Load and store halfword',
          '1'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class SPRelativeLoadAndStore extends ThumbDecoder {
  SPRelativeLoadAndStore()
      : super._(
          11,
          'SP-relative load and store',
          '1001'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class LoadAddress extends ThumbDecoder {
  LoadAddress()
      : super._(
          12,
          'Load address',
          '101'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class AddOffsetToStackPointer extends ThumbDecoder {
  AddOffsetToStackPointer()
      : super._(
          13,
          'Add offset to stack pointer',
          '1011'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class PushAndPopRegisters extends ThumbDecoder {
  PushAndPopRegisters()
      : super._(
          14,
          'Push and pop registers',
          '101101'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class MultipleLoadAndStore extends ThumbDecoder {
  MultipleLoadAndStore()
      : super._(
          15,
          'Multiple load and store',
          '1100'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class ConditionalBranch extends ThumbDecoder {
  ConditionalBranch()
      : super._(
          16,
          'Conditional branch',
          '1101'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class SoftwareInterrupt extends ThumbDecoder {
  SoftwareInterrupt()
      : super._(
          17,
          'Software interrupt',
          '11011111'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class UnconditionalBranch extends ThumbDecoder {
  UnconditionalBranch()
      : super._(
          18,
          'Unconditional branch',
          '111'.padRight(16, '0').parseBits(),
        );
}

@visibleForTesting
class LongBranchWithLink extends ThumbDecoder {
  LongBranchWithLink()
      : super._(
          19,
          'Long branch with link',
          '1111'.padRight(16, '0').parseBits(),
        );
}
