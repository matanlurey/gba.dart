import 'package:binary/binary.dart';
import 'package:gba/src/cpu/mode.dart';
import 'package:gba/src/cpu/registers.dart';
import 'package:test/test.dart';

void main() {
  group('CPSR', () {
    test('should default to an initial state with "user" set', () {
      final registers = Arm7TdmiRegisters();
      expect(registers.cpsr.mode, Arm7TdmiProcessorMode.user);
    });

    test('should be able to write and read the mode bits', () {
      final registers = Arm7TdmiRegisters();
      registers.cpsr.mode = Arm7TdmiProcessorMode.svc;
      expect(registers.cpsr.mode, Arm7TdmiProcessorMode.svc);
    });

    test('should be able to write and read other CPSR bits', () {
      final registers = Arm7TdmiRegisters();
      registers.cpsr
        ..thumb = true
        ..disableFiq = true
        ..disableIrq = true
        ..overflow = true
        ..carryBorrowExtend = true
        ..zeroEqual = true
        ..negativeLessThan = true;
      expect(
          registers.cpsr.value.toBinaryPadded(),
          '1111' // N Z C V
          '0000' // R
          '0000' // R
          '0000' // R
          '0000' // R
          '0000' // R
          '1111' // I F T M
          '0000' // M M M M
          );
      registers.cpsr
        ..thumb = false
        ..disableFiq = false
        ..disableIrq = false
        ..overflow = false
        ..carryBorrowExtend = false
        ..zeroEqual = false
        ..negativeLessThan = false;
      expect(
          registers.cpsr.value.toBinaryPadded(),
          '0000' // N Z C V
          '0000' // R
          '0000' // R
          '0000' // R
          '0000' // R
          '0000' // R
          '0001' // I F T M
          '0000' // M M M M
          );
    });
  });

  group('Banked registers', () {
    Arm7TdmiRegisters registers;

    setUp(() => registers = Arm7TdmiRegisters());

    void writeRange(int start, int end, [int value = 1]) {
      for (var i = start; i <= end; i++) {
        registers[i] = value.asUint32();
      }
    }

    group('should not be used for r0 -> r7', () {
      String r0To7() => registers
          .toData()
          .sublist(0, 8)
          .map((i) => i.toRadixString(16))
          .join(' ');

      setUp(() {
        expect(r0To7(), '0 0 0 0 0 0 0 0');
      });

      test('fiq', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.fiq;
        writeRange(0, 7);
        registers.cpsr.mode = Arm7TdmiProcessorMode.user;
        expect(r0To7(), '1 1 1 1 1 1 1 1');
      });

      test('irq', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.irq;
        writeRange(0, 7);
        registers.cpsr.mode = Arm7TdmiProcessorMode.user;
        expect(r0To7(), '1 1 1 1 1 1 1 1');
      });

      test('svc', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.svc;
        writeRange(0, 7);
        registers.cpsr.mode = Arm7TdmiProcessorMode.user;
        expect(r0To7(), '1 1 1 1 1 1 1 1');
      });

      test('abt', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.abt;
        writeRange(0, 7);
        registers.cpsr.mode = Arm7TdmiProcessorMode.user;
        expect(r0To7(), '1 1 1 1 1 1 1 1');
      });

      test('und', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.und;
        writeRange(0, 7);
        registers.cpsr.mode = Arm7TdmiProcessorMode.user;
        expect(r0To7(), '1 1 1 1 1 1 1 1');
      });
    });

    group('should be used for r8 -> 12', () {
      String r8to12() {
        return [
          for (var i = 8; i <= 12; i++) registers[i].value.toRadixString(16)
        ].join(' ');
      }

      test('fiq', () {
        expect(r8to12(), '0 0 0 0 0', reason: 'Starts at 0');
        registers.cpsr.mode = Arm7TdmiProcessorMode.fiq;
        expect(r8to12(), '0 0 0 0 0', reason: 'Still 0 in FIQ');

        writeRange(8, 13);
        expect(r8to12(), '1 1 1 1 1', reason: 'Now 1 in FIQ');

        registers.cpsr.mode = Arm7TdmiProcessorMode.user;
        expect(r8to12(), '0 0 0 0 0', reason: 'Still 0 in USER');
      });
    });

    group('should use the real r8 -> r12', () {
      String r8to12() => registers
          .toData()
          .sublist(8, 13)
          .map((i) => i.toRadixString(16))
          .join(' ');

      test('svc', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.svc;
        writeRange(8, 12);
        expect(r8to12(), '1 1 1 1 1');
      });

      test('abt', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.abt;
        writeRange(8, 12);
        expect(r8to12(), '1 1 1 1 1');
      });

      test('irq', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.irq;
        writeRange(8, 12);
        expect(r8to12(), '1 1 1 1 1');
      });

      test('und', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.und;
        writeRange(8, 12);
        expect(r8to12(), '1 1 1 1 1');
      });
    });

    group('should use the correct r13 -> r14', () {
      String r13to14Real() => registers
          .toData()
          .sublist(13, 15)
          .map((i) => i.toRadixString(16))
          .join(' ');

      String r13to14Virtual() {
        return [
          for (var i = 13; i <= 14; i++) registers[i].value.toRadixString(16)
        ].join(' ');
      }

      test('user', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.user;
        writeRange(13, 14);
        expect(r13to14Real(), r13to14Virtual());
      });

      test('fiq', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.fiq;
        writeRange(13, 14);
        expect(r13to14Real(), isNot(r13to14Virtual()));
      });

      test('svc', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.svc;
        writeRange(13, 14);
        expect(r13to14Real(), isNot(r13to14Virtual()));
      });

      test('abt', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.abt;
        writeRange(13, 14);
        expect(r13to14Real(), isNot(r13to14Virtual()));
      });

      test('irq', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.irq;
        writeRange(13, 14);
        expect(r13to14Real(), isNot(r13to14Virtual()));
      });

      test('und', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.und;
        writeRange(13, 14);
        expect(r13to14Real(), isNot(r13to14Virtual()));
      });
    });

    group('should save CPSR -> SPSR', () {
      int expected;

      setUp(() {
        registers.cpsr.thumb = true;
        expected = registers.cpsr.value.value;
      });

      test('fiq', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.fiq;
        expect(registers.toData()[24], expected);
      });

      test('svc', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.svc;
        expect(registers.toData()[27], expected);
      });

      test('abt', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.abt;
        expect(registers.toData()[30], expected);
      });

      test('irq', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.irq;
        expect(registers.toData()[33], expected);
      });

      test('abt', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.und;
        expect(registers.toData()[36], expected);
      });
    });

    group('should label the registers', () {
      List<String> labels() {
        return [for (var i = 0; i < 16; i++) registers.labelRegister(i)];
      }

      test('user', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.user;
        expect(labels(), [
          'r0',
          'r1',
          'r2',
          'r3',
          'r4',
          'r5',
          'r6',
          'r7',
          'r8',
          'r9',
          'r10',
          'r11',
          'r12',
          'SP',
          'LR',
          'PC'
        ]);
      });

      test('fiq', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.fiq;
        expect(labels(), [
          'r0',
          'r1',
          'r2',
          'r3',
          'r4',
          'r5',
          'r6',
          'r7',
          'r8_fiq',
          'r9_fiq',
          'r10_fiq',
          'r11_fiq',
          'r12_fiq',
          'r13_fiq',
          'r14_fiq',
          'PC'
        ]);
      });

      test('svc', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.svc;
        expect(labels(), [
          'r0',
          'r1',
          'r2',
          'r3',
          'r4',
          'r5',
          'r6',
          'r7',
          'r8',
          'r9',
          'r10',
          'r11',
          'r12',
          'r13_svc',
          'r14_svc',
          'PC'
        ]);
      });

      test('abt', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.abt;
        expect(labels(), [
          'r0',
          'r1',
          'r2',
          'r3',
          'r4',
          'r5',
          'r6',
          'r7',
          'r8',
          'r9',
          'r10',
          'r11',
          'r12',
          'r13_abt',
          'r14_abt',
          'PC'
        ]);
      });

      test('irq', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.irq;
        expect(labels(), [
          'r0',
          'r1',
          'r2',
          'r3',
          'r4',
          'r5',
          'r6',
          'r7',
          'r8',
          'r9',
          'r10',
          'r11',
          'r12',
          'r13_irq',
          'r14_irq',
          'PC'
        ]);
      });

      test('und', () {
        registers.cpsr.mode = Arm7TdmiProcessorMode.und;
        expect(labels(), [
          'r0',
          'r1',
          'r2',
          'r3',
          'r4',
          'r5',
          'r6',
          'r7',
          'r8',
          'r9',
          'r10',
          'r11',
          'r12',
          'r13_und',
          'r14_und',
          'PC'
        ]);
      });
    });
  });
}
