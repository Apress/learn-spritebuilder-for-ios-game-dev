//
// Copyright 2011 Jeff Lamarche
//
// Copyright 2012 Goffredo Marocchi
//
// Copyright 2012 Ricardo Quesada
//
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided
// that the following conditions are met:
//	1. Redistributions of source code must retain the above copyright notice, this list of conditions and
//		the following disclaimer.
//
//	2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
//		and the following disclaimer in the documentation and/or other materials provided with the
//		distribution.
//
//	THIS SOFTWARE IS PROVIDED BY THE FREEBSD PROJECT ``AS IS'' AND ANY EXPRESS OR IMPLIED
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE FREEBSD PROJECT
//	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
//	OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//	AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "CCShader_private.h"
#import "ccMacros.h"
#import "Support/CCFileUtils.h"
#import "Support/uthash.h"
#import "CCRenderer_private.h"
#import "CCTexture_private.h"
#import "CCDirector.h"
#import "CCCache.h"
#import "CCGL.h"
#import "CCRenderDispatch.h"
#import "CCMetalSupport_Private.h"


const NSString *CCShaderUniformProjection = @"cc_Projection";
const NSString *CCShaderUniformProjectionInv = @"cc_ProjectionInv";
const NSString *CCShaderUniformViewSize = @"cc_ViewSize";
const NSString *CCShaderUniformViewSizeInPixels = @"cc_ViewSizeInPixels";
const NSString *CCShaderUniformTime = @"cc_Time";
const NSString *CCShaderUniformSinTime = @"cc_SinTime";
const NSString *CCShaderUniformCosTime = @"cc_CosTime";
const NSString *CCShaderUniformRandom01 = @"cc_Random01";
const NSString *CCShaderUniformMainTexture = @"cc_MainTexture";
const NSString *CCShaderUniformNormalMapTexture = @"cc_NormalMapTexture";
const NSString *CCShaderUniformAlphaTestValue = @"cc_AlphaTestValue";


// Stringify macros
#define STR(s) #s
#define XSTR(s) STR(s)

/*
	main texture size points/pixels?
*/
static const GLchar *CCShaderHeader =
	"#ifndef GL_ES\n"
	"#define lowp\n"
	"#define mediump\n"
	"#define highp\n"
	"#endif\n\n"
	"uniform highp mat4 cc_Projection;\n"
	"uniform highp mat4 cc_ProjectionInv;\n"
	"uniform highp vec2 cc_ViewSize;\n"
	"uniform highp vec2 cc_ViewSizeInPixels;\n"
	"uniform highp vec4 cc_Time;\n"
	"uniform highp vec4 cc_SinTime;\n"
	"uniform highp vec4 cc_CosTime;\n"
	"uniform highp vec4 cc_Random01;\n\n"
	"uniform " XSTR(CC_SHADER_COLOR_PRECISION) " sampler2D cc_MainTexture;\n\n"
	"uniform " XSTR(CC_SHADER_COLOR_PRECISION) " sampler2D cc_NormalMapTexture;\n\n"
	"varying " XSTR(CC_SHADER_COLOR_PRECISION) " vec4 cc_FragColor;\n"
	"varying highp vec2 cc_FragTexCoord1;\n"
	"varying highp vec2 cc_FragTexCoord2;\n\n"
	"// End Cocos2D shader header.\n\n";

static const GLchar *CCVertexShaderHeader =
	"#ifdef GL_ES\n"
	"precision highp float;\n\n"
	"#endif\n\n"
	"#define CC_NODE_RENDER_SUBPIXEL " XSTR(CC_NODE_RENDER_SUBPIXEL) "\n"
	"attribute highp vec4 cc_Position;\n"
	"attribute highp vec2 cc_TexCoord1;\n"
	"attribute highp vec2 cc_TexCoord2;\n"
	"attribute highp vec4 cc_Color;\n\n"
	"// End Cocos2D vertex shader header.\n\n";

