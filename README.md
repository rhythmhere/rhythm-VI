# Rhythm-VI — Xbox Series Compatibility Layer for Windows (RTX 4050 / 16 GB RAM Tuned)

**Rhythm-VI** is a Windows compatibility layer for running Xbox Series titles natively on PC from user-supplied game files, built by combining [VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD) (Renderer Ports #1, #2, #5, #6, #7 + Residency) and [ScarlettPort](https://github.com/ZigZagBoi1/ScarlettPort) (`FastBoot`, `SkipCutscenes`, `LoadUnpaced`, `PressFile`, `RayTracing=0`), plus **Rhythm-VI** optimizations for **NVIDIA Ada Lovelace (6 GB VRAM)** and **16 GB system RAM**.

> **This repository contains no game files, code, or assets.** You must supply your own legal dump of the title. This project is not affiliated with or endorsed by any game developer or publisher.

---

## What Rhythm-VI Adds

- **NVIDIA ROV Serialization Bypass (`VICTORY_NO_ROVS=1`):** Strips `D3D_SHADER_REQUIRES_ROVS` (`0x2000`) on UAVs inside ordered pixel-shader sections in `victory-shader`, preventing pixel-wave stalls on Ada Lovelace GPUs.
- **Wide Shader Loads (`VICTORY_SHADER_OPT=127`):** Enables 4-dword `WIDE` bitcode optimization passes by default.
- **256-Byte In-Place CBV Fast Path (`VICTORY_PORT_CBV_256=1`):** Binds 256-byte-aligned constant buffers directly from `PORT_CONSTANTS` memory without CPU `scratch_held` allocation or `defer_constants` copies (critical on NVIDIA where `1,000,000`-slot Tier 2 heaps disable `raw_twins`).
- **16 GB RAM Commit Caps:** Caps `STAGING` spare blocks (`128 MiB`), `IDLE_MOST` command lists (`128 / 64 MiB`), and snapshot pool retention (`64 MiB`) when `limited_host_ram()` is active, keeping private commit around `13.1–14.0 GB` instead of `19.2 GB`.
- **ScarlettPort QoL & FastBoot:** `VICTORY_FAST_BOOT=1`, `VICTORY_SKIP_CUTSCENES=1`, `VICTORY_LOAD_UNPACED=1`, `VICTORY_RAY_TRACING=0`, and live input injection via `VICTORY_PRESS_FILE` (`press.txt`).
- **720p Low-to-Medium Default Profile:** `scripts/play-rhythm-vi.ps1` defaults to `release` build, `1280x720` output, `VICTORY_UPSCALER=6`, and `VICTORY_RENDER_SCALE=0.5` (`640x360` internal).

---

## Requirements

- Windows 10 / 11 x64
- CPU with AVX2
- Direct3D 12 GPU with Shader Model 6.6 & Mesh Shaders (tuned for NVIDIA RTX 4050 Laptop 6 GB VRAM)
- Rust toolchain (pinned by `rust-toolchain.toml`) + MSVC C++ Build Tools
- Your own unpacked title files

---

## Quick Start

```powershell
# 1. Copy example config and set paths to your game dump (keep game files outside this repo)
copy victory.example.toml victory.toml

# 2. Build the release binary
cargo build --locked --release -p victory

# 3. (Recommended once per shader/driver update) Pre-warm the shader cache
$env:VICTORY_D3D12_ADAPTER='NVIDIA'
$env:VICTORY_NO_ROVS='1'
$env:VICTORY_SHADER_OPT='127'
.\target\release\victory.exe shaders <path-to-shaders.rpf>

# 4. Launch Rhythm-VI (720p, 0.5 render scale, FastBoot optional)
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\play-rhythm-vi.ps1 -Exe <path-to-game_scarlett_master.exe> -FastBoot
```

### Launcher Options (`scripts/play-rhythm-vi.ps1`)
| Parameter | Default | Description |
|---|---|---|
| `-Exe` | `c:\CHANCHALE\GAMERUN\game_scarlett_master.exe` | Path to the title executable |
| `-Build` | `release` | `release` or `diag` (`diag` requires `--features diagnostics` for full span logs) |
| `-Output` | `1280x720` | Output resolution (`1280x720` uses `VICTORY_UPSCALER=6`) |
| `-FastBoot` | Off | Skip intro logos/cutscenes and auto-advance boot prompts |
| `-RayTracing` | Off | Enable BVH builder & ray tracing (`VICTORY_RAY_TRACING=1`) |
| `-FrameIntervalMs` | `33.333` | Frame cap (`33.333` = 30 FPS, `16.667` = 60 FPS) |
| `-More` | `@{}` | Hashtable of extra `VICTORY_*` environment overrides |

---

## Key Environment Switches

| Switch | Default in Launcher | Purpose |
|---|---|---|
| `VICTORY_NO_ROVS` | `1` | Suppresses `ROVS` pixel-wave serialization on NVIDIA |
| `VICTORY_SHADER_OPT` | `127` | Enables all bitcode passes including 4-dword `WIDE` loads |
| `VICTORY_PORT_CBV_256` | `1` | Binds 256-byte-aligned `PORT_CONSTANTS` CBVs in place |
| `VICTORY_RENDER_SCALE` | `0.5` | Internal render scale (`0.5`–`1.0`) |
| `VICTORY_UPSCALER` | `6` | `6` = title upscaler (required for 720p), `7` = FidelityFX |
| `VICTORY_RESIDENCY_LIMITED` | `1` | Tighter upload/staging budgets for 16 GB RAM |
| `VICTORY_KBM_GTA` | `1` | GTA-style keyboard & mouse mapping (`F2` / `` ` `` toggles mouse-look) |

---

## Observed Performance (RTX 4050 Laptop 6 GB + Ryzen 7 7435HS + 16 GB RAM)

- **Menus / Opening / Post-Load World:** `24.3 – 36.5 FPS` (`27.4 – 41.1 ms/frame`).
- **Heavy Prison Scene (~4,695 draws/frame):** `2.3 – 4.8 FPS` (`208.9 – 443.5 ms/frame`), limited by NVIDIA's `1,000,000`-slot D3D12 Tier 2 descriptor heap ceiling (`raw_twins=false`, disabling `VICTORY_PORT_CBV=1` for non-256-byte CBVs and keeping ~24k dynamic raw views/frame CPU-bound).

---

## Credits & License

Built on [VIctory](https://github.com/Marvisak/VIctory), [VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD), and [ScarlettPort](https://github.com/ZigZagBoi1/ScarlettPort). Licensed under **GPL-3.0-or-later** — see [LICENSE](LICENSE).
