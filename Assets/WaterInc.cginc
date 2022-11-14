#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

struct MeshData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    float4 texCoord : TEXCOORD1;
};

struct Interpolators
{
    float4 vertex : SV_POSITION;
    float4 texCoord : TEXCOORD0;
    float4 screenPos : TEXCOORD1;
    float2 uv : TEXCOORD2;
    float3 normal : TEXCOORD3;
    float3 tangent : TEXCOORD4;
    float3 bitangent : TEXCOORD5;
    float3 wPos : TEXCOORD6;
    LIGHTING_COORDS(7,8)
};

float4 _Color;
UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
float _DepthFactor;
fixed _DepthPow;
float4 _EdgeColor;
fixed _IntersectionThreshold;
fixed _IntersectionPow;

float2 _normalVelocity1 = float2(2,2);
float2 _normalVelocity2;

sampler2D _Normal1;
float4 _Normal1_ST;

sampler2D _Normal2;

float _Gloss;

sampler2D _NoiseTex;
float _WaveSpeed;
float _WaveAmp;
float _ExtraHeight;

Interpolators vert (MeshData v)
{
    Interpolators o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    
    o.uv = TRANSFORM_TEX(v.uv, _Normal1);
    o.normal = UnityObjectToWorldNormal(v.normal);    
    o.tangent=UnityObjectToWorldDir(v.tangent.xyz);
    o.bitangent = cross(o.normal,o.tangent);
    o.bitangent *= (v.tangent.w * unity_WorldTransformParams.w);
    
    o.wPos = mul(unity_ObjectToWorld,v.vertex);
    TRANSFER_VERTEX_TO_FRAGMENT(o); //lighting actually
                
    float noiseSample = tex2Dlod(_NoiseTex, float4(v.texCoord.xy, 0, 0));
    o.vertex.y += sin(_Time * _WaveSpeed * noiseSample) * _WaveAmp + _ExtraHeight;

    // compute depth
    o.screenPos = ComputeScreenPos(o.vertex);
    COMPUTE_EYEDEPTH(o.screenPos.z);

    return o;
}

fixed4 frag (Interpolators i) : SV_Target
{
    fixed4 col = _Color;

    // compute depth
    float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));
    float depth = sceneZ - i.screenPos.z;

    // fade with depth
    fixed depthFading = saturate((abs(pow(depth, _DepthPow))) / _DepthFactor);
    col *= depthFading;

    // "foam line"
    fixed intersect = saturate((abs(depth)) / _IntersectionThreshold);
    col += _EdgeColor * pow(1 - intersect, 4) * _IntersectionPow;


    //float2 uv1 = float2(i.uv.x,i.uv.y);
    float2 uv1 = i.uv.xy - (_Time.y * .09f);
    float2 uv2 = i.uv.xy + (_Time.y * .09f);
    float3 normal1 = UnpackNormal( tex2D(_Normal1,uv1));
    float3 normal2 = UnpackNormal( tex2D(_Normal2,uv2));
    float3 normal = lerp(normal1,normal2,.5f);
    float3 tangentSpaceNormal = normal;

    float3x3 mtxTangToWorld = {
        i.tangent.x, i.bitangent.x,i.normal.x,
        i.tangent.y, i.bitangent.y,i.normal.y,
        i.tangent.z, i.bitangent.z,i.normal.z
    };
    
    float3 N = mul(mtxTangToWorld,tangentSpaceNormal);
    //float3 N = i.normal;
    float3 L = normalize(UnityWorldSpaceLightDir(i.wPos));

    float attenuation = LIGHT_ATTENUATION(i);
    
    float3 lambert = saturate(dot(N,L));
    float3 diffuseLight = (lambert * attenuation) * _LightColor0.xyz;

    //specular lighting
    float3 V = normalize(_WorldSpaceCameraPos- i.wPos);
    float3 H = normalize(L+V);
    float3 specularLight = saturate(dot(H, N)) * (lambert > 0);

    float specularExponent = exp2( _Gloss * 11 ) + 2;
    specularLight = pow( specularLight, specularExponent ) * _Gloss * attenuation;
    specularLight *= _LightColor0.xyz;
    
    return float4(diffuseLight * col + specularLight,1);
                
    return col;
}