static const GLchar *CCFragmentShaderHeader =
	"#ifdef GL_ES\n"
	"precision " XSTR(CC_SHADER_DEFAULT_FRAGMENT_PRECISION) " float;\n"
    "#extension GL_OES_standard_derivatives : enable\n"
	"#endif\n\n"
	"// End Cocos2D fragment shader header.\n\n";

static NSString *CCDefaultVShader =
	@"void main(){\n"
	@"	gl_Position = cc_Position;\n"
	@"#if !CC_NODE_RENDER_SUBPIXEL\n"
	@"	vec2 pixelPos = (0.5*gl_Position.xy/gl_Position.w + 0.5)*cc_ViewSizeInPixels;\n"
	@"	gl_Position.xy = (2.0*floor(pixelPos)/cc_ViewSizeInPixels - 1.0)*gl_Position.w;\n"
	@"#endif\n\n"
	@"	cc_FragColor = clamp(cc_Color, 0.0, 1.0);\n"
	@"	cc_FragTexCoord1 = cc_TexCoord1;\n"
	@"	cc_FragTexCoord2 = cc_TexCoord2;\n"
	@"}\n";

typedef void (* GetShaderivFunc) (GLuint shader, GLenum pname, GLint* param);
typedef void (* GetShaderInfoLogFunc) (GLuint shader, GLsizei bufSize, GLsizei* length, GLchar* infoLog);

static BOOL
CCCheckShaderError(GLint obj, GLenum status, GetShaderivFunc getiv, GetShaderInfoLogFunc getInfoLog)
{
	GLint success;
	getiv(obj, status, &success);
	
	if(!success){
		GLint length;
		getiv(obj, GL_INFO_LOG_LENGTH, &length);
		
		char *log = (char *)alloca(length);
		getInfoLog(obj, length, NULL, log);
		
		fprintf(stderr, "Shader compile error for 0x%04X: %s\n", status, log);
		return NO;
	} else {
		return YES;
	}
}

static const GLchar *
CCShaderTypeHeader(GLenum type)
{
	switch(type){
		case GL_VERTEX_SHADER: return CCVertexShaderHeader;
		case GL_FRAGMENT_SHADER: return CCFragmentShaderHeader;
		default: NSCAssert(NO, @"Bad shader type enumeration."); return NULL;
	}
}

static GLint
CompileShader(GLenum type, const char *source)
{
	GLint shader = glCreateShader(type);
	
	const GLchar *sources[] = {
		CCShaderHeader,
		CCShaderTypeHeader(type),
		source,
	};
	
	glShaderSource(shader, 3, sources, NULL);
	glCompileShader(shader);
	
	NSCAssert(CCCheckShaderError(shader, GL_COMPILE_STATUS, glGetShaderiv, glGetShaderInfoLog), @"Error compiling shader");
	
	return shader;
}


@interface CCShaderCache : CCCache @end
@implementation CCShaderCache

-(id)createSharedDataForKey:(id<NSCopying>)key
{
#warning TODO Need Metal path here.
	NSString *shaderName = (NSString *)key;
	
	NSString *fragmentName = [shaderName stringByAppendingPathExtension:@"fsh"];
	NSString *fragmentPath = [[CCFileUtils sharedFileUtils] fullPathForFilename:fragmentName];
	NSAssert(fragmentPath, @"Failed to find '%@'.", fragmentName);
	NSString *fragmentSource = [NSString stringWithContentsOfFile:fragmentPath encoding:NSUTF8StringEncoding error:nil];
	
	NSString *vertexName = [shaderName stringByAppendingPathExtension:@"vsh"];
	NSString *vertexPath = [[CCFileUtils sharedFileUtils] fullPathForFilename:vertexName];
	NSString *vertexSource = (vertexPath ? [NSString stringWithContentsOfFile:vertexPath encoding:NSUTF8StringEncoding error:nil] : CCDefaultVShader);
	
	CCShader *shader = [[CCShader alloc] initWithVertexShaderSource:vertexSource fragmentShaderSource:fragmentSource];
	shader.debugName = @"shaderName";
	
	return shader;
}

