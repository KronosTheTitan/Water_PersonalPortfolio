Shader "Unlit/Water"
{
    Properties
    {
        [HDR] _Color("Color", Color) = (1, 1, 1, 1)
        _DepthFactor("Depth Factor", float) = 1.0
        _DepthPow("Depth Pow", float) = 1.0
        _Normal1("Normal Map 1", 2d) = "bump" {}
        _Normal2("Normal Map 2", 2d) = "bump" {}

        [HDR] _EdgeColor("Edge Color", Color) = (1, 1, 1, 1)
        _IntersectionThreshold("Intersection threshold", Float) = 1
        _IntersectionPow("Pow", Float) = 1
        _Gloss ("Gloss",Range(0,1)) = 1     

        _NoiseTex("Noise Texture", 2D) = "white" {}
        _WaveSpeed("Wave Speed", float) = 1
        _WaveAmp("Wave Amp", float) = 0.2
        _ExtraHeight("Extra Height", float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        //base pass
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define IS_IN_BASE_PASS

            #include "WaterInc.cginc"

            ENDCG
        }
        
        //add pass
        Pass
        {
            Tags {"LightMode" = "ForwardAdd"}

            Blend One One // src*1 +dst*1
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            #include "WaterInc.cginc"

            ENDCG
        }
    }
}