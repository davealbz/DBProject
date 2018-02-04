//====================================================
// Leaf
//====================================================
// By EVOLVED
// www.evolved-software.com
//====================================================

//--------------
// un-tweaks
//--------------
   matrix World:World;
   matrix WorldIT:WorldInverseTranspose;
   matrix ViewProj:ViewProjection;
   matrix ViewInv:ViewInverse;
   matrix ViewMat:View;
   matrix PreviousVP;
   matrix OrthoProj;

//--------------
// tweaks
//--------------
   float ColorIntensity=1.1;
   float Shade=0.85;
   float DetailScale=5;
   float DetailBump=0.3f;
   float WindTime;
   float WindSize=500;
   float TreeWindTime;
   float TreeWindPower=25;
   float TreeWindSize=100;
   float LeafWindTime;
   float LeafWindPower=5;
   float LeafWindSize=1;
   float3 AmbientColor;
   float3 LightColor;
   float3 LightDirection;
   float3 LightPosition;
   float LightRange;
   float3 ShadowPosition;
   float2 ShadowBias;
   float4 FogRange;
   float3 FogColor1;
   float3 FogColor2;
   float3 HeightFog;
   float4 HeightFogColor;
   float ClipHeight;

//--------------
// Textures
//--------------
   texture BaseTexture <string Name="";>;	
   sampler BaseSampler=sampler_state 
      {
 	texture=<BaseTexture>;
      };
   texture NormalTexture <string Name="";>;	
   sampler NormalSampler=sampler_state 
      {
 	texture=<NormalTexture>;
      };
   texture SpecularTexture <string Name="";>;
   sampler SpecularSampler=sampler_state 
      {
	texture=<SpecularTexture>;
      };
   texture DetailTexture <string Name="";>;
   sampler DetailSampler=sampler_state 
      {
 	texture=<DetailTexture>;
      };
   texture SubSurfaceTexture <string Name="";>;
   sampler SubSurfaceSampler=sampler_state 
      {
	texture=<SubSurfaceTexture>;
      };

//--------------
// structs 
//--------------
   struct InPut
     {
 	float4 Pos:POSITION;
 	float2 Tex:TEXCOORD;
	float3 Normal:NORMAL;
 	float3 color:COLOR0;
     };
   struct OutPut
     {
	float4 Pos:POSITION; 
   	float2 Tex:TEXCOORD0; 
   	float3 Normals:TEXCOORD1;
 	float3 color:TEXCOORD2;
	float ClipY:TEXCOORD3;
	float4 Fog:COLOR0;
     };
   struct In_Geometry
     {
 	float4 Pos:POSITION;
 	float2 Tex:TEXCOORD;
	float3 Normal:NORMAL;
 	float3 color:COLOR0;
     };
   struct Out_Geometry
     {
	float4 Pos:POSITION; 
   	float2 Tex:TEXCOORD0; 
     	float3 TBNx1:TEXCOORD1;
     	float3 TBNx2:TEXCOORD2;
     	float3 TBNx3:TEXCOORD3;
 	float3 color:TEXCOORD6;
     };
   struct In_WPosition
     {
 	float4 Pos:POSITION;
 	float2 Tex:TEXCOORD;
	float3 Normal:NORMAL;
     };
   struct Out_WPosition
     {
 	float4 Pos:POSITION; 
   	float2 Tex:TEXCOORD0;
 	float4 ViewPos:TEXCOORD1;
    	float4 CurrentPos:TEXCOORD2;
    	float4 PreviousPos:TEXCOORD3;
     };
   struct In_Depth
     {
 	float4 Pos:POSITION;
 	float2 Tex:TEXCOORD;
	float3 Normal:NORMAL;
     };
   struct Out_Depth
     {
 	float4 Pos:POSITION; 
   	float2 Tex:TEXCOORD0;
 	float4 Depth:TEXCOORD1; 
     };