-(id)createPublicObjectForSharedData:(id)data
{
	return [data copy];
}

@end


@implementation CCShader {
	BOOL _ownsProgram;
}

//MARK: GL Uniform Setters:

static CCGLUniformSetter
GLUniformSetFloat(NSString *name, GLint location)
{
	return ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
		NSNumber *value = shaderUniforms[name] ?: globalShaderUniforms[name] ?: @(0.0);
		NSCAssert([value isKindOfClass:[NSNumber class]], @"Shader uniform '%@' value must be wrapped in a NSNumber.", name);
		
		glUniform1f(location, value.floatValue);
	};
}

static CCGLUniformSetter
GLUniformSetVec2(NSString *name, GLint location)
{
	NSString *textureName = nil;
	bool pixelSize = [name hasSuffix:@"PixelSize"];
	if(pixelSize){
		textureName = [name substringToIndex:name.length - @"PixelSize".length];
	} else if([name hasSuffix:@"Size"]){
		textureName = [name substringToIndex:name.length - @"Size".length];
	}
	
	return ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
		NSValue *value = shaderUniforms[name] ?: globalShaderUniforms[name];
		
		// Fall back on looking up the actual texture size if the name matches a texture.
		if(value == nil && textureName){
			CCTexture *texture = shaderUniforms[textureName] ?: globalShaderUniforms[textureName];
			GLKVector2 sizeInPixels = GLKVector2Make(texture.pixelWidth, texture.pixelHeight);
			
			GLKVector2 size = GLKVector2MultiplyScalar(sizeInPixels, pixelSize ? 1.0 : 1.0/texture.contentScale);
			value = [NSValue valueWithGLKVector2:size];
		}
		
		// Finally fall back on 0.
		if(value == nil) value = [NSValue valueWithGLKVector2:GLKVector2Make(0.0f, 0.0f)];
		
		NSCAssert([value isKindOfClass:[NSValue class]], @"Shader uniform '%@' value must be wrapped in a NSValue.", name);
		
		if(strcmp(value.objCType, @encode(GLKVector2)) == 0){
			GLKVector2 v; [value getValue:&v];
			glUniform2f(location, v.x, v.y);
		} else if(strcmp(value.objCType, @encode(CGPoint)) == 0){
			CGPoint v = {}; [value getValue:&v];
			glUniform2f(location, v.x, v.y);
		} else if(strcmp(value.objCType, @encode(CGSize)) == 0){
			CGSize v = {}; [value getValue:&v];
			glUniform2f(location, v.width, v.height);
		} else {
			NSCAssert(NO, @"Shader uniformm 'vec2 %@' value must be passed using [NSValue valueWithGLKVector2:], [NSValue valueWithCGPoint:], or [NSValue valueWithCGSize:]", name);
		}
	};
}

static CCGLUniformSetter
GLUniformSetVec3(NSString *name, GLint location)
{
	return ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
		NSValue *value = shaderUniforms[name] ?: globalShaderUniforms[name] ?: [NSValue valueWithGLKVector3:GLKVector3Make(0.0f, 0.0f, 0.0f)];
		NSCAssert([value isKindOfClass:[NSValue class]], @"Shader uniform '%@' value must be wrapped in a NSValue.", name);
		NSCAssert(strcmp(value.objCType, @encode(GLKVector3)) == 0, @"Shader uniformm 'vec3 %@' value must be passed using [NSValue valueWithGLKVector3:]", name);
		
		GLKVector3 v; [value getValue:&v];
		glUniform3f(location, v.x, v.y, v.z);
	};
}

