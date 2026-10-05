# TetCage

Tetrahedral-cage deformation of animated meshes, measured end to end: a CPU
reference oracle, CUDA kernels, a Vulkan compute and render-pass port checked
against that oracle, and the scene-packet seam that brings it into the WGE
game engine, whose renderer is Lava (Julia → SPIR-V → Vulkan).

It starts from AMD's HPG 2026 paper, Gruen, Benthin, Kern and McAllister,
*Ray Tracing Massive Amounts of Animated Geometry* (DOI
[10.1145/3820014](https://doi.org/10.1145/3820014)). The paper's tetrahedral
cage carries animation for ray tracing. This work measures the narrower facet
that ships first on a raster engine: **parametric cage deformation**, where a
shared, cache-resident cage drives many instances at zero bytes of per-frame
upload. The paper's GPU ray-tracing representation is not built here; its
CPU groundwork is (Spiral C: clipping
[watertightness](docs/tetcage-watertightness.md) and a deterministic
[ray census](docs/tetcage-cpu-ray-census.md) against the clipped per-tet
soups).

Everything was run on one machine (RTX 5060, NVIDIA 615.71.9, Vulkan 1.4.351,
Julia 1.12.6). Every number below traces to a CSV in `results/` whose SHA-256
is pinned in the doc that reports it. Deterministic columns reproduce
byte-identically across fresh processes; wall-time columns are machine state,
and the reports say where their ordering is not stable between runs.

## Results

| Finding | Number | Evidence |
|---|---|---|
| GPU kernel vs CPU f32 oracle | bit-identical | [Spiral E](docs/tetcage-gpu-spiral-e.md) |
| Real Vulkan render chain vs the analytic screen model | max 8.4e-5 px (about 1 ulp of framebuffer coordinates; gate 0.5 px) | [Spiral G](docs/tetcage-vulkan-parity.md) |
| Fusing deform + reconstruct into one kernel, then graph submission | 28.5 → 16.2 → 9.9 µs per frame (blob, wind); 2.9× headroom | [Spiral H](docs/tetcage-fusion-headroom.md) |
| Shared parametric cage (0 B/frame) vs uploading cage state (48·T·N B/frame) | parametric wins 28/28 (class, instance-count) cells, N = 1 to 128 | [Goal 2 report](docs/tetcage-goal2-final.md) |
| Deformation error vs cage resolution | rms ∝ h² on curved classes; wind plateaus to about h¹ on flat ones | [Spiral D](docs/tetcage-fidelity-frontier.md) |

And what beats it, measured, not assumed: **deforming resident vertices
directly needs no cage at all**, and wins wall time in 26 of 28 cells on
affine motion. The shared cage overtakes direct deformation only at the
vertex-dense × many-instance corner (10,242 vertices × 128 instances). See
section 2 of the [Goal 2 report](docs/tetcage-goal2-final.md) for the full
envelope, and the [failure register](docs/tetcage-rt-failure-register.md) for
every defect found on the way, including the ones that were ours.

## Layout

| Path | What |
|---|---|
| `oracle/` | CPU reference: cage build (`TetCage.jl`), barycentric basis, deformation fields, mesh IO, and the Spiral C–D drivers |
| `gpu/` | CUDA.jl kernels and the Spiral E, F, H, I drivers (the numeric oracle and economics lab) |
| `vk/` | Vulkan.jl render-pass readback (Spiral G) and the Vulkan compute parity port (P0) |
| `corpus/` | The 10 test meshes and their manifest |
| `results/` | Pinned evidence CSVs |
| `logs/` | Run CSVs kept as evidence (raw `.log` files stay local) |
| `docs/` | Spiral reports, the ledger, the failure register, the integration contract |
| `tetcage_weight_model.jl` | Spiral 1's deterministic memory model of the paper's representation |
| `integration/wge/` | The WGE side: scene packet v7 deformation contract, its tests, and the seam design |
| `vendor/lava/` | Lava (MIT, Simon Danisch) as WGE vendors it, with WGE's two additive patches |
| `references/` | The paper pin (citation, URL, SHA-256) |
| `tools/fetch-paper.sh` | Downloads the paper, verifies its hash, extracts `references/paper.txt` |

## Reproducing

- `julia tetcage_weight_model.jl` from the repo root needs only Julia's
  standard library and rewrites `results/weight-model-sweep.csv`
  byte-identically.
- `oracle/` drivers run on the CPU. `gpu/` needs an NVIDIA GPU with CUDA.jl
  (`gpu/Project.toml`, `gpu/Manifest.toml`). `vk/` needs a Vulkan device
  (`vk/Project.toml` pins Vulkan.jl and VulkanCore.jl to exact upstream
  commits).
- Each report names its driver script, the CSV it writes, and that CSV's hash.
- Several docs cite line ranges of the paper's text. Run
  `tools/fetch-paper.sh` to fetch the authors' version from AMD GPUOpen, check it
  against `references/paper.sha256` and extract `references/paper.txt`. The
  paper is AMD's and is not redistributed here.

## How it reaches the engine

Shipping CUDA in a game was ruled out, so the product path is Vulkan compute.
In WGE terms: the Rust kernel owns identity, policy and evidence, and Julia
with Lava executes. P0 ported the fused kernel to Vulkan compute and matched
the oracle (all gates passed). P1 added an optional `deformation` section to
WGE's scene packet (v7), behind a flag, and is the code in
`integration/wge/`. P2, the in-engine instancing ladder, is next. The
[seam design](integration/wge/tetcage-seam-design.md) has the sequence, gates
and honesty ledger. `integration/wge/` is an excerpt of the WGE crate and does
not build on its own.

## History

This began as a research lane inside WGE (`graphics_lab/tet-lab`), and the
reports keep that wording and those paths as they were written. The work was
done under a written spiral method ([`docs/rpd-sop.md`](docs/rpd-sop.md)): pre-registered predictions and
falsification conditions, pinned evidence, and a failure register that
records amendments rather than hiding them.
