#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

// Linear fog toward the horizon color, matching the Flutter scene (start 70 m, end 210 m).
constant half3 fogColor = half3(0.75h, 0.82h, 0.92h);
constant float fogStart = 70.0;
constant float fogEnd = 210.0;

[[visible]]
void foggedSurface(realitykit::surface_parameters params)
{
    auto material = params.material_constants();
    float3 world = params.geometry().world_position();
    float3 view = (params.uniforms().world_to_view() * float4(world, 1.0)).xyz;
    half fog = half(saturate((length(view) - fogStart) / (fogEnd - fogStart)));
    half keep = 1.0h - fog;
    float glow = max(params.uniforms().custom_parameter().x, 1.0);

    auto surface = params.surface();
    surface.set_base_color(half3(material.base_color_tint()) * keep);
    surface.set_emissive_color(half3(material.emissive_color() * glow) * keep + fogColor * fog);
    surface.set_roughness(half(material.roughness_scale()));
    surface.set_metallic(half(material.metallic_scale()) * keep);
    surface.set_specular(half(material.specular_scale()) * keep);
}