//--------------
// vertex shader
//--------------
   OutPut VS(InPut IN) 
     {
 	OutPut OUT;
	float3 GlobalWind=(mul(IN.Pos,World).xyz/WindSize)+WindTime;
	GlobalWind.x=0.25f+abs(dot(cos(GlobalWind),sin(GlobalWind)));
   	float3 TreeWind=(IN.Pos.xyz/TreeWindSize)+TreeWindTime;
  	TreeWind.x=cos(TreeWind.x);
  	TreeWind.y=cos(TreeWind.y);
  	TreeWind.z=sin(TreeWind.z);
	float3 LeafWind=(IN.Pos.xyz/LeafWindSize)+LeafWindTime;
	LeafWind=abs(normalize(mul(IN.Normal,World)))*sin(dot(LeafWind,0.333f));
    	LeafWind *=LeafWindPower*(1-IN.Tex.y)*(0.1f+(abs(IN.Tex.x-0.5)*2));
	float3 WindAnimate=((TreeWind*TreeWindPower)+LeafWind)*GlobalWind.x;
    	WindAnimate.y=WindAnimate.y*0.1f;
    	WindAnimate *=IN.Pos.y/WindSize;
	float4 NewPos=mul(float4(IN.Pos.xyz+WindAnimate,1),World);
	OUT.Pos=mul(NewPos,ViewProj);
 	OUT.Tex=IN.Tex;
	OUT.Normals=normalize(mul(IN.Normal,World));
	OUT.color=IN.color*(Shade+(1-IN.Tex.y)*(1-Shade))*ColorIntensity;
	OUT.ClipY=NewPos.y-ClipHeight;
	float3 LightVec=NewPos.xyz-LightPosition;
	float ViewVecL=length(NewPos.xyz-ViewInv[3].xyz);
	float4 FogDist=saturate(float4(pow(ViewVecL.xx/FogRange.xy,FogRange.zw),length(LightVec)/(FogRange.x*2),exp(-((NewPos.y-HeightFog.x)/HeightFog.y)*HeightFog.z)*HeightFogColor.w));
	OUT.Fog=float4(lerp(HeightFogColor.xyz,lerp(FogColor2,FogColor1,FogDist.z),FogDist.x),saturate((FogDist.w*FogDist.y)+FogDist.x));
	return OUT;
     }
   Out_Geometry VS_Geometry(In_Geometry IN) 
     {
 	Out_Geometry OUT;
	float3 GlobalWind=(mul(IN.Pos,World).xyz/WindSize)+WindTime;
	GlobalWind.x=0.25f+abs(dot(cos(GlobalWind),sin(GlobalWind)));
   	float3 TreeWind=(IN.Pos.xyz/TreeWindSize)+TreeWindTime;
  	TreeWind.x=cos(TreeWind.x);
  	TreeWind.y=cos(TreeWind.y);
  	TreeWind.z=sin(TreeWind.z);
	float3 LeafWind=(IN.Pos.xyz/LeafWindSize)+LeafWindTime;
	LeafWind=abs(normalize(mul(IN.Normal,World)))*sin(dot(LeafWind,0.333f));
	LeafWind *=LeafWindPower*(1-IN.Tex.y)*(0.1f+(abs(IN.Tex.x-0.5)*2));
	float3 WindAnimate=((TreeWind*TreeWindPower)+LeafWind)*GlobalWind.x;
    	WindAnimate.y=WindAnimate.y*0.1f;
    	WindAnimate *=IN.Pos.y/WindSize;
	float4 NewPos=mul(float4(IN.Pos.xyz+WindAnimate,1),World);
	OUT.Pos=mul(NewPos,ViewProj);
 	OUT.Tex=IN.Tex;
	float3 Tangent=cross(float3(0,0,1),IN.Normal);
	float3x3 TBN={Tangent,cross(IN.Normal,Tangent),IN.Normal};
	float3x3 wTBN=mul(TBN,WorldIT);
	OUT.TBNx1=normalize(wTBN[0]);
	OUT.TBNx2=normalize(wTBN[1]);
	OUT.TBNx3=normalize(wTBN[2]);
 	OUT.color=IN.color*(Shade+(1-IN.Tex.y)*(1-Shade))*ColorIntensity;
	return OUT;
     }
   Out_WPosition VS_WPosition(In_WPosition IN) 
     {
 	Out_WPosition OUT;
	float3 GlobalWind=(mul(IN.Pos,World).xyz/WindSize)+WindTime;
	GlobalWind.x=0.25f+abs(dot(cos(GlobalWind),sin(GlobalWind)));
   	float3 TreeWind=(IN.Pos.xyz/TreeWindSize)+TreeWindTime;
  	TreeWind.x=cos(TreeWind.x);
  	TreeWind.y=cos(TreeWind.y);
  	TreeWind.z=sin(TreeWind.z);
	float3 LeafWind=(IN.Pos.xyz/LeafWindSize)+LeafWindTime;
	LeafWind=abs(normalize(mul(IN.Normal,World)))*sin(dot(LeafWind,0.333f));
    	LeafWind *=LeafWindPower*(1-IN.Tex.y)*(0.1f+(abs(IN.Tex.x-0.5)*2));
	float3 WindAnimate=((TreeWind*TreeWindPower)+LeafWind)*GlobalWind.x;
    	WindAnimate.y=WindAnimate.y*0.1f;
    	WindAnimate *=IN.Pos.y/WindSize;
	float4 NewPos=mul(float4(IN.Pos.xyz+WindAnimate,1),World);
	OUT.Pos=mul(NewPos,ViewProj);
 	OUT.Tex=IN.Tex;
	OUT.ViewPos=float4(mul(NewPos,ViewMat).xyz,OUT.Pos.z);
 	OUT.CurrentPos=OUT.Pos;
	OUT.PreviousPos=mul(NewPos,PreviousVP);
	return OUT;
     }
   Out_Depth VS_DepthMap(In_Depth IN)
     {
        Out_Depth OUT;
	float3 GlobalWind=(mul(IN.Pos,World).xyz/WindSize)+WindTime;
	GlobalWind.x=0.25f+abs(dot(cos(GlobalWind),sin(GlobalWind)));
   	float3 TreeWind=(IN.Pos.xyz/TreeWindSize)+TreeWindTime;
  	TreeWind.x=cos(TreeWind.x);
  	TreeWind.y=cos(TreeWind.y);
  	TreeWind.z=sin(TreeWind.z);
	float3 LeafWind=(IN.Pos.xyz/LeafWindSize)+LeafWindTime;
	LeafWind=abs(normalize(mul(IN.Normal,World)))*sin(dot(LeafWind,0.333f));
    	LeafWind *=LeafWindPower*(1-IN.Tex.y)*(0.1f+(abs(IN.Tex.x-0.5)*2));
	float3 WindAnimate=((TreeWind*TreeWindPower)+LeafWind)*GlobalWind.x;
    	WindAnimate.y=WindAnimate.y*0.1f;
    	WindAnimate *=IN.Pos.y/WindSize;
	float4 NewPos=mul(float4(IN.Pos.xyz+WindAnimate,1),World);
	OUT.Pos=mul(NewPos,ViewProj);
 	OUT.Tex=IN.Tex;
	OUT.Depth=float4(ShadowPosition-NewPos,0);
        return OUT;
     }
   Out_Depth VS_DepthMapDirectional(In_Depth IN)
     {
        Out_Depth OUT;
	float3 GlobalWind=(mul(IN.Pos,World).xyz/WindSize)+WindTime;
	GlobalWind.x=0.25f+abs(dot(cos(GlobalWind),sin(GlobalWind)));
   	float3 TreeWind=(IN.Pos.xyz/TreeWindSize)+TreeWindTime;
  	TreeWind.x=cos(TreeWind.x);
  	TreeWind.y=cos(TreeWind.y);
  	TreeWind.z=sin(TreeWind.z);
	float3 LeafWind=(IN.Pos.xyz/LeafWindSize)+LeafWindTime;
	LeafWind=abs(normalize(mul(IN.Normal,World)))*sin(dot(LeafWind,0.333f));
    	LeafWind *=LeafWindPower*(1-IN.Tex.y)*(0.1f+(abs(IN.Tex.x-0.5)*2));
	float3 WindAnimate=((TreeWind*TreeWindPower)+LeafWind)*GlobalWind.x;
    	WindAnimate.y=WindAnimate.y*0.1f;
    	WindAnimate *=IN.Pos.y/WindSize;
	float4 NewPos=mul(float4(IN.Pos.xyz+WindAnimate,1),World);
	OUT.Pos=mul(NewPos,OrthoProj);
 	OUT.Tex=IN.Tex;
	OUT.Depth=float4(NewPos-ShadowPosition,0);
        return OUT;
     }

