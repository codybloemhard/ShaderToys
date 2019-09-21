#define VIEW_DIST 20.0

vec3 _moonPos = vec3(0.0, 1.0, 0.0);

float shapeSphere(vec3 p, vec3 pos, float r){
    return length(p - pos)-r;
}

float shapeFloor(vec3 p, float down){
    return p.y + down;
}

float shapeTorus( vec3 p, vec3 pos, vec2 t )
{
    p -= pos;
    vec2 q = vec2(length(p.xz)-t.x,p.y);    
    return (length(q)-t.y);
}
#define SHAPES 4
vec2 map(vec3 p){
    vec2 shapes[SHAPES];
    shapes[0] = vec2(shapeSphere(p, vec3(0.0,1.0,0.0), 2.0), 1.0);//base
    shapes[1] = vec2(shapeTorus(p, vec3(0.0, 1.0, 0.0), vec2(3.0, 0.07)), 2.0);  //ring2
    shapes[2] = vec2(shapeTorus(p, vec3(0.0, 1.0, 0.0), vec2(3.7, 0.03)), 2.0);  //ring2
    shapes[3] = vec2(shapeSphere(p, _moonPos, 0.15), 3.0);//moon
    
    float minf = 1000.0;
    vec2 res = shapes[0];
    for(int i = 1; i < SHAPES; i++){
        if(shapes[i].x < res.x){
            minf = shapes[i].x;
            res = shapes[i];
        }
    }
    return res;
}

vec2 sunmap(vec3 p, vec3 pos){
    vec2 s = vec2(shapeSphere(p, pos, 1.0), 1.0);
    return s;
}

vec3 calcNormal(vec3 p){
    vec3 e = vec3(0.001,0.0,0.0);
    vec3 n;
    n.x = map(p+e.xyy).x - map(p-e.xyy).x;
    n.y = map(p+e.yxy).x - map(p-e.yxy).x;
    n.z = map(p+e.yyx).x - map(p-e.yyx).x;
    return normalize(n);
}

vec2 intersect(vec3 ro, vec3 rd){
    for(float t = 0.0; t < VIEW_DIST;){
        vec2 h = map(ro + t*rd);
        if(h.x < 0.0001) return vec2(t, h.y);
        t += h.x;
    }
    return vec2(0.0);
}

vec2 sun(vec3 ro, vec3 rd, vec3 sp){
    for(float t = 0.0; t < 30.0;){
        vec2 h = sunmap(ro + t*rd, sp);
        if(h.x < 0.0001) return vec2(t, h.y);
        t += h.x;
    }
    return vec2(0.0);
}

float softShadow(vec3 ro, vec3 rd){
    float res = 1.0;
    for(float t = 0.1; t < 8.0;){
        float h = map(ro + t*rd).x;
        if(h < 0.001) return 0.0;
        res = min(res, 8.0*h/t);
        t += h;
    }
    return res;
}

//noise functions by IQ (changed it a bit)
float hash( float n )
{
    return fract(sin(n)*4121.15393);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*157.0 + 113.0*p.z;

    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}