static CCGLUniformSetter
GLUniformSetVec4(NSString *name, GLint location)
{
	return ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
		NSValue *value = shaderUniforms[name] ?: globalShaderUniforms[name] ?: [NSValue valueWithGLKVector4:GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f)];
		
		if([value isKindOfClass:[NSValue class]]){
			NSCAssert(strcmp([(NSValue *)value objCType], @encode(GLKVector4)) == 0, @"Shader uniformm 'vec4 %@' value must be passed using [NSValue valueWithGLKVector4:].", name);
			
			GLKVector4 v; [value getValue:&v];
			glUniform4f(location, v.x, v.y, v.z, v.w);
		} else if([value isKindOfClass:[CCColor class]]){
			GLKVector4 v = [(CCColor *)value glkVector4];
			glUniform4f(location, v.x, v.y, v.z, v.w);
		} else {
			NSCAssert(NO, @"Shader uniformm 'vec4 %@' value must be passed using [NSValue valueWithGLKVector4:] or a CCColor object.", name);
		}
	};
}

static CCGLUniformSetter
GLUniformSetMat4(NSString *name, GLint location)
{
	return ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
		NSValue *value = shaderUniforms[name] ?: globalShaderUniforms[name] ?: [NSValue valueWithGLKMatrix4:GLKMatrix4Identity];
		NSCAssert([value isKindOfClass:[NSValue class]], @"Shader uniform '%@' value must be wrapped in a NSValue.", name);
		NSCAssert(strcmp(value.objCType, @encode(GLKMatrix4)) == 0, @"Shader uniformm 'mat4 %@' value must be passed using [NSValue valueWithGLKMatrix4:]", name);
		
		GLKMatrix4 m; [value getValue:&m];
		glUniformMatrix4fv(location, 1, GL_FALSE, m.m);
	};
}

static NSDictionary *
GLUniformSettersForProgram(GLuint program)
{
	NSMutableDictionary *uniformSetters = [NSMutableDictionary dictionary];
	
	glUseProgram(program);
	
	GLint count = 0;
	glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &count);
	
	int textureUnit = 0;
	
	for(int i=0; i<count; i++){
		GLchar cname[256];
		GLsizei length = 0;
		GLsizei size = 0;
		GLenum type = 0;
		
		glGetActiveUniform(program, i, sizeof(cname), &length, &size, &type, cname);
		NSCAssert(size == 1, @"Uniform arrays not supported. (yet?)");
		
		NSString *name = @(cname);
		GLint location = glGetUniformLocation(program, cname);
		
		// Setup a block that is responsible for binding that uniform variable's value.
		switch(type){
			default: NSCAssert(NO, @"Uniform type not supported. (yet?)");
			case GL_FLOAT: uniformSetters[name] = GLUniformSetFloat(name, location); break;
			case GL_FLOAT_VEC2: uniformSetters[name] = GLUniformSetVec2(name, location); break;
			case GL_FLOAT_VEC3: uniformSetters[name] = GLUniformSetVec3(name, location); break;
			case GL_FLOAT_VEC4: uniformSetters[name] = GLUniformSetVec4(name, location); break;
			case GL_FLOAT_MAT4: uniformSetters[name] = GLUniformSetMat4(name, location); break;
			case GL_SAMPLER_2D: {
				// Sampler setters are handled a differently since the real work is binding the texture and not setting the uniform value.
				uniformSetters[name] = ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
					CCTexture *texture = shaderUniforms[name] ?: globalShaderUniforms[name] ?: [CCTexture none];
					NSCAssert([texture isKindOfClass:[CCTexture class]], @"Shader uniform '%@' value must be a CCTexture object.", name);
					
					// Bind the texture to the texture unit for the uniform.
					glActiveTexture(GL_TEXTURE0 + textureUnit);
					glBindTexture(GL_TEXTURE_2D, texture.name);
				};
				
				// Bind the texture unit at init time.
				glUniform1i(location, textureUnit);
				textureUnit++;
			}
		}
	}
	
	return uniformSetters;
}

//MARK: Init Methods:

