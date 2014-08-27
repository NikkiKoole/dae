import std.stdio;
import std.file;
import std.random;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
//import derelict.sdl2.mixer;
//import derelict.sdl2.ttf;
//import derelict.sdl2.net;

import derelict.util.exception;
import std.json;
import texture;

enum SCREEN_WIDTH = 800;
enum SCREEN_HEIGHT = 600;

SDL_Window* window = null;
SDL_Renderer* renderer = null;

Texture fontTexture = null;
Texture imgTexture = null;

bool loadMedia()
{
    bool success = true;
    fontTexture = new Texture(renderer, window);
    fontTexture.loadFromFile("resources/size11_0.png");
    if (fontTexture is null)
    {
        success = false;
        writeln("Error loading font texture",SDL_GetError());
    }
    auto fontFile = readText("resources/size11.fnt");
    if (fontFile is null)
    {
        success = false;
        writeln("Error loading font file");
    }
    fontTexture.makeFramesFromBMFontString(fontFile);
    
    imgTexture = new Texture(renderer, window);

    imgTexture.loadFromFile("resources/atlas/spritesheet.png");
    if (imgTexture is null){
        success = false;
        writeln("Error loading sprite texture", SDL_GetError());
    }
    auto imgSpriteSheetJSON = readText("resources/atlas/spritesheet.json");
    if (imgSpriteSheetJSON is null) {
        success = false;
        writeln("Error loading spritesheet json", SDL_GetError());
    }
    imgTexture.makeFramesFromAtlas(parseJSON(imgSpriteSheetJSON));
    return success;
}


bool init()
{
    bool success = true;

    if( SDL_Init( SDL_INIT_VIDEO ) < 0 )
    {
        writeln( "SDL could not initialize! SDL_Error: ", SDL_GetError() );
        success = false;
    }
    else
    {
        if (!SDL_SetHint( SDL_HINT_RENDER_SCALE_QUALITY, "1"))
        {
            writeln( "Warning: Linear texture filtering not enabled!" );
        }

        window = SDL_CreateWindow( "SDL Tutorial",
                                   SDL_WINDOWPOS_UNDEFINED, 
                                   SDL_WINDOWPOS_UNDEFINED, 
                                   SCREEN_WIDTH, 
                                   SCREEN_HEIGHT, 
                                   SDL_WINDOW_SHOWN );
        if( window == null )
        {
            writeln( "Window could not be created! SDL_Error: ", SDL_GetError() );
            success = false;
        }
        else
        {
            renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
            if( renderer == null )
            {
                writeln( "Renderer could not be created! SDL Error:", SDL_GetError() );
                success = false;
            } 
            else{
                //Initialize renderer color
                SDL_SetRenderDrawColor( renderer, 0xFF, 0xFF, 0xFF, 0xFF );
                
                //Initialize PNG loading
                int imgFlags = IMG_INIT_PNG;
                if( !( IMG_Init( imgFlags ) & imgFlags ) )
                {
                    writeln( "SDL_image could not initialize! SDL_image Error: ", IMG_GetError() );
                    success = false;
                }
            }
        }
    }

    return success;
}

void close()
{
    //Destroy window    
    SDL_DestroyRenderer( renderer );
    SDL_DestroyWindow( window );
    window = null;
    renderer = null;

    //Quit SDL subsystems
    //TTF_Quit();
    IMG_Quit();
    SDL_Quit();

}

void main() 
{
    DerelictSDL2.load();
    DerelictSDL2Image.load();
    //DerelictSDL2Mixer.load();
    //DerelictSDL2ttf.load();
    //DerelictSDL2Net.load();
    auto deg = 0;

    if (!init()) {
        writeln("couldn't initialize");
    }
    else
    {
        if( !loadMedia() )
        {
            writeln( "Failed to load media!" );
        }
        else
        {
            bool quit = false;
            SDL_Event e;

            while( !quit )
            {
                while( SDL_PollEvent( &e ) != 0 )
                {
                    if( e.type == SDL_QUIT )
                    {
                        quit = true;
                    }
                }





                
                //Clear screen
                SDL_SetRenderDrawColor( renderer, 0x00, 0x00, 0x00, 0xFF );
                SDL_RenderClear( renderer );
                auto str  = 
"And shall do so ever, though I took him at 's
prayers. Fare you well, my lord; and believe this
of me, there can be no kernel in this light nut; the
soul of this man is his clothes. Trust him not in
matter of heavy consequence; I have kept of them
tame, and know their natures. Farewell, monsieur:
I have spoken better of you than you have or will to
deserve at my hand; but we must do good against evil.

I shall obey his will.
You must not marvel, Helen, at my course,
Which holds not colour with the time, nor does
The ministration and required office
On my particular. Prepared I was not
For such a business; therefore am I found
So much unsettled: this drives me to entreat you
That presently you take our way for home;
And rather muse than ask why I entreat you,
For my respects are better than they seem
And my appointments have in them a need
Greater than shows itself at the first view
To you that know them not. This to my mother:
Giving a letter

'Twill be two days ere I shall see you, so
I leave you to your wisdom.";

                fontTexture.drawText(str, 10,100);
                imgTexture.drawImage("fourA0.png", 20,20, 45);
                imgTexture.drawImage("fourA1.png", 40,20, 45);
                imgTexture.drawImage("fourA2.png", 40,20, deg++ );
                imgTexture.drawImage("fourA3.png", 20,20, 45+deg);
                //Render current frame
                //gTextTexture.render( ( SCREEN_WIDTH - gTextTexture.getWidth() ) / 2, ( SCREEN_HEIGHT - gTextTexture.getHeight() ) / 2 );

                //Update screen
                SDL_RenderPresent( renderer );
            }

        }
    }

    close();
}

