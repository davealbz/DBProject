//====================================================
// Particles
//====================================================
// By EVOLVED
// www.evolved-software.com
//====================================================

//--------------
// un-tweaks
//--------------
   matrix ViewProj:ViewProjection;
   matrix ViewInv:ViewInverse;
   float time:Time;

//--------------
// tweaks
//--------------
   matrix EmitterMat;
   matrix ParticleMat;
   float ZshiftScale;
   float4 ParticlePosition[75];
   float4 ParticleColor[75];
   float4 ParticleAngle[75];
   float4 AlphaMultiplier;
   float4 Intensity;
   float2 AlphaToSurface;
   float4 Animation;
   float4 ViewSize;
   float EdgeSoftness;
   float Blocker;
   float4 FogRange;
   float3 HeightFog;
   float4 HeightFogColor;

//--------------
// Textures
//--------------
   texture DepthTexture <string Name = "";>;
   sampler DepthSampler=sampler_state 
      {
	Texture=<DepthTexture>;
	MagFilter=None;
	MinFilter=None;
	MipFilter=None;
      };
   texture ParticleTexture <string Name = "";>;	
   sampler ParticleSampler=sampler_state 
      {
 	Texture=<ParticleTexture>;
      };
   texture EmitterTexture <string Name = "";>;	
   sampler EmitterSampler=sampler_state 
      {
 	Texture=<EmitterTexture>;
      };

//--------------
// structs 
//--------------
   struct InPut
     {
 	float2 UV:TEXCOORD0; 
        float2 Index:TEXCOORD1;
        float Texture:TEXCOORD2;
     };
   struct OutPut
     {
	float4 Pos:POSITION; 
 	float4 Tex0:TEXCOORD0;
 	float2 Tex1:TEXCOORD1;
	float3 Frame:TEXCOORD2;
	float4 Proj:TEXCOORD3;
 	float4 ParticleColor:COLOR0;
     };

//--------------
// vertex shader
//--------------
   OutPut VS(InPut IN) 
     {
 	OutPut OUT;
	float4 VPos=ParticlePosition[IN.Index.x];
	float4 VColor=ParticleColor[IN.Index.x];
	float4 VAngle=ParticleAngle[IN.Index.x];
	float3 View=VPos-ViewInv[3].xyz;
	float Zshift=1+(length(View)*ZshiftScale);
   	float DSin,DCos,DSin2;
      	sincos(VAngle.x,DSin,DCos);
	DSin2=DSin*2;
    	float3x3 XRotateAxis=float3x3(1,0,0,0,1-(DSin*DSin2),-(DCos*DSin2),0,DCos*DSin2,1-(DSin*DSin2));
    	sincos(VAngle.y,DSin,DCos);
	DSin2=DSin*2;
    	float3x3 YRotateAxis=float3x3(1-(DSin*DSin2),0,DCos*DSin2,0,1,0,-(DCos*DSin2),0,1-(DSin*DSin2));
    	sincos(VAngle.z,DSin,DCos);
	DSin2=DSin*2;
    	float3x3 ZRotateAxis=float3x3(1-(DSin*DSin2),-(DCos*DSin2),0,DCos*DSin2,1-(DSin*DSin2),0,0,0,1);
 	float3 Scale=float3((IN.UV.x-0.5f)*VPos.w*Zshift,0,(IN.UV.y-0.5f)*((VPos.w*Zshift)*VAngle.w));
	OUT.Pos=mul(float4(mul(mul(mul(Scale,ZRotateAxis),XRotateAxis),YRotateAxis)+VPos,1),ViewProj);
	float2 UV=float2(IN.UV.x,1-IN.UV.y)/Animation;
	float FrameTime=(VColor.w*Animation.w)*Animation.z;
 	OUT.Tex0.xy=UV+(float2(int(FrameTime),int(FrameTime/Animation.x))/Animation);
	FrameTime +=1;
 	OUT.Tex0.zw=UV+(float2(int(FrameTime),int(FrameTime/Animation.x))/Animation);
	OUT.Tex1=IN.UV;
	OUT.Frame=float3(FrameTime-floor(FrameTime),IN.Texture,lerp(AlphaToSurface.x,AlphaToSurface.y,IN.Texture));
	float2 Alpha=(1-pow(1-VColor.ww,AlphaMultiplier.xz))*(1-pow(VColor.ww,AlphaMultiplier.yw));
	OUT.Proj=float4(OUT.Pos.x*0.5+0.5*OUT.Pos.w,0.5*OUT.Pos.w-OUT.Pos.y*0.5,OUT.Pos.w,OUT.Pos.z);
	float ViewVecL=length(View);
	float3 FogDist=saturate(float3(pow(ViewVecL.xx/FogRange.xy,FogRange.zw),exp(-((VPos.y-HeightFog.x)/HeightFog.y)*HeightFog.z)*HeightFogColor.w));
	float Fog=1-saturate((FogDist.z*FogDist.y)+FogDist.x);
	float4 Color=float4(VColor.xyz,lerp(Alpha.x,Alpha.y,IN.Texture)*Fog);
	OUT.ParticleColor=lerp(Color*Intensity.xxxy,Color*Intensity.zzzw,IN.Texture);
	return OUT;
     }

//--------------
// pixel shader
//--------------
    float4 PS(OutPut IN)  : COLOR
     {
	float4 Particle=lerp(tex2D(EmitterSampler,IN.Tex1.xy),lerp(tex2D(ParticleSampler,IN.Tex0.xy),tex2D(ParticleSampler,IN.Tex0.zw),IN.Frame.x),IN.Frame.y)*IN.ParticleColor;
	Particle.w *=saturate((tex2D(DepthSampler,((IN.Proj.xy/IN.Proj.z)*ViewSize.zw)+ViewSize.xy).y-IN.Proj.w)*EdgeSoftness);
	Particle.xyz=lerp(Particle.xyz+(Particle.www*IN.Frame.z),float3(0.5,0.5,0),Blocker);
	return Particle;
    }

//--------------
// techniques   
//--------------
   technique Particles
      {
 	pass p0
      {		
	vertexShader= compile vs_3_0 VS();
 	pixelShader = compile ps_3_0 PS();
	AlphaBlendEnable=true;
	SrcBlend=SRCALPHA;
	zwriteenable=false;
        ColorWriteEnable=7;	
      }
      }