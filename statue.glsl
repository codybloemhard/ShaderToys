#define VIEW_DIST 200.0

struct Material{
    vec3 albedo;
    vec2 specular;
    vec3 specularColour;
    float reflection;
};

Material matWhite = Material(vec3(0.9, 0.9, 0.9), vec2(1.0, 0.0), vec3(1.0), 0.0);
Material matGlossy = Material(vec3(0.2, 0.2, 0.7), vec2(16.0, 3.0), vec3(1.0), 0.1);
Material matBrown = Material(vec3(0.2, 0.1, 0.05), vec2(16.0, 1.0), vec3(1.0), 0.0);

Material matGold = Material(vec3(1.0, 1.0, 1.0), vec2(128.0, 8.0), vec3(0.6, 0.6, 0.1), 0.5);
Material matMirror = Material(vec3(1.0), vec2(256.0, 1.0), vec3(1.0), 1.0);
    
float sdfSphere(vec3 point, vec3 pos, float radius){
    return length(point - pos) - radius;
}

float sdfPlane(vec3 point, float down){
    return point.y - down;
}

float sdfBox(vec3 point, vec3 pos, vec3 size)
{
  return length(max(abs(point-pos)-size*0.5,0.0));
}

float sdfEllipsoid(vec3 p, vec3 pos, vec3 r)
{
    p -= pos;
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float sdfUnion( float d1, float d2 )
{
    return min(d1,d2);
}

float sdfSubtract( float d1, float d2 )
{
    return max(-d1,d2);
}

float sdfIntersect( float d1, float d2 )
{
    return max(d1,d2);
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sdfBlend(float d1, float d2, float k)
{
    return smin( d1, d2, k);
}


float sHead(vec3 point, vec3 pos){
    point -= pos;
    float p0 = sdfSphere(point, vec3(0.0, 1.0, 0.0), 1.0);
    float p1 = sdfBox(point, vec3(0.0, -0.0, 0.0), vec3(1.0, 1.0, 1.0));
    return sdfBlend(p0, p1, 1.0);
}

float sBody(vec3 point, vec3 pos){
    point -= pos;
    point.z *= 1.3;
    float p0 = sdfBox(point, vec3(0.0), vec3(1.5, 3.0, 1.0));
    float p1 = sdfSphere(point, vec3(0.0), 1.0);
    return sdfBlend(p0, p1, 1.5);
}

float sdfStatue(vec3 point, vec3 pos){
    float res = 0.0;
    point -= pos;
    
    float head = sHead(point/0.7, vec3(0.0, 2.8, 0.0)) * 0.7;
    float body = sBody(point, vec3(0.0, 0.0, 0.0));
    float arm0 = sdfEllipsoid(point, vec3(+1.5, +1.1, 0.0), vec3(2.2, 0.3, 0.3));
    float arm1 = sdfEllipsoid(point, vec3(-1.5, +1.1, 0.0), vec3(2.2, 0.3, 0.3));
    float leg1 = sdfEllipsoid(point, vec3(+0.6, -2.5, 0.0), vec3(0.5, 2.5, 0.5));
    float leg2 = sdfEllipsoid(point, vec3(-0.6, -2.5, 0.0), vec3(0.5, 2.5, 0.5));
    float legs = sdfUnion(leg1, leg2);
    
    res = sdfBlend(head, body, 0.5);
    res = sdfBlend(res, arm0, 0.5);
    res = sdfBlend(res, arm1, 0.5);
    res = sdfBlend(res, legs, 0.5);
    return res;
}

#define SHAPES 1
vec2 getSDF(vec3 point){
    vec2 shapes[SHAPES];
    shapes[0] = vec2(sdfStatue(point, vec3(0.0, 1.0, 0.0)), 3.0);
    float minf = VIEW_DIST * 10.0;
    vec2 res = shapes[0];
    for(int i = 1; i < SHAPES; i++){
        if(shapes[i].x < res.x){
            minf = shapes[i].x;
            res = shapes[i];
        }
    }
    return res;
}

vec2 intersect(vec3 ro, vec3 rd){
    for(float t = 0.0; t < VIEW_DIST;){
        vec2 closest = getSDF(ro + t*rd);
        if(closest.x < 0.001) return vec2(t, closest.y);
        t += closest.x;
    }
    return vec2(0.0);
}

vec3 calcNormal(vec3 pos){
    vec3 e = vec3(0.001, 0.0, 0.0);
    vec3 n;
    n.x = getSDF(pos + e.xyy).x - getSDF(pos - e.xyy).x;
    n.y = getSDF(pos + e.yxy).x - getSDF(pos - e.yxy).x;
    n.z = getSDF(pos + e.yyx).x - getSDF(pos - e.yyx).x;
    return normalize(n);
}

float calcShadow(vec3 ro, vec3 rd, float ldits){
    float res = 1.0;
    ro += rd * 0.1;
    for(float t = 0.1; t < ldits;){
        float h = getSDF(ro + t*rd).x;
        if(h < 0.001) return 0.0;
        res = min( res, 8.0*h/t );
        t += h;
    }
    return res;
}

float calcAmbientOcclusion(vec3 pos, vec3 nor)
{
    float stepSize = 0.01f;
    float t = stepSize;
    float oc = 0.0f;
    for(int i = 0; i < 10; ++i)
    {
        float d = getSDF(pos + nor * t).x;
        oc += t - d;
        t += stepSize;
    }

    return 1.0 - clamp(oc, 0.0, 1.0);
}

vec3 calcShading(vec3 pos, vec3 nor, vec3 camdir, vec3 lightpos, Material mat){
    vec3 lightDifference = lightpos - pos;
    vec3 lightdir = normalize(lightDifference);
    float ambientL = 0.01;
    float diffuseL = dot(nor, lightdir);
    float shadowL = calcShadow(pos, lightdir, length(lightDifference));
    
    vec3 reflectdir = reflect(lightdir, nor);
    float specangle = max(dot(reflectdir, camdir), 0.0);
    float specularL = pow(specangle, mat.specular.x/4.0)*mat.specular.y;
    
    return vec3(ambientL + specularL + diffuseL*shadowL) * mat.albedo * mat.specularColour;
}

vec3 calcReflection(vec3 surfpos, vec3 surfnor, vec3 camdir, vec3 lightpos){
    Material material;
    vec2 inter = intersect(surfpos + (surfnor*0.01), surfnor);
    if(inter.y > 0.5){
        vec3 pos = surfpos + inter.x*surfnor;
        vec3 nor = calcNormal(pos);
        
        if(inter.y == 1.0) material = matWhite;
        else if(inter.y == 2.0) material = matGlossy;
        else if(inter.y == 3.0) material = matGold;
        else if(inter.y == 4.0) material = matBrown;
        else if(inter.y == 5.0) material = matMirror;
        
        return calcShading(pos, nor, camdir, lightpos, material);
    }
    return texture( iChannel0, surfnor ).xyz;
}

vec3 calcMaterial(vec3 pos, vec3 nor, vec3 camdir, vec3 lightpos, Material mat){
    vec3 lightDifference = lightpos - pos;
    vec3 lightdir = normalize(lightDifference);
    float ambientL = 0.01;
    float diffuseL = dot(nor, lightdir);
    float shadowL = calcShadow(pos, lightdir, length(lightDifference));
    
    vec3 reflectdir = reflect(lightdir, nor);
    float specangle = max(dot(reflectdir, camdir), 0.0);
    float specularL = pow(specangle, mat.specular.x/4.0)*mat.specular.y;
    
    vec3 reflectL = calcReflection(pos, nor, camdir, lightpos);
    
    vec3 basec = mix(vec3(diffuseL), reflectL, mat.reflection);
    vec3 colour = ((specularL + basec)*shadowL) + ambientL;
    colour *= mat.albedo * mat.specularColour;
    return colour;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= 0.5;
    uv.x *= -iResolution.x / iResolution.y;
    
    float time  = iTime * 0.5;
    
    vec3 campos = vec3(sin(time) * 9.0, 3.0, cos(time) * 9.0);
    float camzoom = 1.0;
    vec3 lookpos = vec3(0.0, 1.0, 0.0);
    
    vec3 lookdir = normalize(lookpos - campos);
    vec3 right = normalize(cross( vec3(0.0, 1.0, 0.0), lookdir ));
    vec3 up = normalize(cross(lookdir,right));
    
    vec3 imageplanepoint = campos + (lookdir*camzoom) + (right*uv.x) + (up*uv.y);
    vec3 camdir = normalize(imageplanepoint - campos);
    
    vec3 lightpos = vec3(3.0, 4.0, 7.0) * 10.0;
    
    vec3 colour = texture( iChannel0, camdir ).xyz;
    Material material;
    
    vec2 inter = intersect(campos, camdir);
    if(inter.y > 0.5){
        vec3 pos = campos + inter.x*camdir;
        vec3 nor = calcNormal(pos);
        
        if(inter.y == 1.0) material = matWhite;
        else if(inter.y == 2.0) material = matGlossy;
        else if(inter.y == 3.0) material = matGold;
        else if(inter.y == 4.0) material = matBrown;
        else if(inter.y == 5.0) material = matMirror;
        
        colour = calcMaterial(pos, nor, camdir, lightpos, material);//*calcAmbientOcclusion(pos, nor);
        colour = pow(colour, vec3(1.0/2.2));
    }
    
    fragColor = vec4(colour,1.0);
}
