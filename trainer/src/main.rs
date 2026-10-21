//! PROVISIONAL toy-grid MLP training smoke (Atrapa task 6.1).
//!
//! The environment here is NOT Atrapa's gameplay. Rules review (tasks 1.2/1.3)
//! is open and the shared headless transition (task 2.1) does not exist yet,
//! so this crate uses a deliberately unrelated toy task: on an N x N grid, a
//! scripted teacher picks the move (up/right/down/left) that reduces the
//! Manhattan distance from an agent cell to a target cell (ties: larger axis
//! gap first, then the lower action index). A small MLP imitates the teacher.
//! The point is to prove a real gradient-update lane, device selection,
//! export, and a reference forward pass for later Dart/WASM parity.
use candle_core::{DType, Device, Module, Tensor, D};
use candle_nn::{linear, loss, Linear, Optimizer, VarBuilder, VarMap};
use sha2::{Digest, Sha256};
use std::time::Instant;

const GRID: usize = 8;
const IN: usize = 2 * GRID * GRID; // one-hot agent cell + one-hot target cell
const HIDDEN: usize = 64;
const OUT: usize = 4; // 0 up, 1 right, 2 down, 3 left (PROVISIONAL toy meaning)

/// Tiny deterministic PRNG (SplitMix64) so the dataset is seed-reproducible.
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
        z ^ (z >> 31)
    }
    fn below(&mut self, n: usize) -> usize {
        (self.next() % n as u64) as usize
    }
}

/// Toy teacher: returns None when agent == target.
fn teacher(a: (usize, usize), t: (usize, usize)) -> Option<u32> {
    let dx = t.0 as i64 - a.0 as i64;
    let dy = t.1 as i64 - a.1 as i64;
    if dx == 0 && dy == 0 {
        return None;
    }
    Some(if dx.abs() >= dy.abs() {
        if dx > 0 { 1 } else { 3 }
    } else if dy > 0 {
        2
    } else {
        0
    })
}

fn encode(a: (usize, usize), t: (usize, usize)) -> Vec<f32> {
    let mut v = vec![0f32; IN];
    v[a.1 * GRID + a.0] = 1.0;
    v[GRID * GRID + t.1 * GRID + t.0] = 1.0;
    v
}

fn dataset(rng: &mut Rng, n: usize) -> (Vec<f32>, Vec<u32>) {
    let (mut xs, mut ys) = (Vec::with_capacity(n * IN), Vec::with_capacity(n));
    while ys.len() < n {
        let a = (rng.below(GRID), rng.below(GRID));
        let t = (rng.below(GRID), rng.below(GRID));
        if let Some(y) = teacher(a, t) {
            xs.extend(encode(a, t));
            ys.push(y);
        }
    }
    (xs, ys)
}

struct Mlp {
    l1: Linear,
    l2: Linear,
}
impl Module for Mlp {
    fn forward(&self, x: &Tensor) -> candle_core::Result<Tensor> {
        self.l2.forward(&self.l1.forward(x)?.relu()?)
    }
}

/// Reference forward pass in plain f32 Rust over the exported flat layout.
/// This is the arithmetic a Dart/WASM evaluator must reproduce.
fn reference_forward(w: &[f32], x: &[f32]) -> [f32; OUT] {
    let (w1, rest) = w.split_at(HIDDEN * IN);
    let (b1, rest) = rest.split_at(HIDDEN);
    let (w2, b2) = rest.split_at(OUT * HIDDEN);
    let mut h = [0f32; HIDDEN];
    for j in 0..HIDDEN {
        let mut s = b1[j];
        for i in 0..IN {
            s += w1[j * IN + i] * x[i];
        }
        h[j] = s.max(0.0);
    }
    let mut o = [0f32; OUT];
    for k in 0..OUT {
        let mut s = b2[k];
        for j in 0..HIDDEN {
            s += w2[k * HIDDEN + j] * h[j];
        }
        o[k] = s;
    }
    o
}