-(instancetype)initWithGLProgram:(GLuint)program uniformSetters:(NSDictionary *)uniformSetters ownsProgram:(BOOL)ownsProgram
{
	NSAssert([CCConfiguration sharedConfiguration].graphicsAPI == CCGraphicsAPIGL, @"GL graphics not configured.");
	
	if((self = [super init])){
		_program = program;
		_uniformSetters = uniformSetters;
		_ownsProgram = ownsProgram;
	}
	
	return self;
}

#if __CC_METAL_SUPPORTED_AND_ENABLED
-(instancetype)initWithMetalVertexFunction:(id<MTLFunction>)vertexFunction fragmentFunction:(id<MTLFunction>)fragmentFunction
{
	if((self = [super init])){
		_vertexFunction = vertexFunction;
		_fragmentFunction = fragmentFunction;
		
		#warning TODO setup _uniformSetters
//		_uniformSetters = uniformSetters;
	}
	
	return self;
}
#endif

-(instancetype)initWithVertexShaderSource:(NSString *)vertexSource fragmentShaderSource:(NSString *)fragmentSource
{
	#warning TODO
	if([CCConfiguration sharedConfiguration].graphicsAPI == CCGraphicsAPIMetal) return self;
	
	__block typeof(self) blockself = self;
	
	CCRenderDispatch(NO, ^{
		CCGL_DEBUG_PUSH_GROUP_MARKER("CCShader: Init");
		
		GLuint program = glCreateProgram();
		glBindAttribLocation(program, CCShaderAttributePosition, "cc_Position");
		glBindAttribLocation(program, CCShaderAttributeTexCoord1, "cc_TexCoord1");
		glBindAttribLocation(program, CCShaderAttributeTexCoord2, "cc_TexCoord2");
		glBindAttribLocation(program, CCShaderAttributeColor, "cc_Color");
		
		GLint vshader = CompileShader(GL_VERTEX_SHADER, vertexSource.UTF8String);
		glAttachShader(program, vshader);
		
		GLint fshader = CompileShader(GL_FRAGMENT_SHADER, fragmentSource.UTF8String);
		glAttachShader(program, fshader);
		
		glLinkProgram(program);
		NSCAssert(CCCheckShaderError(program, GL_LINK_STATUS, glGetProgramiv, glGetProgramInfoLog), @"Error linking shader program");
		
		glDeleteShader(vshader);
		glDeleteShader(fshader);
		
		CCGL_DEBUG_POP_GROUP_MARKER();
		
		blockself = [blockself initWithGLProgram:program uniformSetters:GLUniformSettersForProgram(program) ownsProgram:YES];
	});
	
	return blockself;
}

-(instancetype)initWithFragmentShaderSource:(NSString *)source
{
	return [self initWithVertexShaderSource:CCDefaultVShader fragmentShaderSource:source];
}

- (void)dealloc
{
	CCLOGINFO( @"cocos2d: deallocing %@", self);

	GLuint program = _program;
	if(_ownsProgram && program){
		CCRenderDispatch(YES, ^{
			glDeleteProgram(program);
		});
	}
}

-(instancetype)copyWithZone:(NSZone *)zone
{
	return [[CCShader allocWithZone:zone] initWithGLProgram:_program uniformSetters:_uniformSetters ownsProgram:NO];
}

static CCShaderCache *CC_SHADER_CACHE = nil;
static CCShader *CC_SHADER_POS_COLOR = nil;
static CCShader *CC_SHADER_POS_TEX_COLOR = nil;
static CCShader *CC_SHADER_POS_TEXA8_COLOR = nil;
static CCShader *CC_SHADER_POS_TEX_COLOR_ALPHA_TEST = nil;

