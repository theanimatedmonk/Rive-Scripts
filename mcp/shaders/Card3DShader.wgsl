// Card3DShader — 3D card sized from the face artboard.
// Front/back sample the artboard texture (kind = 0).
// Rim faces use edgeColor (kind = 1).
//
// Lighting: a slight UV bulge so the highlight travels across the face as the
// card turns (a perfectly flat normal would brighten the whole face at once).
//
// Bindings group 0:
//   0: UBO 208 bytes — mvp, model, edgeColor,
//      light (angleRad, lightI, glossI, glossSharp 0-1),
//      params.x = curvature, params.y = ambient 0-1, lightColor = gloss tint,
//      foil (intensity 0-1, stripe count, tilt shift 0-1, angle rad)
//   1: face texture
//   2: sampler

struct UBO {
    mvp: mat4x4<f32>,
    model: mat4x4<f32>,
    edgeColor: vec4<f32>,
    light: vec4<f32>,
    params: vec4<f32>,
    lightColor: vec4<f32>,
    foil: vec4<f32>,
}
@group(0) @binding(0) var<uniform> u: UBO;
@group(0) @binding(1) var tFace: texture_2d<f32>;
@group(0) @binding(2) var tSamp: sampler;

struct VIn {
    @location(0) pos: vec3<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) kind: f32,
}

struct VOut {
    @builtin(position) clip: vec4<f32>,
    @location(0) uv: vec2<f32>,
    @location(1) kind: f32,
    @location(2) localPos: vec3<f32>,
}

@vertex
fn vs_main(v: VIn) -> VOut {
    var o: VOut;
    o.clip = u.mvp * vec4<f32>(v.pos, 1.0);
    o.uv = v.uv;
    o.kind = v.kind;
    o.localPos = v.pos;
    return o;
}

@fragment
fn fs_main(f: VOut) -> @location(0) vec4<f32> {
    let sampled = textureSample(tFace, tSamp, f.uv);
    let k = clamp(f.kind, 0.0, 1.0);
    let albedo = mix(sampled, u.edgeColor, k);

    let uvC = f.uv * 2.0 - 1.0;
    let curve = u.params.x;
    let zRaw = f.localPos.z;
    let zN = select(1.0, sign(zRaw), abs(zRaw) > 0.001);
    let nFace = normalize(vec3<f32>(uvC.x * curve, uvC.y * curve, zN));
    let nRim = normalize(vec3<f32>(f.localPos.x, f.localPos.y, 0.0001));
    let nLocal = normalize(mix(nFace, nRim, k));
    let nWorld = normalize((u.model * vec4<f32>(nLocal, 0.0)).xyz);

    let angle = u.light.x;
    let L = normalize(vec3<f32>(sin(angle), 0.42, cos(angle)));
    let V = vec3<f32>(0.0, 0.0, 1.0);
    let H = normalize(L + V);

    let ndl = max(dot(nWorld, L), 0.0);
    let ndh = max(dot(nWorld, H), 0.0);
    let ndv = max(dot(nWorld, V), 0.0);
    let lightI = u.light.y;
    let glossI = u.light.z;
    let sharp = clamp(u.light.w, 0.0, 1.0);
    let power = mix(6.0, 96.0, sharp);
    let specTerm = pow(clamp(ndh, 0.0001, 1.0), power);
    let fres = pow(clamp(1.0 - ndv, 0.0, 1.0), 2.0);
    let spec = specTerm * glossI * 1.6 * (1.0 + fres * 0.45);
    let ambient = u.params.y;
    let diffuse = mix(ambient, 1.0, ndl * clamp(lightI * 2.4, 0.0, 1.0));
    let lit = albedo.rgb * diffuse + u.lightColor.rgb * spec;

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
    let tilt = nWorld.x * 0.9 + nWorld.y * 0.28;
    let phase = (stripeUv + wave + tilt * shiftAmt) * stripes * 6.2831855;
    let hr = 0.5 + 0.5 * sin(phase);
    let hg = 0.5 + 0.5 * sin(phase + 2.094395);
    let hb = 0.5 + 0.5 * sin(phase + 4.18879);
    let foilMask = 0.42 + 0.58 * fres + 0.32 * specTerm;
    let foilLit = vec3<f32>(hr, hg, hb) * foilI * foilMask;
    let invA = vec3<f32>(1.0) - lit;
    let invF = vec3<f32>(1.0) - foilLit;
    let rgb = vec3<f32>(1.0) - invA * invF;
    return vec4<f32>(rgb, albedo.a);
}
