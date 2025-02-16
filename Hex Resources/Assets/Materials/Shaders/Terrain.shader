﻿Shader "Custom/Terrain"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Terrain Texture Array", 2DArray) = "white" {}
        _GridTex ("Grid Texture", 2D) = "white" {}
        [NoScaleOffset] _HeightMap ("Heights", 2D) = "grey" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Specular ("Specular", Color) = (0.2, 0.2, 0.2)
        _BackgroundColor ("Background Color", Color) = (0, 0, 0)
        [Toggle(SHOW_MAP_DATA)] _ShowMapData ("Show Map Data", Float) = 0
        _BackgroundTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardSpecular fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.5

        #pragma multi_compile _ GRID_ON
        #pragma multi_compile _ HEX_MAP_EDIT_MODE

        #pragma shader_feature SHOW_MAP_DATA

        #include "HexCellData.cginc"
        #include "HexMetrics.cginc"

        UNITY_DECLARE_TEX2DARRAY(_MainTex);

        struct Input
        {
	        float4 color: COLOR;
            float3 worldPos;
            float3 terrain;
            float4 visibility;
            float2 uv_HeightMap;
            float4 screenPos;

            #if defined(SHOW_MAP_DATA)
                float mapData;
            #endif
        };
        
        sampler2D _HeightMap;
        float4 _HeightMap_TexelSize;

        half _Glossiness;
        fixed3 _Specular;
        fixed4 _Color;
        sampler2D _GridTex;
        // half3 _BackgroundColor;

        sampler2D _BackgroundTex;
        float4 _BackgroundTex_ST;


        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void vert (inout appdata_full v, out Input data)
        {
            UNITY_INITIALIZE_OUTPUT(Input, data);

            float4 cell0 = GetCellData(v, 0);
            float4 cell1 = GetCellData(v, 1);
            float4 cell2 = GetCellData(v, 2);

            data.terrain.x = cell0.w;
            data.terrain.y = cell1.w;
            data.terrain.z = cell2.w;

            data.visibility.x = cell0.x;
            data.visibility.y = cell1.x;
            data.visibility.z = cell2.x;
            data.visibility.xyz = lerp(0.25, 1, data.visibility.xyz);
            data.visibility.w = cell0.y * v.color.x + cell1.y * v.color.y + cell2.y * v.color.z;
        }

        float4 GetTerrainColor (Input IN, int index)
        {
            float3 uvw = float3(IN.worldPos.xz * (2 * TILING_SCALE), IN.terrain[index]);
            float4 c = UNITY_SAMPLE_TEX2DARRAY(_MainTex, uvw);
            return c *= (IN.color[index] * IN.visibility[index]);
        }

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            fixed4 c =
                GetTerrainColor(IN, 0) +
                GetTerrainColor(IN, 1) +
                GetTerrainColor(IN, 2);

            fixed4 grid = 1;
            #if defined(GRID_ON)
                float2 gridUV = IN.worldPos.xz;
                gridUV.x *= 1 / (4 * 8.66025404);
                gridUV.y *= 1 / (2 * 15.0);
                grid = tex2D(_GridTex, gridUV);
            #endif

            float2 heightUV = IN.worldPos.xz;
            heightUV.x *= 1 / (4 * 8.66025404);
            heightUV.y *= 1 / (2 * 15.0);
            heightUV *= 0.45;

            float explored = IN.visibility.w;
            o.Albedo = c.rgb * grid * _Color * explored;

            #if defined(SHOW_MAP_DATA)
                o.Albedo = IN.mapData * grid;
            #endif

            float2 bgTexCoordinates = IN.screenPos.xy / IN.screenPos.w;
            float aspect = _ScreenParams.x / _ScreenParams.y;
            bgTexCoordinates.x *= aspect;
            bgTexCoordinates = TRANSFORM_TEX(bgTexCoordinates, _BackgroundTex);
            fixed4 bgCol = tex2D(_BackgroundTex, bgTexCoordinates);

            o.Specular = _Specular * explored;
            o.Smoothness = _Glossiness;
            o.Occlusion = explored;
            // o.Emission = _BackgroundColor * (1 - explored);
            o.Emission = bgCol * (1 - explored);
            o.Normal = UnpackNormal (tex2D(_HeightMap, heightUV));
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
