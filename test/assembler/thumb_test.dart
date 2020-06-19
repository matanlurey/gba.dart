import 'package:binary/binary.dart';
import 'package:gba/src/assembler/thumb.dart';
import 'package:test/test.dart';

void main() {
  group('Mask values should be computed', () {
    for (final format in ThumbBinaryOpcodeFormat.values) {
      test('${format.toString().split('.')[1]}', () {
        expect(
          ThumbBinaryOpcodeFormatX.match(format.mask.asUint32()),
          format,
          reason: 'Mask should be unique enough to match',
        );
      });
    }
  });
}