//--------------
// pixel shader
//-------------- 
   float4 PS(OutPut IN) : COLOR
     {
	clip(IN.ClipY);
  	clip(tex2D(BaseSampler,IN.Tex).w-0.333f);
   	float3 Diffuse=tex2D(BaseSampler,IN.Tex)*IN.color;
	return float4(lerp(Diffuse*(saturate(dot(-LightDirection,IN.Normals)*LightColor)+AmbientColor),IN.Fog,IN.Fog.w),1);
     }
   float4 PackColor(in float4 iColor1,in float4 iColor2,in float4 iColor3)
     {
	iColor1=floor(iColor1*254);
	iColor2=floor(iColor2*254);
	iColor3=floor(iColor3*254);
	return float4((iColor1.x*65025)+(iColor2.x*255)+iColor3.x,
	 	      (iColor1.y*65025)+(iColor2.y*255)+iColor3.y,
		      (iColor1.z*65025)+(iColor2.z*255)+iColor3.z,
		      (iColor1.w*65025)+(iColor2.w*255)+iColor3.w);
     }
   float4 PS_Geometry(Out_Geometry IN) : COLOR
     {
  	clip(tex2D(BaseSampler,IN.Tex).w-0.333f);
   	float3 Diffuse=saturate(tex2D(BaseSampler,IN.Tex)*IN.color);
	float3 Normalmap=tex2D(NormalSampler,IN.Tex)*2-1;
	float3 Normals=saturate(0.5f+mul(Normalmap,float3x3(IN.TBNx1,IN.TBNx2,IN.TBNx3))*0.5f);
 	float3 Specular=tex2D(SpecularSampler,IN.Tex);
	return PackColor(float4(Diffuse,Specular.y),float4(Normals,Specular.x),tex2D(SubSurfaceSampler,IN.Tex));
     }
   float4 PS_GeometryDetail(Out_Geometry IN) : COLOR
     {
  	clip(tex2D(BaseSampler,IN.Tex).w-0.333f);
	float4 Detail=tex2D(DetailSampler,IN.Tex*DetailScale);
   	float3 Diffuse=saturate(((tex2D(BaseSampler,IN.Tex)*IN.color)+Detail.www)-0.5f);
	float3 Normalmap=(tex2D(NormalSampler,IN.Tex)*2-1)+((Detail.xyz*2-1)*DetailBump);
	float3 Normals=saturate(0.5f+mul(Normalmap,float3x3(IN.TBNx1,IN.TBNx2,IN.TBNx3))*0.5f);
 	float3 Specular=tex2D(SpecularSampler,IN.Tex);
	return PackColor(float4(IN.color,Specular.y),float4(Normals,Specular.x),tex2D(SubSurfaceSampler,IN.Tex));
     }
   float4 PS_WPosition(Out_WPosition IN) : COLOR
     {
  	clip(tex2D(BaseSampler,IN.Tex).w-0.333f);
	float2 Velocity=(IN.CurrentPos/IN.CurrentPos.w)-(IN.PreviousPos/IN.PreviousPos.w);
	return float4(length(IN.ViewPos.xyz),IN.ViewPos.w,Velocity);
     }
   float4 PS_DepthMapVsm(Out_Depth IN) : COLOR
     {
  	clip(tex2D(BaseSampler,IN.Tex).w-0.333f);
	float Depth=saturate(length(IN.Depth.xyz/LightRange));
        return float4(Depth,Depth*Depth,0,0);
     }
   float4 PS_DepthMapEvsm(Out_Depth IN) : COLOR
     {
  	clip(tex2D(BaseSampler,IN.Tex).w-0.333f);
	float Depth=saturate(length(IN.Depth.xyz/LightRange));
	float2 DepthPN=float2(Depth+ShadowBias.x,1-Depth+ShadowBias.y);
	float2 DepthExp=exp(DepthPN*7-3.5f);
        return float4(DepthExp.x,DepthExp.y,DepthExp.x*DepthExp.x,DepthExp.y*DepthExp.y);
     }
   float4 PS_DepthMapDirectionalVsm(Out_Depth IN) : COLOR
     {
  	clip(tex2D(BaseSampler,IN.Tex).w-0.333f);
	float Depth=saturate(dot(IN.Depth.xyz,LightDirection)/LightRange)+ShadowBias.x;
        return float4(Depth,Depth*Depth,0,0);
     }
   float4 PS_DepthMapDirectionalVsmBa(Out_Depth IN) : COLOR
     {
  	clip(tex2D(BaseSampler,IN.Tex).w-0.333f);
	float Depth=saturate(dot(IN.Depth.xyz,LightDirection)/LightRange)+ShadowBias.x;
        return float4(0,0,Depth,Depth*Depth);
     }
   float4 PS_DepthMapDirectionalEvsm(Out_Depth IN) : COLOR
     {
  	clip(tex2D(BaseSampler,IN.Tex).w-0.333f);
	float Depth=saturate(dot(IN.Depth.xyz,LightDirection)/LightRange);
	float2 DepthPN=float2(Depth+ShadowBias.x,1-Depth+ShadowBias.y);
	float2 DepthExp=exp(DepthPN*7-3.5f);
        return float4(DepthExp.x,DepthExp.y,DepthExp.x*DepthExp.x,DepthExp.y*DepthExp.y);
     }

