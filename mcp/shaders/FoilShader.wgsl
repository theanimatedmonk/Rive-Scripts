// FoilShader — reusable holographic foil overlay.
// Screen-blends rainbow stripes onto a source texture. The bands travel with
// a fake UV bulge (and an optional extra tilt) so the look matches Card3D /
// Sphere3D without needing a 3D mesh.
//
// Bindings group 0:
//   0: UBO 64 bytes
//      foil      — x intensity 0-1, y stripe count, z tilt shift 0-1, w angle rad
//      light     — x angle rad (drives fresnel / spec mask)
//      params    — x curvature (0.55 like the card), y extra tilt, zw unused
//      pad
//   1: source texture
//   2: sampler
//
// Draw a fullscreen triangle (vertex_index 0..2), no vertex buffer.
//
// Luau pack (64 bytes):
//   0  foilIntensity/100, foilStripes, foilShift/100, rad(foilAngle)
//  16  rad(lightAngle), 0, 0, 0
//  32  0.55, extraTilt, 0, 0
//  48  0, 0, 0, 0

struct UBO {
    foil: vec4<f32>,
    light: vec4<f32>,
    params: vec4<f32>,
    pad: vec4<f32>,
}
@group(0) @binding(0) var<uniform> u: UBO;
@group(0) @binding(1) var tSrc: texture_2d<f32>;
@group(0) @binding(2) var tSamp: sampler;

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

@fragment
fn fs_main(f: VOut) -> @location(0) vec4<f32> {
    let albedo = textureSample(tSrc, tSamp, f.uv);

    let uvC = f.uv * 2.0 - 1.0;
    let curve = u.params.x;
    let nLocal = normalize(vec3<f32>(uvC.x * curve, uvC.y * curve, 1.0));

    let angle = u.light.x;
    let L = normalize(vec3<f32>(sin(angle), 0.42, cos(angle)));
    let V = vec3<f32>(0.0, 0.0, 1.0);
    let H = normalize(L + V);
    let ndh = max(dot(nLocal, H), 0.0);
    let ndv = max(dot(nLocal, V), 0.0);
    let specTerm = pow(clamp(ndh, 0.0001, 1.0), 40.0);
    let fres = pow(clamp(1.0 - ndv, 0.0, 1.0), 2.0);

    let foilI = u.foil.x;
    let stripes = max(u.foil.y, 0.25);
    let shiftAmt = u.foil.z;
    let foilAng = u.foil.w;
    let ca = cos(foilAng);
    let sa = sin(foilAng);
    let uvcX = f.uv.x - 0.5;
    let uvcY = f.uv.y - 0.5;
    let stripeUv = uvcX * ca + uvcY * sa + 0.5;
    let perp = uvcX * (0.0 - sa) + uvcY * ca;
    let wave = sin(perp * 8.0) * 0.08;
    let tilt = nLocal.x * 0.9 + nLocal.y * 0.28 + u.params.y;
    let phase = (stripeUv + wave + tilt * shiftAmt) * stripes * 6.2831855;
    let hr = 0.5 + 0.5 * sin(phase);
    let hg = 0.5 + 0.5 * sin(phase + 2.094395);
    let hb = 0.5 + 0.5 * sin(phase + 4.18879);
    let foilMask = 0.42 + 0.58 * fres + 0.32 * specTerm;
    let foilLit = vec3<f32>(hr, hg, hb) * foilI * foilMask;
    let invA = vec3<f32>(1.0) - albedo.rgb;
    let invF = vec3<f32>(1.0) - foilLit;
    let rgb = vec3<f32>(1.0) - invA * invF;
    return vec4<f32>(rgb, albedo.a);
}
