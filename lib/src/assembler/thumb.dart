import 'dart:convert';

import 'package:binary/binary.dart';

/// ...
class ThumbInstruct {}

/// Decodes `THUMB` 16-bit instructions [Uint16] into [ThumbInstruct].
///
/// > NOTE: This decoder is prioritized around _correctness_, _range checks_,
/// and in general making the code easy to read and debug (over performance). We
/// may want a _faster_ decoder for conventional use.
class ThumbDecoder extends Converter<Uint16, ThumbInstruct> {
  @override
  ThumbInstruct convert(Uint16 input) {
    return ThumbInstruct();
  }
}
