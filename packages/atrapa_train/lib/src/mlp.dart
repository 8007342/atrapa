import 'dart:math' as math;
import 'dart:typed_data';

/// Dense ReLU MLP evaluator. Weight layout (shared with trainer/ and the
/// policy bundles): for each layer, weight[out][in] row-major then
/// bias[out], little-endian float32, concatenated. ReLU after every layer
/// except the last (raw logits).
class Mlp {
  final List<int> sizes;
  final Float32List params;
  late final List<Float32List> _acts =
      [for (final n in sizes) Float32List(n)];

  Mlp(this.sizes, this.params) {
    if (params.length != paramCount(sizes)) {
      throw ArgumentError(
          'expected ${paramCount(sizes)} params, got ${params.length}');
    }
  }

  static int paramCount(List<int> sizes) {
    var n = 0;
    for (var l = 0; l + 1 < sizes.length; l++) {
      n += sizes[l] * sizes[l + 1] + sizes[l + 1];
    }
    return n;
  }

  /// Logits for input [x]. The returned list is reused by the next call.
  Float32List forward(Float32List x) {
    _acts[0].setAll(0, x);
    var off = 0;
    for (var l = 0; l + 1 < sizes.length; l++) {
      final nin = sizes[l], nout = sizes[l + 1];
      final a = _acts[l], z = _acts[l + 1];
      final bOff = off + nin * nout;
      final last = l + 2 == sizes.length;
      for (var o = 0; o < nout; o++) {
        var acc = params[bOff + o];
        final row = off + o * nin;
        for (var i = 0; i < nin; i++) {
          acc += params[row + i] * a[i];
        }
        z[o] = (last || acc > 0) ? acc : 0;
      }
      off = bOff + nout;
    }
    return _acts.last;
  }

  int argmax(Float32List x) {
    final y = forward(x);
    var b = 0;
    for (var i = 1; i < y.length; i++) {
      if (y[i] > y[b]) b = i;
    }
    return b;
  }

  static Float32List decode(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    final out = Float32List(bytes.lengthInBytes ~/ 4);
    for (var i = 0; i < out.length; i++) {
      out[i] = bd.getFloat32(i * 4, Endian.little);
    }
    return out;
  }

  Uint8List encode() {
    final bd = ByteData(params.length * 4);
    for (var i = 0; i < params.length; i++) {
      bd.setFloat32(i * 4, params[i], Endian.little);
    }
    return bd.buffer.asUint8List();
  }

  /// He-uniform initialisation (deterministic for a given [rand]).
  static Mlp init(List<int> sizes, math.Random rand) {
    final p = Float32List(paramCount(sizes));
    var off = 0;
    for (var l = 0; l + 1 < sizes.length; l++) {
      final lim = math.sqrt(6.0 / sizes[l]);
      for (var k = 0; k < sizes[l] * sizes[l + 1]; k++) {
        p[off + k] = (rand.nextDouble() * 2 - 1) * lim;
      }
      off += sizes[l] * sizes[l + 1] + sizes[l + 1];
    }
    return Mlp(sizes, p);
  }
}

