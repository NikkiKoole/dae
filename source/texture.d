import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.json;
import std.ascii;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

string getValueForArgumentInLine(string argument, string line)
{
    if (!endsWith(argument, "="))
    {
        argument ~= "=";
    }
    auto indexBegin = line.indexOf(argument,0);
    auto indexEnd = line.indexOf(" ",indexBegin);
    if (indexBegin == -1 || indexEnd == -1)
    {
        return "";
    }
    return line[indexBegin .. indexEnd].split("=")[1];
}


class Texture
{
public:
    this(SDL_Renderer* r, SDL_Window* w)
    {
        window = w;
        renderer = r;
        mTexture = null;
        mWidth = 0;
        mHeight = 0;
        mPitch = 0;
        mPixels = null;
        mFrames = null;
        mLineHeight = 0;
    }
    ~this()
    {
        free();
    }
    
    bool makeFramesFromBMFontString(string BMFontFile)
    {
        auto lines = BMFontFile.split("\r\n");
        auto count = 0;
        foreach(string line ;lines)
        {
            if (count > 3)
            {
                if (startsWith(line, "char"))
                {
                    //writeln(line);
                    auto id = getValueForArgumentInLine("id",line);
                    auto x = to!int(getValueForArgumentInLine("x",line));
                    auto y = to!int(getValueForArgumentInLine("y",line));
                    auto width = to!int(getValueForArgumentInLine("width",line));
                    auto height = to!int(getValueForArgumentInLine("height",line));
                    auto xOffset = to!int(getValueForArgumentInLine("xoffset",line));
                    auto yOffset = to!int(getValueForArgumentInLine("yoffset",line));
                    auto xAdvance = to!int(getValueForArgumentInLine("xadvance",line));

                    SDL_Rect clipRectangle;
                    clipRectangle.x = x;
                    clipRectangle.y = y;
                    clipRectangle.w = width;
                    clipRectangle.h = height;
                    
                    mFrames[id] = SubFrame(clipRectangle, xOffset, yOffset, xAdvance);
                }
            }
            count+=1;
        }
        mLineHeight = to!int(getValueForArgumentInLine("lineHeight", lines[1]));
        return false;
    }
    bool makeFramesFromAtlas(JSONValue json)
    {
        foreach( string name, value; json["frames"] ){
            auto frame = value["frame"];
            auto spriteSourceSize = value["spriteSourceSize"];
            SDL_Rect clipRectangle;
            clipRectangle.x = to!int(frame["x"].toString());
            clipRectangle.y = to!int(frame["y"].toString());
            clipRectangle.w = to!int(frame["w"].toString());
            clipRectangle.h = to!int(frame["h"].toString());
            int xOffset = to!int(spriteSourceSize["x"].toString());
            int yOffset = to!int(spriteSourceSize["y"].toString());
            int xAdvance = 0;

            mFrames[name] = SubFrame(clipRectangle, xOffset, yOffset, xAdvance);

        }
        return false;
    }
    bool loadFromFile(string path) 
    {
        free();
        SDL_Texture* newTexture = null;
        SDL_Surface* loadedSurface = IMG_Load(path.ptr);    
        if (loadedSurface == null) 
        {
            writeln("Unable to load image ",path," SDL_Error: ",IMG_GetError());
        }
        else
        {
            SDL_Surface* formattedSurface = SDL_ConvertSurface(loadedSurface, SDL_GetWindowSurface(window).format, 0);
            if (formattedSurface == null)
            {
                writeln("Unable to convert surface to display format! SDL_Error: ", SDL_GetError());
            }
            else{
                newTexture = SDL_CreateTexture(renderer,
                                               SDL_GetWindowPixelFormat(window), 
                                               SDL_TEXTUREACCESS_STREAMING, 
                                               formattedSurface.w,
                                               formattedSurface.h);
                
                if (newTexture == null){
                    writeln("Unable to create blank texture! SDL_Error: ", SDL_GetError());
                }
                else {
                    SDL_LockTexture(newTexture, null, &mPixels, &mPitch);
                    memcpy(mPixels, formattedSurface.pixels, formattedSurface.pitch * formattedSurface.h);
                    SDL_UnlockTexture(newTexture);
                    mPixels = null;
                    mWidth = formattedSurface.w;
                    mHeight = formattedSurface.h;
                }
                SDL_FreeSurface(formattedSurface);
            }
            SDL_FreeSurface(loadedSurface);
        }
        mTexture = newTexture;
        return mTexture != null;
    }


