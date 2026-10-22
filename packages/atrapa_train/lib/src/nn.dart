import 'dart:math' as math;
import 'dart:typed_data';

import 'mlp.dart';

/// Trainable twin of [Mlp] (same parameter layout). Weighted softmax
/// cross-entropy: weight 1 = imitation, weight = advantage = REINFORCE.
class Trainer {
  final List<int> sizes;
  final Float32List params;
  final Float32List grad;
  final Float32List m, v;
  int t = 0;
  late final List<Float32List> acts = [for (final n in sizes) Float32List(n)];
  late final List<Float32List> deltas = [for (final n in sizes) Float32List(n)];

  Trainer(this.sizes, this.params)
      : grad = Float32List(params.length),
        m = Float32List(params.length),
        v = Float32List(params.length);

  void _forward(Float32List x) {
    acts[0].setAll(0, x);
    var off = 0;
    for (var l = 0; l + 1 < sizes.length; l++) {
      final nin = sizes[l], nout = sizes[l + 1];
      final a = acts[l], z = acts[l + 1];
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
  }

  /// Accumulate the gradient of w * CE(softmax(f(x)), label) - beta * H.
  /// Returns the unweighted CE loss and whether argmax == label.
  (double, bool) accumulate(Float32List x, int label, double w,
      {double entropyBeta = 0}) {
    _forward(x);
    final L = sizes.length - 1;
    final y = acts[L];
    var mx = y[0];
    for (var i = 1; i < y.length; i++) {
      if (y[i] > mx) mx = y[i];
    }
    var sum = 0.0;
    final p = Float64List(y.length);
    for (var i = 0; i < y.length; i++) {
      p[i] = math.exp(y[i] - mx);
      sum += p[i];
    }
    var argmax = 0;
    var ent = 0.0;
    for (var i = 0; i < y.length; i++) {
      p[i] /= sum;
      if (p[i] > p[argmax]) argmax = i;
      if (p[i] > 0) ent -= p[i] * math.log(p[i]);
    }
    final d = deltas[L];
    for (var i = 0; i < y.length; i++) {
      var g = w * (p[i] - (i == label ? 1 : 0));
      if (entropyBeta != 0 && p[i] > 0) {
        // d(-H)/dz_i = p_i * (log p_i + H)
        g += entropyBeta * p[i] * (math.log(p[i]) + ent);
      }
      d[i] = g;
    }
    // Backward.
    var off = params.length;
    for (var l = L - 1; l >= 0; l--) {
      final nin = sizes[l], nout = sizes[l + 1];
      off -= nin * nout + nout;
      final bOff = off + nin * nout;
      final a = acts[l], dz = deltas[l + 1], da = deltas[l];
      for (var o = 0; o < nout; o++) {
        final g = dz[o];
        if (g == 0) continue;
        grad[bOff + o] += g;
        final row = off + o * nin;
        for (var i = 0; i < nin; i++) {
          grad[row + i] += g * a[i];
        }
      }
      if (l > 0) {
        for (var i = 0; i < nin; i++) {
          if (a[i] <= 0) {
            da[i] = 0;
            continue;
          }
          var s = 0.0;
          for (var o = 0; o < nout; o++) {
            s += params[off + o * nin + i] * dz[o];
          }
          da[i] = s;
        }
      }
    }
    return (-math.log(p[label] + 1e-12), argmax == label);
  }

  /// AdamW step with the accumulated gradient divided by [batch]; clears it.
  void adam(int batch, double lr,
      {double b1 = 0.9, double b2 = 0.999, double wd = 1e-4, double clip = 1.0}) {
    t++;
    final inv = 1.0 / batch;
    var norm = 0.0;
    for (var i = 0; i < grad.length; i++) {
      norm += (grad[i] * inv) * (grad[i] * inv);
    }
    norm = math.sqrt(norm);
    final scale = norm > clip ? inv * clip / norm : inv;
    final c1 = 1 - math.pow(b1, t), c2 = 1 - math.pow(b2, t);
    for (var i = 0; i < params.length; i++) {
      final g = grad[i] * scale;
      m[i] = b1 * m[i] + (1 - b1) * g;
      v[i] = b2 * v[i] + (1 - b2) * g * g;
      params[i] -= lr * ((m[i] / c1) / (math.sqrt(v[i] / c2) + 1e-8) + wd * params[i]);
      grad[i] = 0;
    }
  }
}