+(void)initialize
{
	// +initialize may be called due to loading a subclass.
	if(self != [CCShader class]) return;
	
	NSAssert([CCConfiguration sharedConfiguration].graphicsAPI != CCGraphicsAPIInvalid, @"Graphics API not configured.");
	
#if __CC_METAL_SUPPORTED_AND_ENABLED
	if([CCConfiguration sharedConfiguration].graphicsAPI == CCGraphicsAPIMetal){
		id<MTLLibrary> library = [CCMetalContext currentContext].library;
		id<MTLFunction> vertex = [library newFunctionWithName:@"CCVertexFunctionDefault"];
		
		CC_SHADER_POS_COLOR = [[self alloc] initWithMetalVertexFunction:vertex fragmentFunction:[library newFunctionWithName:@"CCFragmentFunctionDefaultColor"]];
		CC_SHADER_POS_COLOR.debugName = @"CCPositionColorShader";
		
		CC_SHADER_POS_TEX_COLOR = [[self alloc] initWithMetalVertexFunction:vertex fragmentFunction:[library newFunctionWithName:@"CCFragmentFunctionDefaultTextureColor"]];
		CC_SHADER_POS_TEX_COLOR.debugName = @"CCPositionTextureColorShader";
		
		CC_SHADER_POS_TEXA8_COLOR = [[self alloc] initWithMetalVertexFunction:vertex fragmentFunction:[library newFunctionWithName:@"CCFragmentFunctionDefaultTextureA8Color"]];
		CC_SHADER_POS_TEXA8_COLOR.debugName = @"CCPositionTextureA8ColorShader";
		
		CC_SHADER_POS_TEX_COLOR_ALPHA_TEST = [[self alloc] initWithMetalVertexFunction:vertex fragmentFunction:[library newFunctionWithName:@"CCFragmentFunctionUnsupported"]];
		CC_SHADER_POS_TEX_COLOR_ALPHA_TEST.debugName = @"CCPositionTextureColorAlphaTestShader";
	} else
#endif
	{
		CC_SHADER_CACHE = [[CCShaderCache alloc] init];
		
		// Setup the builtin shaders.
		CC_SHADER_POS_COLOR = [[self alloc] initWithFragmentShaderSource:@"void main(){gl_FragColor = cc_FragColor;}"];
		CC_SHADER_POS_COLOR.debugName = @"CCPositionColorShader";
		
		CC_SHADER_POS_TEX_COLOR = [[self alloc] initWithFragmentShaderSource:@"void main(){gl_FragColor = cc_FragColor*texture2D(cc_MainTexture, cc_FragTexCoord1);}"];
		CC_SHADER_POS_TEX_COLOR.debugName = @"CCPositionTextureColorShader";
		
		CC_SHADER_POS_TEXA8_COLOR = [[self alloc] initWithFragmentShaderSource:@"void main(){gl_FragColor = cc_FragColor*texture2D(cc_MainTexture, cc_FragTexCoord1).a;}"];
		CC_SHADER_POS_TEXA8_COLOR.debugName = @"CCPositionTextureA8ColorShader";
		
		CC_SHADER_POS_TEX_COLOR_ALPHA_TEST = [[self alloc] initWithFragmentShaderSource:CC_GLSL(
			uniform float cc_AlphaTestValue;
			void main(){
				vec4 tex = texture2D(cc_MainTexture, cc_FragTexCoord1);
				if(tex.a <= cc_AlphaTestValue) discard;
				gl_FragColor = cc_FragColor*tex;
			}
		)];
		CC_SHADER_POS_TEX_COLOR_ALPHA_TEST.debugName = @"CCPositionTextureColorAlphaTestShader";
	}
}

+(instancetype)positionColorShader
{
	return CC_SHADER_POS_COLOR;
}

+(instancetype)positionTextureColorShader
{
	return CC_SHADER_POS_TEX_COLOR;
}

+(instancetype)positionTextureColorAlphaTestShader
{
	return CC_SHADER_POS_TEX_COLOR_ALPHA_TEST;
}

+(instancetype)positionTextureA8ColorShader
{
	return CC_SHADER_POS_TEXA8_COLOR;
}

+(instancetype)shaderNamed:(NSString *)shaderName
{
	return [CC_SHADER_CACHE objectForKey:shaderName];
}

@end