fn argmax(v: &[f32]) -> usize {
    let mut b = 0;
    for i in 1..v.len() {
        if v[i] > v[b] {
            b = i;
        }
    }
    b
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    let get = |k: &str, d: &str| -> String {
        args.iter().position(|a| a == k).and_then(|i| args.get(i + 1)).cloned().unwrap_or(d.into())
    };
    let want = get("--device", "cpu");
    let out_dir = get("--out", "target/train-smoke/out");
    let steps: usize = get("--steps", "2000").parse()?;
    let batch: usize = get("--batch", "4096").parse()?;
    let seed: u64 = get("--seed", "42").parse()?;

    let device = match want.as_str() {
        "cuda" => Device::new_cuda(0)?,
        "cpu" => Device::Cpu,
        o => return Err(format!("unknown --device {o}").into()),
    };
    let device_desc = match &device {
        Device::Cpu => "cpu".to_string(),
        Device::Cuda(_) => "cuda:0".to_string(),
        _ => "other".to_string(),
    };
    eprintln!("device_requested={want} device_used={device_desc}");

    let mut rng = Rng(seed);
    let (vx, vy) = dataset(&mut Rng(seed ^ 0xA5A5), 2048); // held-out eval corpus
    let vx_t = Tensor::from_vec(vx.clone(), (vy.len(), IN), &device)?;

    let varmap = VarMap::new();
    let vb = VarBuilder::from_varmap(&varmap, DType::F32, &device);
    let model = Mlp { l1: linear(IN, HIDDEN, vb.pp("l1"))?, l2: linear(HIDDEN, OUT, vb.pp("l2"))? };
    let mut opt = candle_nn::AdamW::new_lr(varmap.all_vars(), 3e-3)?;

    let acc = |m: &Mlp| -> candle_core::Result<f32> {
        let p = m.forward(&vx_t)?.argmax(D::Minus1)?.to_vec1::<u32>()?;
        Ok(p.iter().zip(&vy).filter(|(a, b)| a == b).count() as f32 / vy.len() as f32)
    };
    let acc0 = acc(&model)?;

    // Pre-generate host batches so timing measures the device training loop.
    let batches: Vec<(Vec<f32>, Vec<u32>)> = (0..16).map(|_| dataset(&mut rng, batch)).collect();
    let mut first_loss = f32::NAN;
    let mut last_loss = f32::NAN;
    let t0 = Instant::now();
    for s in 0..steps {
        let (x, y) = &batches[s % batches.len()];
        let xt = Tensor::from_slice(x, (batch, IN), &device)?;
        let yt = Tensor::from_slice(y, batch, &device)?;
        let l = loss::cross_entropy(&model.forward(&xt)?, &yt)?;
        opt.backward_step(&l)?;
        if s == 0 || s + 1 == steps || s % 500 == 0 {
            let lv = l.to_scalar::<f32>()?;
            if s == 0 { first_loss = lv; }
            last_loss = lv;
            eprintln!("step {s} loss {lv:.4}");
        }
    }
    let _ = model.forward(&vx_t)?.sum_all()?.to_scalar::<f32>()?; // sync device
    let wall = t0.elapsed().as_secs_f64();
    let acc1 = acc(&model)?;
    let samples_per_s = (steps * batch) as f64 / wall;

    // Export: flat little-endian f32 [W1 (HIDDEN x IN, row-major) | b1 | W2 (OUT x HIDDEN) | b2]
    let flat_of = |t: &Tensor| -> candle_core::Result<Vec<f32>> { t.flatten_all()?.to_vec1::<f32>() };
    let data = varmap.data().lock().unwrap();
    let mut flat = Vec::new();
    for k in ["l1.weight", "l1.bias", "l2.weight", "l2.bias"] {
        flat.extend(flat_of(data.get(k).ok_or(k)?.as_tensor())?);
    }
    drop(data);
    let bytes: Vec<u8> = flat.iter().flat_map(|f| f.to_le_bytes()).collect();
    let hash = format!("{:x}", Sha256::digest(&bytes));

    // Parity: reference forward over the eval corpus vs the candle model.
    let cand = model.forward(&vx_t)?.to_device(&Device::Cpu)?.to_vec2::<f32>()?;
    let (mut max_abs, mut agree) = (0f32, 0usize);
    for (i, row) in cand.iter().enumerate() {
        let r = reference_forward(&flat, &vx[i * IN..(i + 1) * IN]);
        for k in 0..OUT {
            max_abs = max_abs.max((r[k] - row[k]).abs());
        }
        agree += (argmax(&r) == argmax(row)) as usize;
    }
    let tol = 1e-4f32;
    let parity_ok = max_abs <= tol && agree == cand.len();

    // A small fixed fixture corpus with reference logits for Dart/WASM tests.
    let fixtures: Vec<serde_json::Value> = [((0, 0), (7, 7)), ((3, 4), (3, 0)), ((5, 5), (1, 5)), ((2, 6), (2, 7))]
        .iter()
        .map(|&(a, t)| {
            let lg = reference_forward(&flat, &encode(a, t));
            serde_json::json!({"agent": [a.0, a.1], "target": [t.0, t.1], "logits": lg, "action": argmax(&lg)})
        })
        .collect();

    std::fs::create_dir_all(&out_dir)?;
    std::fs::write(format!("{out_dir}/weights.f32"), &bytes)?;
    let manifest = serde_json::json!({
        "schema": "atrapa-policy-smoke/0",
        "provisional": true,
        "provisional_reason": "toy grid task; Atrapa rules review (tasks 1.2/1.3) open; no shared headless transition yet (2.1)",
        "task": "imitate toy teacher: move reducing Manhattan distance agent->target on 8x8 grid",
        "architecture": {"type": "mlp", "layers": [IN, HIDDEN, OUT], "activation": "relu", "output": "logits"},
        "observation": {"size": IN, "encoding": "one-hot agent cell (y*8+x) then one-hot target cell (64 + y*8+x)"},
        "actions": ["up", "right", "down", "left"],
        "weights": {"file": "weights.f32", "dtype": "f32", "endian": "little",
            "layout": [["l1.weight", [HIDDEN, IN]], ["l1.bias", [HIDDEN]], ["l2.weight", [OUT, HIDDEN]], ["l2.bias", [OUT]]],
            "row_major": true, "param_count": flat.len(), "bytes": bytes.len(), "sha256": hash},
        "training": {"device": device_desc, "seed": seed, "steps": steps, "batch": batch, "optimizer": "AdamW lr=3e-3",
            "first_loss": first_loss, "last_loss": last_loss, "eval_acc_before": acc0, "eval_acc_after": acc1,
            "wall_s": wall, "samples_per_s": samples_per_s},
        "parity": {"reference": "trainer/src/main.rs reference_forward", "corpus": vy.len(), "max_abs_diff": max_abs,
            "tolerance": tol, "action_agreement": agree as f64 / cand.len() as f64, "ok": parity_ok},
        "fixtures": fixtures,
    });
    std::fs::write(format!("{out_dir}/manifest.json"), serde_json::to_string_pretty(&manifest)?)?;
    println!("RESULT device={device_desc} steps={steps} batch={batch} wall_s={wall:.3} samples_per_s={samples_per_s:.0} loss={first_loss:.4}->{last_loss:.4} acc={acc0:.3}->{acc1:.3} params={} sha256={hash} parity_max_abs={max_abs:.2e} parity_ok={parity_ok}", flat.len());
    if !parity_ok {
        return Err("parity check failed".into());
    }
    Ok(())
}