    void setColor(Uint8 red, Uint8 green, Uint8 blue )
    {
        SDL_SetTextureColorMod( mTexture, red, green, blue );
    }
    void setBlendMode(SDL_BlendMode blendMode)
    {
        SDL_SetTextureBlendMode( mTexture, blendMode);
    }
    void setAlpha(Uint8 alpha)
    {
        SDL_SetTextureAlphaMod( mTexture, alpha);
    }

    void free()
    {
        if( mTexture != null )
        {
            SDL_DestroyTexture( mTexture );
            mTexture = null;
            mWidth = 0;
            mHeight = 0;
        }
    }
    void drawText(string text, int x, int y)
    {
        auto currentX = x;
        auto currentY = y;
        for (int i=0;i<text.length;i++)
        {
            
            if (to!string(text[i]) == "\n")
            {
                currentY += mLineHeight;
                currentX = x;
            } 
            else
            {
                int ascii = text[i];
                if (to!string(ascii) in mFrames){
                    SubFrame frame = mFrames[to!string(ascii)];
                    render(currentX+frame.xOffset, currentY+frame.yOffset ,&frame.clipRectangle);
                    currentX += frame.xAdvance;
                }
            
            }
        }
    }
    void drawImage(string name, int x, int y, double angle = 0.0)
    {
        if (name in mFrames)
        {
            SubFrame frame = mFrames[name];
            render(x+frame.xOffset,y+frame.yOffset,&frame.clipRectangle, angle);
        }
                       
    }
    void render(int x,int y, SDL_Rect* clip = null, double angle = 0.0, SDL_Point* center = null, SDL_RendererFlip flip = SDL_FLIP_NONE )
    {
        SDL_Rect renderQuad = { x, y, mWidth, mHeight };
   
        if( clip != null )
        {
            renderQuad.w = clip.w;
            renderQuad.h = clip.h;
        }

        SDL_RenderCopyEx( renderer, mTexture, clip, &renderQuad, angle, center, flip );
    }
    /// Dimensions
    int getWidth()
    {
        return mWidth;
    }
    int getHeight()
    {
        return mHeight;
    }
    // Pixel access
    bool lockTexture()
    {
        bool success = true;
        if (mPixels != null)
        {
            writeln("Texture is already locked!");
            success = false;
        }
        else 
        {
            if(SDL_LockTexture(mTexture, null, &mPixels, &mPitch) != 0) 
            {
                writeln("Unable to lock texture SDL_Error: ",SDL_GetError());
                success = false;
            }
        }
        return success;
    }
    bool unlockTexture() 
    {
        bool success = true;
        if (mPixels == null) 
        {
            writeln("Texture is not locked!");
            success = false;
        }
        else
        {
            SDL_UnlockTexture(mTexture);
            mPixels = null;
            mPitch = 0;
        }
        return success;
    }

    void* getPixels()
    {
        return mPixels;
    }
    int getPitch()
    {
        return mPitch;
    }

private:
    SDL_Renderer* renderer;
    SDL_Window* window;
    SDL_Texture* mTexture;
    void* mPixels;
    int mPitch;

    int mWidth;
    int mHeight;
    SubFrame[string] mFrames;
    int mLineHeight;
}

struct SubFrame
{
    SDL_Rect clipRectangle;
    int xOffset;
    int yOffset;
    int xAdvance; //only needed for fonts
}
