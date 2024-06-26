#define root_signature "RootFlags(ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT)"

[RootSignature(root_signature)]
void vsMain(
    float2 position : POSITION,
    out float4 out_position : SV_Position
) {
    out_position = float4(position, 0.0, 1.0);
}

[RootSignature(root_signature)]
void psMain(
    float4 position : SV_Position,
    out float4 out_color : SV_Target0
) {
    out_color = float4(0.75, 0.0, 0.0, 1.0);
}