//--------------
// techniques   
//--------------
   technique Diffuse
      {
 	pass p1
      {		
 	vertexShader = compile vs_3_0 VS(); 
 	pixelShader  = compile ps_3_0 PS();
      }
      }
   technique Geometry
      {
 	pass p1
      {		
 	vertexShader = compile vs_3_0 VS_Geometry(); 
 	pixelShader  = compile ps_3_0 PS_Geometry();
      }
      }
   technique GeometryDetail
      {
 	pass p1
      {		
 	vertexShader = compile vs_3_0 VS_Geometry(); 
 	pixelShader  = compile ps_3_0 PS_GeometryDetail();
      }
      }
   technique WPosition
      {
 	pass p1
      {		
 	vertexShader = compile vs_3_0 VS_WPosition(); 
 	pixelShader  = compile ps_3_0 PS_WPosition();
      }
      }
    technique DepthMapVsm
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMap(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapVsm();
      }
      }
    technique DepthMapEvsm
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMap(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapEvsm();
      }
      }
    technique DepthMapDirectionalVsm
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMapDirectional(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapDirectionalVsm();
        ColorWriteEnable=3;
      }
      }
    technique DepthMapDirectionalVsmBa
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMapDirectional(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapDirectionalVsmBa();
        ColorWriteEnable=12;
      }
      }
    technique DepthMapDirectionalEvsm
      {
 	pass p1
      {		
 	VertexShader = compile vs_3_0 VS_DepthMapDirectional(); 
 	PixelShader  = compile ps_3_0 PS_DepthMapDirectionalEvsm();
      }
      }