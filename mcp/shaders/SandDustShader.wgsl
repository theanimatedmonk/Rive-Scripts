// SandDustShader — animated sand / dust motes over a transparent layer.
// Fullscreen triangle (vertex_index 0..2), no vertex buffer.
//
// Bindings group 0:
//   0: UBO 80 bytes
//      time  — x seconds, y seed, z density 0-1, w grain size 0-1
//      drift — x wind angle rad, y speed, z turbulence 0-1, w aspect (w/h)
//      look  — x opacity 0-1, y softness 0-1, z bottom falloff 0-1, w sparkle 0-1
//      dust  — rgb grain color, a unused
//      hi    — rgb highlight, w haze 0-1
//
// Luau pack:
//    0  time, seed, density/100, grainSize/100
//   16  rad(windAngle), speed/100, turbulence/100, width/height
//   32  opacity/100, softness/100, falloff/100, sparkle/100
//   48  dustColor rgb, 1
//   64  highlight rgb, haze/100

struct UBO {
    time: vec4<f32>,
    drift: vec4<f32>,
    look: vec4<f32>,
    dust: vec4<f32>,
    hi: vec4<f32>,
}
@group(0) @binding(0) var<uniform> u: UBO;

struct VOut {
    @builtin(position) clip: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@vertex
fn vs_main(@builtin(vertex_index) vid: u32) -> VOut {
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(3.0, -1.0),
        vec2<f32>(-1.0, 3.0),
    );
    let p = pos[vid];
    var o: VOut;
    o.clip = vec4<f32>(p, 0.0, 1.0);
    o.uv = vec2<f32>(p.x * 0.5 + 0.5, 0.5 - p.y * 0.5);
    return o;
}

fn hash21(p: vec2<f32>) -> f32 {
    var p2 = fract(p * vec2<f32>(0.1031, 0.1030));
    let n = p2.x * (p2.y + 33.33);
    p2 = p2 + vec2<f32>(n, n);
    return fract((p2.x + p2.y) * p2.x);
}

fn hash22(p: vec2<f32>) -> vec2<f32> {
    let n = vec3<f32>(
        p.x,
        p.y,
        p.x + p.y,
    ) * vec3<f32>(0.1031, 0.1030, 0.0973);
    var p3 = fract(n);
    let k = p3.x + p3.y * 33.33 + p3.z;
    p3 = p3 + vec3<f32>(k, k, k);
    return fract((p3.xx + p3.yz) * p3.zy);
}

fn vnoise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let a = hash21(i);
    let b = hash21(i + vec2<f32>(1.0, 0.0));
    let c = hash21(i + vec2<f32>(0.0, 1.0));
    let d = hash21(i + vec2<f32>(1.0, 1.0));
    let u = f * f * (vec2<f32>(3.0, 3.0) - f * 2.0);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

fn grains(uv: vec2<f32>, grid: f32, t: f32, sizeMul: f32, seed: f32) -> vec2<f32> {
    let p = uv * grid;
    let id = floor(p);
    let f = fract(p);
    var spec = 0.0;
    var glow = 0.0;
    for (var iy: i32 = -1; iy <= 1; iy = iy + 1) {
        for (var ix: i32 = -1; ix <= 1; ix = ix + 1) {
            let off = vec2<f32>(f32(ix), f32(iy));
            let cell = id + off + vec2<f32>(seed, seed * 1.7);
            let rnd = hash22(cell);
            let life = hash21(cell + vec2<f32>(3.1, 7.9));
            let tw = sin(t * (1.2 + life * 2.4) + life * 6.2831855) * 0.5 + 0.5;
            let center = off + rnd;
            let d = length(f - center);
            let rad = mix(0.018, 0.085, life) * sizeMul;
            let g = 1.0 - smoothstep(0.0, rad, d);
            spec += g * g * (0.35 + 0.65 * life);
            glow += (1.0 - smoothstep(0.0, rad * 3.2, d)) * life * tw * 0.35;
        }
    }
    return vec2<f32>(spec, glow);
}

@fragment
fn fs_main(f: VOut) -> @location(0) vec4<f32> {
    let aspect = max(u.drift.w, 0.2);
    var uv = f.uv;
    uv.x = uv.x * aspect;

    let t = u.time.x;
    let seed = u.time.y;
    let dens = u.time.z;
    let gsz = mix(0.45, 2.2, u.time.w);
    let ang = u.drift.x;
    let spd = u.drift.y;
    let turb = u.drift.z;
    let opac = u.look.x;
    let soft = u.look.y;
    let fall = u.look.z;
    let spark = u.look.w;
    let hazeAmt = u.hi.w;

    let dir = vec2<f32>(cos(ang), sin(ang));
    let swirl = vec2<f32>(
        vnoise(uv * 2.4 + vec2<f32>(t * 0.11, seed)),
        vnoise(uv * 2.4 + vec2<f32>(seed + 4.0, t * 0.09)),
    );
    let wind = dir * t * spd * 0.55 + (swirl * 2.0 - vec2<f32>(1.0, 1.0)) * turb * 0.18;

    let uv1 = uv + wind;
    let uv2 = uv * 1.7 + wind * 0.55 + vec2<f32>(seed, 0.0);
    let uv3 = uv * 3.1 - wind * 0.28 + vec2<f32>(0.0, seed);

    let g1 = grains(uv1, mix(18.0, 42.0, dens), t, gsz, seed);
    let g2 = grains(uv2, mix(28.0, 64.0, dens), t * 1.3, gsz * 0.72, seed + 11.0);
    let g3 = grains(uv3, mix(46.0, 90.0, dens), t * 0.7, gsz * 0.5, seed + 23.0);

    let n1 = vnoise(uv1 * 6.0 + vec2<f32>(t * 0.07, 0.0));
    let n2 = vnoise(uv2 * 13.0 - vec2<f32>(0.0, t * 0.05));
    let haze = n1 * 0.65 + n2 * 0.35;
    let hazeSoft = smoothstep(0.35, 0.82, haze);

    let bot = mix(1.0, 1.0 - f.uv.y, fall);
    let veil = hazeSoft * hazeAmt * bot;
    let spec = (g1.x * 0.55 + g2.x * 0.35 + g3.x * 0.28) * dens * bot;
    let glow = (g1.y + g2.y * 0.7 + g3.y * 0.5) * spark * bot;

    let grain = mix(spec, smoothstep(0.0, mix(0.15, 1.2, soft), spec), 0.65);
    let rgb = u.dust.rgb * (veil * 0.55 + grain * 0.9) + u.hi.rgb * glow;
    let a = clamp((veil * 0.5 + grain * 0.85 + glow * 0.65) * opac, 0.0, 1.0);
    return vec4<f32>(rgb, a);
}