float fbm( vec3 p, float hardness, float n0, float n1, float n2, float n3, float n4)
{
    float f = 0.0;
    p = p*hardness;
    f += n0*noise( p ); p = p*2.02;
    f += n1*noise( p ); p = p*3.03;
    f += n2*noise( p ); p = p*3.01;
    f += n3*noise( p ); p = p*3.05;
    f += n4*noise( p );

    return f/0.9375;
}
//main
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //updating    
    _moonPos.x = sin(iTime * 0.01) * 5.5;
    _moonPos.z = cos(iTime * 0.01) * 5.5;
    //rendering
    vec2 uv = fragCoord.xy / iResolution.xy;    //UV
    uv -= 0.5f;                                 //set origen to be in the middle of the screen
    uv.x *= iResolution.x / iResolution.y;      //aspect ratio
    uv *= -1.0;                                 //invert space
    vec3 colour = vec3(0.0);
    
    //vec3 campos = vec3(0.0,2.0,5.0);
    //vec3 camdir = normalize(vec3(-1.0 * 2.0*uv, -1.0));
    float camdist = 8.0;
    float camspeed = 0.2;
    float camtime = 0.4*iTime*camspeed;
    //cam goes in circles around planet
    vec3 campos = 1.0 * vec3(cos(camtime)*camdist, 0.0, sin(camtime)*camdist);
    vec3 ww = normalize(vec3(0.0, 1.0, 0.0) - campos);//look at planet
    vec3 uu = normalize(cross(vec3(0.0, 1.0, 0.0), ww));
    vec3 vv = normalize(cross(ww,uu));
    vec3 camdir = normalize(uv.x*uu + uv.y*vv + 1.0*ww);
    
    vec3 lightpos = normalize(vec3(-1.0,-0.8,0.0));
    vec3 sunpos = vec3(lightpos.x, 0.0, lightpos.z);
    vec2 sunint = sun(campos, camdir, sunpos*20.0);
    if(sunint.y > 0.5){
        vec3 spos = campos + sunint.x*camdir;
        colour = dot(calcNormal(spos), sunpos) * vec3(1.0, 1.0, 0.0);
    }
    
    vec2 inter = intersect(campos, camdir);
    if(inter.y > 0.5){
        vec3 pos = campos + inter.x*camdir;
        vec3 nor = calcNormal(pos);
        
        //float ambientL = 0.5 + 0.5*nor.y;
        float diffuseL = max(0.0, dot(nor, lightpos));
        float shadowL = softShadow(pos, lightpos);       
        vec3 ambient = vec3(0.0);////there is little to none ambient light in space
        
        colour = ambient;
        
        if(inter.y == 1.0){//planet
            colour += diffuseL*1.0;//do not use shadows on this material
            vec3 mixcolour0 = vec3(0.7, 0.3, 0.3);
            vec3 mixcolour1 = vec3(0.6, 0.7, 0.8);
            vec3 mixcolour2 = vec3(0.9, 0.1, 0.1);
            float f = smoothstep( 0.35, 1.0, fbm(pos, 1.0, 0.6, 0.25, 0.125, 0.062, 0.03) );
            vec3 mixcolour = mix( mixcolour0, mixcolour1, f );
            f = smoothstep( 0.0, 1.0, fbm(pos*48.0, 1.0, 0.5, 0.25, 0.125, 0.06, 0.03) );
            f = smoothstep( 0.6,1.0,f);
            mixcolour = mix( mixcolour, mixcolour2, f*0.5 );
            colour *= mixcolour;
        }
        else if(inter.y == 2.0){//rings
            colour += diffuseL*shadowL;//use shadows on this material
            vec3 mixcolour0 = vec3(0.4, 0.5, 0.4);
            vec3 mixcolour1 = vec3(0.1, 0.2, 0.1);
            float f = smoothstep( 0.4, 1.0, fbm(pos, 1.0, 0.6, 0.25, 0.125, 0.062, 0.03) );
            vec3 mixcolour = mix( mixcolour0, mixcolour1, f );
            colour *= mixcolour;
        }
        else if(inter.y == 3.0){//moon
            colour += diffuseL*shadowL;//use shadows on this material
            vec3 mixcolour0 = vec3(0.6, 0.5, 0.4);
            vec3 mixcolour1 = vec3(0.5, 0.3, 0.2);
            float f = smoothstep( 0.0, 1.0, fbm(nor*4.0, 1.0, 0.5, 0.25, 0.125, 0.06, 0.03) );
            f = smoothstep( 0.3,1.0,f);
            vec3 mixcolour = mix( mixcolour0, mixcolour1, f*2.0 );
            colour *= mixcolour;
        }
    }
    
    fragColor = vec4(colour,1.0);
}
