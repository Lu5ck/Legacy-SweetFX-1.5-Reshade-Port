/*------------------------------------------------------------------------------
						HDR
------------------------------------------------------------------------------*/
uniform float HDRPower
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 8.00;
	ui_tooltip = "Strangely lowering this makes the image brighter";
> = 1.30;
uniform float radius2
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 8.00;
	ui_tooltip = "Raising this seems to make the effect stronger and also brighter";
> =  0.87;

#include "ReShade.fxh"

float4 HDRPass( float4 colorInput, float2 Tex )
{
	float3 c_center = tex2D(ReShade::BackBuffer, Tex).rgb; //reuse SMAA center sample or lumasharpen center sample?
	//float3 c_center = colorInput.rgb; //or just the input?
	
	//float3 bloom_sum1 = float3(0.0, 0.0, 0.0); //don't initialize to 0 - use the first tex2D to do that
	//float3 bloom_sum2 = float3(0.0, 0.0, 0.0); //don't initialize to 0 - use the first tex2D to do that
	//Tex += float2(0, 0); // +0 ? .. oh riiiight - that will surely do something useful
	
	float radius1 = 0.793;
	float3 bloom_sum1 = tex2D(ReShade::BackBuffer, Tex + float2(1.5, -1.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, Tex + float2(-1.5, -1.5) * radius1).rgb; //rearrange sample order to minimize ALU and maximize cache usage
	bloom_sum1 += tex2D(ReShade::BackBuffer, Tex + float2(1.5, 1.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, Tex + float2(-1.5, 1.5) * radius1).rgb;
	
	bloom_sum1 += tex2D(ReShade::BackBuffer, Tex + float2(0, -2.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, Tex + float2(0, 2.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, Tex + float2(-2.5, 0) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, Tex + float2(2.5, 0) * radius1).rgb;
	
	bloom_sum1 *= 0.005;
	
	float3 bloom_sum2 = tex2D(ReShade::BackBuffer, Tex + float2(1.5, -1.5) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, Tex + float2(-1.5, -1.5) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, Tex + float2(1.5, 1.5) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, Tex + float2(-1.5, 1.5) * radius2).rgb;


	bloom_sum2 += tex2D(ReShade::BackBuffer, Tex + float2(0, -2.5) * radius2).rgb;	
	bloom_sum2 += tex2D(ReShade::BackBuffer, Tex + float2(0, 2.5) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, Tex + float2(-2.5, 0) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, Tex + float2(2.5, 0) * radius2).rgb;

	bloom_sum2 *= 0.010;
	
	float dist = radius2 - radius1;
	
	float3 HDR = (c_center + (bloom_sum2 - bloom_sum1)) * dist;
	float3 blend = HDR + colorInput.rgb;
	colorInput.rgb = pow(abs(blend), abs(HDRPower)) + HDR; // pow - don't use fractions for HDRpower
	
	return saturate(colorInput);
}

float3 HDRWrap(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord);

	color = HDRPass(color,texcoord);

	return color.rgb;
}

technique HDR_Tech
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = HDRWrap;
	}
}
