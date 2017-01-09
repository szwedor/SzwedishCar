#version 330

// Holds information about a light
struct Light {
 vec3 position;
 vec3 color;
 float ambientIntensity;
 float diffuseIntensity;

 int type;
 vec3 direction;
 float coneAngle;

 float linear;
 float quadratic;
 float radius;
};

in vec3 v_norm;
in vec3 v_pos;
in vec2 f_texcoord;
out vec4 outputColor;

// Texture information
uniform sampler2D maintexture;

uniform mat4 view;

// Material information
uniform vec3 material_ambient;
uniform vec3 material_diffuse;
uniform vec3 material_specular;
uniform float material_specExponent;

// Array of lights used in the shader
uniform Light lights[5];

void
main()
{
 outputColor = vec4(0,0,0,1);

 // Texture information
 vec2 flipped_texcoord = vec2(f_texcoord.x, 1.0 - f_texcoord.y);
 vec4 texcolor = texture2D(maintexture, flipped_texcoord.xy);

 vec3 n = normalize(v_norm);
 
 // Loop through lights, adding the lighting from each one
 for(int i = 0; i < 5; i++){
  
  // Skip lights with no effect
  if(lights[i].color == vec3(0,0,0))
  {
   continue;
  }
  
  vec3 lightvec = normalize(lights[i].position - v_pos);
  vec4 lightcolor = vec4(0,0,0,1);

  // Check spotlight angle
  bool inCone = false;
  if(lights[i].type == 1 && degrees(acos(dot(lightvec, lights[i].direction))) < lights[i].coneAngle)
  {
   inCone = true;
  }

  // Directional lighting
  if(lights[i].type == 2){
   lightvec = lights[i].direction;
  }





  // Ambient
  vec4 ambient = lights[i].ambientIntensity * vec4(lights[i].color, 0.0);
  lightcolor = lightcolor + texcolor * ambient;// * vec4(material_ambient, 0.0);


  //Diffuse
  vec4 light_diffuse = lights[i].diffuseIntensity * vec4(lights[i].color, 0.0);
  float lambert = max(dot(n, lightvec), 0.0);
  if(lights[i].type != 1 || inCone){  // Spotlight, limit light to specific angle
   lightcolor = lightcolor + (light_diffuse * texcolor * vec4(material_diffuse, 0.0)) * lambert;
  }


  // Specular lighting
  vec3 reflectionvec = normalize(reflect(-lightvec, v_norm));
  vec3 viewvec = normalize(vec3(inverse(view) * vec4(0,0,0,1)) - v_pos); 
  float material_specularreflection = pow(max(dot(reflectionvec, viewvec), 0.0), material_specExponent);

  if(lights[i].type != 1 || inCone){ // Spotlight, specular reflections are also limited by angle
  if(lights[i].type!=2)
   lightcolor = lightcolor + vec4(material_specular * lights[i].color, 0.0) * material_specularreflection;
  }

  // Attenuation
  float distancefactor = distance(lights[i].position, v_pos);
  float attenuation = 1.0 / (1.0 + (distancefactor * lights[i].linear) + (distancefactor * distancefactor * lights[i].quadratic));
  outputColor = outputColor + lightcolor * attenuation;
 }

}