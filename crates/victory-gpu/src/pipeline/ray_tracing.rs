//! Ray tracing off (`VICTORY_RAY_TRACING=0`; off by default):
//! the passes that walk the structures (BVH traversal) and that sort rays
//! into bins for them are left out when `VICTORY_RAY_TRACING=0` is set,
//! saving VRAM and frame time on GPUs like the RTX 4050 Laptop (6 GB).

use super::Shader;
use std::sync::OnceLock;
use victory_shader::{Container, FourCC};

/// What a pipeline does for ray tracing.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(super) enum Work {
    Traversal,
    RayBins,
    Other,
}

fn asked_off() -> bool {
    static OFF: OnceLock<bool> = OnceLock::new();
    *OFF.get_or_init(|| {
        let var = std::env::var("VICTORY_RAY_TRACING");
        let off = var.as_deref().is_ok_and(|v| v.trim() == "0");
        if off {
            tracing::info!("ray tracing off: BVH traversal and ray-bin passes left out");
        }
        off
    })
}

/// Whether the passes are left out now.
pub(super) fn off_now() -> bool {
    asked_off()
}

/// Why a pipeline of `shaders` is left out while ray tracing is off.
pub(super) fn omission(shaders: &[std::sync::Arc<Shader>]) -> Option<&'static str> {
    if !off_now() {
        return None;
    }
    shaders.iter().find_map(|s| match classify(s.stage, &s.container) {
        Work::Traversal => Some("ray tracing off: BVH traversal"),
        Work::RayBins => Some("ray tracing off: ray bin preparation"),
        Work::Other => None,
    })
}

const RAY_BIN_ENTRIES: [&[u8]; 5] = [
    b"CS_ScreenProbes_EvaluateRayRequests_RayBinning_",
    b"CS_RayBudgeting_Cull_RayBinning_",
    b"CS_ScreenProbes_GenerateRayBins_",
    b"CS_GenerateRayBins_",
    b"CS_GenerateRayBinOffsets_",
];

fn classify(stage: &str, container: &[u8]) -> Work {
    let Ok(c) = Container::parse(container) else {
        return Work::Other;
    };
    if stage == "compute"
        && c.part(FourCC::PSV0).is_some_and(|psv| {
            psv.data
                .split(|b| *b == 0)
                .any(|entry| RAY_BIN_ENTRIES.iter().any(|name| entry.starts_with(name)))
        })
    {
        return Work::RayBins;
    }
    let Some(programs) = c
        .part(FourCC::DXIL)
        .and_then(|p| victory_shader::native_programs(p.data).ok())
    else {
        return Work::Other;
    };
    if programs.iter().any(|p| traverses(&p.code)) {
        return Work::Traversal;
    }
    Work::Other
}

fn traverses(code: &[u8]) -> bool {
    code.chunks_exact(4).any(|bytes| {
        let word = u32::from_le_bytes(bytes.try_into().unwrap());
        word >> 26 == 0x3c && (word >> 18) & 0x7e == 0x66 && word & 1 != 0
    }) && victory_shader::gfx10::decode(code).is_ok_and(|instructions| {
        instructions
            .iter()
            .any(|i| matches!(i.name(), Some("image_bvh_intersect_ray" | "image_bvh64_intersect_ray")))
    })
}
