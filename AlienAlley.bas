'-----------------------------------------------------------------------------------------------------------------------
'      _    _ _                 _    _ _
'     / \  | (_) ___ _ __      / \  | | | ___ _   _
'    / _ \ | | |/ _ \ '_ \    / _ \ | | |/ _ \ | | |
'   / ___ \| | |  __/ | | |  / ___ \| | |  __/ |_| |
'  /_/   \_\_|_|\___|_| |_| /_/   \_\_|_|\___|\__, |
'                                             |___/
'
'  Source port copyright (c) 2023 Samuel Gomes
'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/TimeOps.bi'
'$INCLUDE:'include/MathOps.bi'
'$INCLUDE:'include/GraphicOps.bi'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------------------------
$NOPREFIX
$COLOR:32
$ASSERTS
$UNSTABLE:MIDI
$MIDISOUNDFONT:DEFAULT
$EXEICON:'./AlienAlley.ico'
$VERSIONINFO:ProductName='Alien Alley'
$VERSIONINFO:CompanyName='Samuel Gomes'
$VERSIONINFO:LegalCopyright='Copyright (c) 2023 Samuel Gomes'
$VERSIONINFO:LegalTrademarks='All trademarks are property of their respective owners'
$VERSIONINFO:Web='https://github.com/a740g'
$VERSIONINFO:Comments='https://github.com/a740g'
$VERSIONINFO:InternalName='AlienAlley'
$VERSIONINFO:OriginalFilename='AlienAlley.exe'
$VERSIONINFO:FileDescription='Alien Alley executable'
$VERSIONINFO:FILEVERSION#=2,4,1,0
$VERSIONINFO:PRODUCTVERSION#=2,4,1,0
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------------------------
' Game constants
CONST APP_NAME = "Alien Alley"
CONST MAX_ALIENS = 4
CONST MAX_ALIEN_MISSILES = 20
CONST MAX_HERO_MISSILES = 10
CONST MAX_EXPLOSIONS = MAX_ALIENS + 1 ' +1 for hero
CONST MAX_EXPLOSION_BITMAPS = 5
CONST GUN_BLINK_RATE = 20
CONST HERO_X_VELOCITY = 3
CONST HERO_Y_VELOCITY = 3
CONST ALIEN_X_VELOCITY = 3
CONST ALIEN_Y_VELOCITY = 2
CONST HERO_MISSILE_VELOCITY = 5
CONST ALIEN_MISSILE_VELOCITY = 4
CONST ALIEN_MOVE_TIME_VAR = 50
CONST ALIEN_MOVE_TIME_BASE = 20
CONST ALIEN_GEN_RATE_BASE = 40
CONST ALIEN_GEN_RATE_VAR = 40
CONST ALIEN_FIRE_LOCKOUT = 60
CONST ALIEN_FIRE_PROB_HERO = 20
CONST ALIEN_FIRE_PROB_RANDOM = 10
CONST ALIEN_PROX_THRESHOLD = 20
CONST HERO_GUN_OFFSET_LEFT = 3
CONST HERO_GUN_OFFSET_RIGHT = 26
CONST HERO_GUN_OFFSET_UP = 10
CONST ALIEN_GUN_OFFSET_LEFT = 4
CONST ALIEN_GUN_OFFSET_RIGHT = 25
CONST ALIEN_GUN_OFFSET_DOWN = 20
CONST DEATH_DELAY = 60 ' 1 sec delay after player death
CONST POINTS_PER_ALIEN = 10
CONST SHIELD_STATUS_WIDTH = 80
CONST SHIELD_STATUS_HEIGHT = 20
CONST SHIELD_STATUS_LEFT = 192
CONST SHIELD_STATUS_TOP = 360
CONST SHIELD_STATUS_RIGHT = SHIELD_STATUS_LEFT + SHIELD_STATUS_WIDTH - 1
CONST SHIELD_STATUS_BOTTOM = SHIELD_STATUS_TOP + SHIELD_STATUS_HEIGHT - 1
CONST MAX_HERO_SHIELDS = SHIELD_STATUS_WIDTH - 1
CONST SCORE_NUMBERS_LEFT = 474
CONST SCORE_NUMBERS_TOP = 363
CONST EXPLOSION_FRAME_REPEAT_COUNT = 3
CONST HIGH_SCORE_TEXT_LEN = 20
CONST HIGH_SCORE_FILENAME = "highscore.csv"
CONST NUM_HIGH_SCORES = 10
CONST NUM_TILES = 3
CONST UPDATES_PER_SECOND = 60
' Screen parameters
CONST SCREEN_WIDTH = 640
CONST SCREEN_HEIGHT = 400
CONST STATUS_HEIGHT = 60 ' our HUD is 60 pixels now 30 * 2 in 640x400 mode
CONST REDUCED_SCREEN_HEIGHT = SCREEN_HEIGHT - STATUS_HEIGHT
' Scrolling parameters
CONST MAP_SCROLL_STEP_NORMAL = 1
CONST MAP_SCROLL_STEP_FAST = 2
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' USER DEFINED TYPES
'-----------------------------------------------------------------------------------------------------------------------
TYPE Rectangle2DType
    a AS Vector2FType
    b AS Vector2FType
END TYPE

TYPE SpriteType
    isActive AS BYTE ' is this sprite active / in use?
    size AS Vector2FType ' size of the sprite
    boundary AS Rectangle2DType ' sprite should not leave this area
    position AS Vector2FType ' (left, top) position of the sprite on the 2D plane
    velocity AS Vector2FType ' velocity of the sprite
    bDraw AS BYTE ' do we need to draw the sprite?
    objSpec1 AS LONG ' special data 1
    objSpec2 AS LONG ' special data 2
END TYPE

TYPE HighScoreType
    text AS STRING
    score AS LONG
END TYPE
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------------------------
DIM SHARED Score AS LONG
DIM SHARED HeroShields AS INTEGER
DIM SHARED HighScore(0 TO NUM_HIGH_SCORES - 1) AS HighScoreType
DIM SHARED MapScrollStep AS INTEGER ' # of pixels to scroll the background
DIM SHARED Hero AS SpriteType
DIM SHARED Alien(0 TO MAX_ALIENS - 1) AS SpriteType
DIM SHARED HeroMissile(0 TO MAX_HERO_MISSILES - 1) AS SpriteType
DIM SHARED AlienMissile(0 TO MAX_ALIEN_MISSILES - 1) AS SpriteType
DIM SHARED Explosion(0 TO MAX_EXPLOSIONS - 1) AS SpriteType
DIM SHARED HUDSize AS Vector2FType
DIM SHARED HUDDigitSize AS Vector2FType
DIM SHARED AlienGenCounter AS INTEGER
DIM SHARED GunBlinkCounter AS INTEGER
DIM SHARED GunBlinkState AS BYTE
DIM SHARED AllowHeroFire AS BYTE
' Asset global variables
DIM SHARED ExplosionSound AS LONG ' sample handle
DIM SHARED LaserSound AS LONG ' sample handle
DIM SHARED HeroBitmap(0 TO 1) AS LONG
DIM SHARED AlienBitmap(0 TO 1) AS LONG
DIM SHARED MissileBitmap AS LONG
DIM SHARED MissileTrailUpBitmap AS LONG
DIM SHARED MissileTrailDnBitmap AS LONG
DIM SHARED ExplosionBitmap(0 TO MAX_EXPLOSION_BITMAPS - 1) AS LONG
DIM SHARED TileBitmap(0 TO NUM_TILES - 1) AS LONG
DIM SHARED HUDBitmap(0 TO 1) AS LONG
DIM SHARED HUDDigitBitmap(0 TO 9) AS LONG
REDIM SHARED TileMap(0 TO 0, 0 TO 0) AS LONG ' bitmap for each tile position
REDIM SHARED TileMapY(0 TO 0) AS LONG ' the y postion of the tile row
DIM SHARED TileMapSize AS Vector2FType
DIM SHARED ShowFPS AS BYTE
DIM SHARED NoLimit AS BYTE
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - Main program loop. Inits the program, draws intro screens and title pages,
' and waits for user to hit keystroke to indicated what they want to do
'-----------------------------------------------------------------------------------------------------------------------
DIM Quit AS BYTE
DIM DrawTitle AS BYTE
DIM k AS UNSIGNED LONG

' We want the title page to show the first time
DrawTitle = TRUE
' Initialize everything we need
InitializeProgram
' Display the into credits screen
DisplayIntroCredits
' Clear keyboard and mouse
ClearInput

' Main menu loop
DO WHILE NOT Quit
    ' Draw title page (only if required)
    IF DrawTitle THEN
        DisplayTitlePage
        DrawTitle = FALSE
    END IF

    ' Get a key from the user
    k = KEYHIT

    ' Check what key was press and action it
    SELECT CASE k
        CASE KEY_ESCAPE, KEY_LOWER_Q, KEY_UPPER_Q
            Quit = TRUE

        CASE KEY_LOWER_K, KEY_UPPER_K, KEY_LOWER_M, KEY_UPPER_M, KEY_LOWER_J, KEY_UPPER_J, KEY_ENTER
            RunGame
            NewHighScore Score
            ClearInput
            DrawTitle = TRUE

        CASE KEY_LOWER_S, KEY_UPPER_S
            DisplayHighScoresScreen
            ClearInput
            DrawTitle = TRUE

        CASE KEY_F1
            ShowFPS = NOT ShowFPS

        CASE KEY_F7
            NoLimit = NOT NoLimit

        CASE ELSE
            DrawTitle = FALSE
    END SELECT
LOOP

' Fade out
Graphics_FadeScreen FALSE, UPDATES_PER_SECOND * 2, 100

' Release all resources
FinalizeProgram

SYSTEM
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------------------------

' Calculates the bounding rectangle for a sprite given its position & size
SUB GetRectangle (position AS Vector2FType, size AS Vector2FType, r AS Rectangle2DType)
    r.a.x = position.x
    r.a.y = position.y
    r.b.x = position.x + size.x - 1
    r.b.y = position.y + size.y - 1
END SUB


' Collision testing routine. This is a simple bounding box collision test
FUNCTION RectanglesCollide%% (r1 AS Rectangle2DType, r2 AS Rectangle2DType)
    RectanglesCollide = NOT (r1.a.x > r2.b.x OR r2.a.x > r1.b.x OR r1.a.y > r2.b.y OR r2.a.y > r1.b.y)
END FUNCTION


' Chear mouse and keyboard events
SUB ClearInput
    DO WHILE MOUSEINPUT
    LOOP
    KEYCLEAR
END SUB


' Loads the hero, alien, and missile sprites and initializes the sprite structures
SUB InitializeSprites
    DIM i AS INTEGER

    ' Load hero spaceship
    HeroBitmap(0) = Graphics_LoadImage("dat/gfx/hero0.pcx", FALSE, TRUE, EMPTY_STRING, Black)
    ASSERT HeroBitmap(0) < -1
    HeroBitmap(1) = Graphics_LoadImage("dat/gfx/hero1.pcx", FALSE, TRUE, EMPTY_STRING, Black)
    ASSERT HeroBitmap(1) < -1

    ' Load alien spaceship
    AlienBitmap(0) = Graphics_LoadImage("dat/gfx/alien0.pcx", FALSE, TRUE, EMPTY_STRING, Black)
    ASSERT AlienBitmap(0) < -1
    AlienBitmap(1) = Graphics_LoadImage("dat/gfx/alien1.pcx", FALSE, TRUE, EMPTY_STRING, Black)
    ASSERT AlienBitmap(1) < -1

    ' Load missile
    MissileBitmap = Graphics_LoadImage("dat/gfx/missile.pcx", FALSE, TRUE, EMPTY_STRING, Black)
    ASSERT MissileBitmap < -1

    ' Load missile trails
    MissileTrailUpBitmap = Graphics_LoadImage("dat/gfx/missiletrailup.pcx", FALSE, TRUE, EMPTY_STRING, Black)
    ASSERT MissileTrailUpBitmap < -1
    MissileTrailDnBitmap = Graphics_LoadImage("dat/gfx/missiletraildn.pcx", FALSE, TRUE, EMPTY_STRING, Black)
    ASSERT MissileTrailDnBitmap < -1

    ' Load explosion bitmaps
    FOR i = 0 TO MAX_EXPLOSION_BITMAPS - 1
        ExplosionBitmap(i) = Graphics_LoadImage("dat/gfx/explosion" + LTRIM$(STR$(i)) + ".pcx", FALSE, TRUE, EMPTY_STRING, Black)
        ASSERT ExplosionBitmap(i) < -1
    NEXT

    ' Initialize Hero sprite
    Hero.isActive = TRUE
    Hero.size.x = WIDTH(HeroBitmap(0))
    Hero.size.y = HEIGHT(HeroBitmap(0))
    Hero.boundary.a.x = 0
    Hero.boundary.a.y = 0
    Hero.boundary.b.x = SCREEN_WIDTH
    Hero.boundary.b.y = REDUCED_SCREEN_HEIGHT
    Hero.position.x = ((Hero.boundary.b.x - Hero.boundary.a.x) / 2) - Hero.size.x / 2
    Hero.position.y = ((Hero.boundary.b.y - Hero.boundary.a.y) / 2) - Hero.size.y / 2
    Hero.velocity.x = HERO_X_VELOCITY
    Hero.velocity.y = HERO_Y_VELOCITY
    Hero.bDraw = TRUE

    ' Initialize alien sprites
    FOR i = 0 TO MAX_ALIENS - 1
        Alien(i).isActive = FALSE
        Alien(i).size.x = WIDTH(AlienBitmap(0))
        Alien(i).size.y = HEIGHT(AlienBitmap(0))
        Alien(i).boundary.a.x = 0
        Alien(i).boundary.b.x = SCREEN_WIDTH
        Alien(i).bDraw = FALSE
    NEXT

    ' Initialize alien missiles
    FOR i = 0 TO MAX_ALIEN_MISSILES - 1
        AlienMissile(i).isActive = FALSE
        AlienMissile(i).size.x = WIDTH(MissileBitmap)
        AlienMissile(i).size.y = HEIGHT(MissileBitmap)
        AlienMissile(i).objSpec1 = WIDTH(MissileTrailUpBitmap) ' Store these here
        AlienMissile(i).objSpec2 = HEIGHT(MissileTrailUpBitmap) ' Store these here
        AlienMissile(i).bDraw = FALSE
    NEXT

    ' Initialize hero missiles
    FOR i = 0 TO MAX_HERO_MISSILES - 1
        HeroMissile(i).isActive = FALSE
        HeroMissile(i).size.x = WIDTH(MissileBitmap)
        HeroMissile(i).size.y = HEIGHT(MissileBitmap)
        HeroMissile(i).objSpec1 = WIDTH(MissileTrailUpBitmap) ' Store these here
        HeroMissile(i).objSpec2 = HEIGHT(MissileTrailUpBitmap) ' Store these here
        HeroMissile(i).bDraw = FALSE
    NEXT

    ' Initialize explosions
    FOR i = 0 TO MAX_EXPLOSIONS - 1
        Explosion(i).isActive = FALSE
        Explosion(i).size.x = WIDTH(ExplosionBitmap(0))
        Explosion(i).size.y = HEIGHT(ExplosionBitmap(0))
        Explosion(i).bDraw = FALSE
    NEXT

    ' Set up gun blink stuff
    GunBlinkCounter = GUN_BLINK_RATE
    GunBlinkState = 1
END SUB


' Frees the memory occupied by the sprites
SUB FinalizeSprites
    DIM i AS INTEGER

    FOR i = 0 TO MAX_EXPLOSION_BITMAPS - 1
        FREEIMAGE ExplosionBitmap(i)
    NEXT

    FREEIMAGE MissileTrailDnBitmap
    FREEIMAGE MissileTrailUpBitmap
    FREEIMAGE MissileBitmap
    FREEIMAGE AlienBitmap(0)
    FREEIMAGE AlienBitmap(1)
    FREEIMAGE HeroBitmap(0)
    FREEIMAGE HeroBitmap(1)
END SUB


' Updates the "UserInput..." variables used by the MoveSprites routine from supported input devices
' Return TRUE if ESC was pressed
' TODO: Add game controller support
FUNCTION GetInput%% (UserInputUp AS BYTE, UserInputDown AS BYTE, UserInputLeft AS BYTE, UserInputRight AS BYTE, UserInputFire AS BYTE)
    DIM mouseMovement AS Vector2FType
    DIM mouseFire AS BYTE

    ' Collect and aggregate mouse input
    ' The mouse should not give undue advantage
    DO WHILE MOUSEINPUT
        mouseMovement.x = mouseMovement.x + MOUSEMOVEMENTX
        mouseMovement.y = mouseMovement.y + MOUSEMOVEMENTY
        mouseFire = mouseFire OR MOUSEBUTTON(1) OR MOUSEBUTTON(2) OR MOUSEBUTTON(3)
    LOOP

    UserInputLeft = (mouseMovement.x < 0) OR KEYDOWN(KEY_LEFT_ARROW) OR KEYDOWN(KEY_UPPER_A) OR KEYDOWN(KEY_LOWER_A)
    UserInputRight = (mouseMovement.x > 0) OR KEYDOWN(KEY_RIGHT_ARROW) OR KEYDOWN(KEY_UPPER_D) OR KEYDOWN(KEY_LOWER_D)
    UserInputUp = (mouseMovement.y < 0) OR KEYDOWN(KEY_UP_ARROW) OR KEYDOWN(KEY_UPPER_W) OR KEYDOWN(KEY_LOWER_W)
    UserInputDown = (mouseMovement.y > 0) OR KEYDOWN(KEY_DOWN_ARROW) OR KEYDOWN(KEY_UPPER_S) OR KEYDOWN(KEY_LOWER_S)
    UserInputFire = mouseFire OR KEYDOWN(KEY_SPACE) OR KEYDOWN(KEY_LEFT_CONTROL) OR KEYDOWN(KEY_RIGHT_CONTROL) OR KEYDOWN(KEY_LEFT_ALT) OR KEYDOWN(KEY_RIGHT_ALT)

    GetInput = KEYDOWN(KEY_ESCAPE)
END FUNCTION


' Finds a non-active hero missile in the HeroMissile array and initializes it
' Return TRUE if it was successful
FUNCTION CreateHeroMissile%% (x AS INTEGER, y AS INTEGER)
    DIM i AS INTEGER

    FOR i = 0 TO MAX_HERO_MISSILES - 1
        IF NOT HeroMissile(i).isActive THEN
            HeroMissile(i).isActive = TRUE
            HeroMissile(i).position.x = x
            HeroMissile(i).position.y = y
            HeroMissile(i).velocity.x = 0
            HeroMissile(i).velocity.y = -HERO_MISSILE_VELOCITY
            HeroMissile(i).bDraw = TRUE
            CreateHeroMissile = TRUE
            EXIT FUNCTION
        END IF
    NEXT

    CreateHeroMissile = FALSE
END FUNCTION


' Finds a free alien in the Alien array and initializes it
SUB CreateAlien
    DIM i AS INTEGER

    FOR i = 0 TO MAX_ALIENS - 1
        IF NOT Alien(i).isActive THEN
            Alien(i).isActive = TRUE
            Alien(i).position.x = RND * (SCREEN_WIDTH - Alien(i).size.x)
            Alien(i).position.y = -Alien(i).size.y
            Alien(i).velocity.x = RND * ALIEN_X_VELOCITY + 1
            Alien(i).velocity.y = RND * ALIEN_Y_VELOCITY + 1
            Alien(i).objSpec1 = ALIEN_MOVE_TIME_BASE + RND * ALIEN_MOVE_TIME_VAR
            Alien(i).objSpec2 = 0 ' ability to fire immediately
            Alien(i).bDraw = TRUE
            EXIT FOR
        END IF
    NEXT
END SUB


' Finds a free alien missile in the AlienMissile array and initializes it.
' The x and y positions of the missile are set from the x and y parameters which will place them somewhere near an alien gun.
SUB CreateAlienMissile (x AS INTEGER, y AS INTEGER)
    DIM i AS INTEGER

    FOR i = 0 TO MAX_ALIEN_MISSILES - 1
        IF NOT AlienMissile(i).isActive THEN
            AlienMissile(i).isActive = TRUE
            AlienMissile(i).position.x = x
            AlienMissile(i).position.y = y
            AlienMissile(i).velocity.x = 0
            AlienMissile(i).velocity.y = ALIEN_MISSILE_VELOCITY
            AlienMissile(i).bDraw = TRUE
            EXIT FOR
        END IF
    NEXT
END SUB


' Starts an explosion occuring at the appropriate x and y coordinates.
SUB CreateExplosion (position AS Vector2FType)
    DIM i AS INTEGER

    FOR i = 0 TO MAX_EXPLOSIONS - 1
        IF NOT Explosion(i).isActive THEN
            Explosion(i).isActive = TRUE
            Explosion(i).position = position
            Explosion(i).objSpec1 = 0 ' current explosion bitmap
            Explosion(i).objSpec2 = EXPLOSION_FRAME_REPEAT_COUNT
            Explosion(i).bDraw = TRUE
            EXIT FOR
        END IF
    NEXT
END SUB


' Loads HUD bitmaps and initialize the HUD
SUB InitializeHUD
    DIM i AS INTEGER

    ' Load the HUD bitmap
    HUDBitmap(0) = Graphics_LoadImage("dat/gfx/hud0.pcx", FALSE, TRUE, "HQ2XA", Black)
    ASSERT HUDBitmap(0) < -1
    HUDBitmap(1) = Graphics_LoadImage("dat/gfx/hud1.pcx", FALSE, TRUE, "HQ2XA", Black)
    ASSERT HUDBitmap(1) < -1

    HUDSize.x = WIDTH(HUDBitmap(0))
    HUDSize.y = HEIGHT(HUDBitmap(0))

    ' Load the digit bitmaps
    FOR i = 0 TO 9
        HUDDigitBitmap(i) = Graphics_LoadImage("dat/gfx/" + LTRIM$(STR$(i)) + ".pcx", FALSE, TRUE, "HQ2XA", Black)
        ASSERT HUDDigitBitmap(i) < -1
    NEXT
    HUDDigitSize.x = WIDTH(HUDDigitBitmap(0))
    HUDDigitSize.y = HEIGHT(HUDDigitBitmap(0))
END SUB


' Destroys the HUD
SUB FinalizeHUD
    DIM i AS INTEGER

    FOR i = 0 TO 9
        FREEIMAGE HUDDigitBitmap(i)
    NEXT

    FREEIMAGE HUDBitmap(0)
    FREEIMAGE HUDBitmap(1)
END SUB


' Draws the status area at the bottom of the screen showing the player's current score and shield strength
SUB DrawHUD
    DIM AS INTEGER i, j, w, h

    ' First draw the HUD panel onto the frame buffer. Our HUD was originally for 320 x 240; so we gotta stretch it
    PUTIMAGE (0, SCREEN_HEIGHT - HUDSize.y)-(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1), HUDBitmap(GunBlinkState)

    ' Update the shield status
    LINE (SHIELD_STATUS_LEFT, SHIELD_STATUS_TOP)-(SHIELD_STATUS_LEFT + HeroShields, SHIELD_STATUS_BOTTOM), RGB32(255 - (255 * HeroShields / MAX_HERO_SHIELDS), 255 * HeroShields / MAX_HERO_SHIELDS, 0), BF
    LINE (SHIELD_STATUS_LEFT, SHIELD_STATUS_TOP)-(SHIELD_STATUS_RIGHT, SHIELD_STATUS_BOTTOM), White, B , &B1001001001001001

    j = SCORE_NUMBERS_LEFT
    w = HUDDigitSize.x
    h = HUDDigitSize.y

    ' Render the score
    FOR i = 5 TO 0 STEP -1
        PUTIMAGE (j, SCORE_NUMBERS_TOP)-(j + w - 1, SCORE_NUMBERS_TOP + h), HUDDigitBitmap(Math_GetDigitFromLong(Score, i))
        j = j + w
    NEXT
END SUB


' Initialize the map with random tiles
SUB InitializeMap
    DIM AS LONG x, y, c

    ' Load the background tiles
    TileBitmap(0) = Graphics_LoadImage("dat/gfx/stars1.pcx", FALSE, TRUE, EMPTY_STRING, -1)
    ASSERT TileBitmap(0) < -1
    TileBitmap(1) = Graphics_LoadImage("dat/gfx/stars2.pcx", FALSE, TRUE, EMPTY_STRING, -1)
    ASSERT TileBitmap(1) < -1
    TileBitmap(2) = Graphics_LoadImage("dat/gfx/earth.pcx", FALSE, TRUE, EMPTY_STRING, -1)
    ASSERT TileBitmap(2) < -1

    TileMapSize.x = SCREEN_WIDTH \ WIDTH(TileBitmap(0))
    TileMapSize.y = SCREEN_HEIGHT \ HEIGHT(TileBitmap(0)) + 1 ' one more at the bottom for seemless scrolling

    ' Tiles (n, 0) is always placed offscreen
    REDIM TileMap(1 TO TileMapSize.x, 0 TO TileMapSize.y) AS LONG ' resize the tile map array
    REDIM TileMapY(0 TO TileMapSize.y) AS LONG ' resize the y position array

    ' Set other variables
    MapScrollStep = MAP_SCROLL_STEP_NORMAL

    ' Just set some ramdom tiles on the tile map
    FOR y = 0 TO TileMapSize.y
        FOR x = 1 TO TileMapSize.x
            ' We just need more stars and less planets
            c = RND * 256
            IF c = 128 THEN
                c = NUM_TILES - 1
            ELSE
                c = c MOD (NUM_TILES - 1)
            END IF

            TileMap(x, y) = TileBitmap(c)
        NEXT
        TileMapY(y) = HEIGHT(TileBitmap(0)) * y - HEIGHT(TileBitmap(0)) ' setup the y values for TileMapY
    NEXT
END SUB


' Destroys the background tile map stuff
SUB FinalizeMap
    DIM i AS LONG

    FOR i = 0 TO NUM_TILES - 1
        FREEIMAGE TileBitmap(i)
    NEXT
END SUB


' Scrolls the background using the backgound tiles
SUB UpdateMap
    DIM AS LONG x, y, c

    ' Shift all tiles down by "scrollstep" pixels
    FOR y = 0 TO TileMapSize.y
        TileMapY(y) = TileMapY(y) + MapScrollStep
    NEXT

    ' Check if the first row is completely on-screen and if so add a fresh row on top
    IF TileMapY(0) >= 0 THEN
        ' Shift all tiles down a row so that the last one is removed
        FOR y = TileMapSize.y TO 1 STEP -1
            TileMapY(y) = TileMapY(y - 1)

            FOR x = 1 TO TileMapSize.x
                TileMap(x, y) = TileMap(x, y - 1)
            NEXT
        NEXT

        TileMapY(0) = -HEIGHT(TileBitmap(0)) ' set the tile to render completely offscreen

        ' Generate a new row of tiles at the top of the map
        FOR x = 1 TO TileMapSize.x
            ' We just need more stars and less planets
            c = RND * 256
            IF c = 128 THEN
                c = NUM_TILES - 1
            ELSE
                c = c MOD (NUM_TILES - 1)
            END IF

            TileMap(x, 0) = TileBitmap(c)
        NEXT
    END IF
END SUB


' Draws the tile map to the frame buffer
SUB DrawMap
    DIM AS LONG x, y

    FOR y = 0 TO TileMapSize.y
        FOR x = 1 TO TileMapSize.x
            PUTIMAGE ((x - 1) * WIDTH(TileBitmap(0)), TileMapY(y)), TileMap(x, y)
        NEXT
    NEXT
END SUB


' Loads and plays a MIDI file (loops it too)
SUB PlayMIDIFile (fileName AS STRING)
    STATIC MIDIHandle AS LONG ' Sound handle

    ' Unload if there is anything previously loaded
    IF MIDIHandle > 0 THEN
        SNDSTOP MIDIHandle
        SNDCLOSE MIDIHandle
        MIDIHandle = 0
    END IF

    ' Check if the file exists
    IF fileName <> EMPTY_STRING AND FILEEXISTS(fileName) THEN
        MIDIHandle = SNDOPEN(fileName, "stream")
        ASSERT MIDIHandle > 0
        ' Loop the MIDI file
        IF MIDIHandle > 0 THEN SNDLOOP MIDIHandle
    END IF
END SUB


' Initialize sound stuff
SUB InitializeSound
    ' Load the sound effects
    ExplosionSound = SNDOPEN("dat/sfx/snd/explode.wav")
    ASSERT ExplosionSound > 0
    LaserSound = SNDOPEN("dat/sfx/snd/laser.wav")
    ASSERT LaserSound > 0
END SUB


' Close all sound related stuff and frees resources
SUB FinalizeSound
    SNDCLOSE ExplosionSound
    SNDCLOSE LaserSound

    PlayMIDIFile EMPTY_STRING ' This is will unload whatever MIDI data is there in memory
END SUB


' Centers a string on the screen
' The function calculates the correct starting column position to center the string on the screen and then draws the actual text
SUB DrawStringCenter (s AS STRING, y AS LONG, c AS UNSIGNED LONG)
    COLOR c
    PRINTSTRING ((SCREEN_WIDTH \ 2) - (PRINTWIDTH(s) \ 2), y), s
END SUB


' Displays the HighScore array on the screen.
SUB DrawHighScores
    DIM AS INTEGER i

    DrawStringCenter "####===-- HIGH SCORES --===####", 32, LemonYellow
    FOR i = 0 TO NUM_HIGH_SCORES - 1
        DrawStringCenter RIGHT$(" " + STR$(i + 1), 2) + ". " + LEFT$(HighScore(i).text + SPACE$(HIGH_SCORE_TEXT_LEN), HIGH_SCORE_TEXT_LEN) + "  " + RIGHT$(SPACE$(4) + STR$(HighScore(i).score), 5), 64 + i * 32, SkyBlue
    NEXT
END SUB


' Displays the high score screen from the title page
SUB DisplayHighScoresScreen
    ClearInput

    DO
        CLS , 0

        UpdateMap

        DrawMap
        DrawHighScores

        IF ShowFPS THEN PRINTSTRING (0, 0), STR$(Time_GetHertz) + " FPS"

        DISPLAY

        IF NOT NoLimit THEN LIMIT UPDATES_PER_SECOND

        DO WHILE MOUSEINPUT
            IF MOUSEBUTTON(1) OR MOUSEBUTTON(2) OR MOUSEBUTTON(3) THEN EXIT DO
        LOOP
    LOOP WHILE KEYHIT <= NULL
END SUB


' Manipulates the HighScore array to make room for the users score and gets the new text
SUB NewHighScore (NewScore AS LONG)
    DIM AS INTEGER i, sPos
    DIM k AS UNSIGNED INTEGER

    ' Check to see if it's really a high score
    IF NewScore <= HighScore(NUM_HIGH_SCORES - 1).score THEN EXIT SUB

    ' Start high score music
    PlayMIDIFile "dat/sfx/mus/alienend.mid"

    ' Move other scores down to make room
    FOR i = NUM_HIGH_SCORES - 2 TO 0 STEP -1
        IF NewScore > HighScore(i).score THEN
            HighScore(i + 1).text = HighScore(i).text
            HighScore(i + 1).score = HighScore(i).score
        ELSE
            EXIT FOR
        END IF
    NEXT
    i = i + 1

    ' Blank out text of correct slot
    HighScore(i).text = EMPTY_STRING
    HighScore(i).score = NewScore


    sPos = 0
    ClearInput
    COLOR DeepSkyBlue

    ' Get user text string
    DO
        CLS , 0
        UpdateMap

        DrawMap
        DrawHighScores
        PRINTSTRING (228 + sPos * 8, 64 + i * 32), CHR$(179)

        k = KEYHIT
        IF k >= KEY_SPACE AND k <= KEY_TILDE AND sPos < HIGH_SCORE_TEXT_LEN THEN
            sPos = sPos + 1
            HighScore(i).text = HighScore(i).text + CHR$(k)
        ELSEIF k = KEY_BACKSPACE AND sPos > 0 THEN
            sPos = sPos - 1
            HighScore(i).text = LEFT$(HighScore(i).text, sPos)
        END IF

        IF ShowFPS THEN PRINTSTRING (0, 0), STR$(Time_GetHertz) + " FPS"

        DISPLAY

        IF NOT NoLimit THEN LIMIT UPDATES_PER_SECOND
    LOOP WHILE k <> KEY_ENTER
END SUB


' Displays the Alien Alley title page
SUB DisplayTitlePage
    ' Start title music
    PlayMIDIFile "dat/sfx/mus/alienintro.mid"

    ' Clear screen
    CLS , 0

    ' First page of stuff
    DIM tmp AS LONG
    tmp = LOADIMAGE("dat/gfx/title.pcx", 32, "HQ2XA")
    ASSERT tmp < -1

    ' Stretch bmp to fill the screen
    PUTIMAGE (0, 0)-(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1), tmp

    FREEIMAGE tmp

    ' Fade in
    Graphics_FadeScreen TRUE, UPDATES_PER_SECOND * 2, 100
END SUB


' Displays the introduction credits
SUB DisplayIntroCredits
    ' Clear the screen
    CLS , 0

    ' First page of stuff
    DrawStringCenter "Coriolis Group Books", 192, White
    DrawStringCenter "Presents", 208, White

    Graphics_FadeScreen TRUE, UPDATES_PER_SECOND * 2, 100 ' fade in
    Graphics_FadeScreen FALSE, UPDATES_PER_SECOND * 2, 100 ' fade out

    ' Clear the screen
    CLS , 0

    ' Second page of stuff
    DrawStringCenter "A", 176, White
    DrawStringCenter "Dave Roberts", 192, White
    DrawStringCenter "Production", 208, White

    Graphics_FadeScreen TRUE, UPDATES_PER_SECOND * 2, 100 ' fade in
    Graphics_FadeScreen FALSE, UPDATES_PER_SECOND * 2, 100 ' fade out
END SUB


' Loads the high score file from disk
' If a high score file cannot be found or cannot be read, a default list of high-score entries is created
SUB LoadHighScores
    IF FILEEXISTS(HIGH_SCORE_FILENAME) THEN
        DIM i AS INTEGER
        DIM hsFile AS LONG

        ' Open the highscore file; if there is a problem load defaults
        hsFile = FREEFILE
        OPEN HIGH_SCORE_FILENAME FOR INPUT AS hsFile

        ' Read the name and the scores
        FOR i = 0 TO NUM_HIGH_SCORES - 1
            INPUT #hsFile, HighScore(i).text, HighScore(i).score
        NEXT

        ' Close file
        CLOSE hsFile
    ELSE ' Load default highscores if there is no highscore file
        HighScore(0).text = "Norman Bates"
        HighScore(0).score = 1000

        HighScore(1).text = "Darth Vader"
        HighScore(1).score = 900

        HighScore(2).text = "John McClane"
        HighScore(2).score = 800

        HighScore(3).text = "Captain Quint"
        HighScore(3).score = 700

        HighScore(4).text = "Indiana Jones"
        HighScore(4).score = 600

        HighScore(5).text = "James Bond"
        HighScore(5).score = 500

        HighScore(6).text = "Mary Poppins"
        HighScore(6).score = 400

        HighScore(7).text = "Freddy Krueger"
        HighScore(7).score = 300

        HighScore(8).text = "Jack Sparrow"
        HighScore(8).score = 200

        HighScore(9).text = "Ace Ventura"
        HighScore(9).score = 100
    END IF
END SUB


' Writes the HighScore array out to the high score file
SUB SaveHighScores
    DIM i AS INTEGER
    DIM hsFile AS LONG

    ' Open the file for writing
    hsFile = FREEFILE

    OPEN HIGH_SCORE_FILENAME FOR OUTPUT AS hsFile

    FOR i = 0 TO NUM_HIGH_SCORES - 1
        WRITE #hsFile, HighScore(i).text, HighScore(i).score
    NEXT

    CLOSE hsFile
END SUB


' This moves the sprite based on the velocity and if there is a boundary specified then keeps it confined
SUB UpdateSprite (s AS SpriteType)
    ' First move the sprite
    s.position.x = s.position.x + s.velocity.x
    s.position.y = s.position.y + s.velocity.y

    ' Next limit movement if boundary is specified
    IF s.boundary.b.x > s.boundary.a.x THEN
        IF s.position.x < s.boundary.a.x THEN s.position.x = s.boundary.a.x
        IF s.position.x > s.boundary.b.x - s.size.x THEN s.position.x = s.boundary.b.x - s.size.x
    END IF
    IF s.boundary.b.y > s.boundary.a.y THEN
        IF s.position.y < s.boundary.a.y THEN s.position.y = s.boundary.a.y
        IF s.position.y > s.boundary.b.y - s.size.y THEN s.position.y = s.boundary.b.y - s.size.y
    END IF
END SUB


' Takes care of moving hero ship and alien sprites, based on user input and their behavioral algorithms
' MoveSprites is also where missiles are generated and off-screen images are removed from play
SUB MoveSprites (UserInputUp AS BYTE, UserInputDown AS BYTE, UserInputLeft AS BYTE, UserInputRight AS BYTE, UserInputFire AS BYTE)
    DIM i AS INTEGER
    DIM AlienFireResult AS INTEGER
    DIM AlienProximity AS INTEGER

    ' First, take care of the hero
    IF UserInputUp THEN Hero.velocity.y = -HERO_Y_VELOCITY
    IF UserInputDown THEN Hero.velocity.y = HERO_Y_VELOCITY
    IF UserInputLeft THEN Hero.velocity.x = -HERO_X_VELOCITY
    IF UserInputRight THEN Hero.velocity.x = HERO_X_VELOCITY
    UpdateSprite Hero
    ' Set these to zero so that we don't keep moving
    Hero.velocity.x = 0
    Hero.velocity.y = 0

    ' Update hero missiles
    FOR i = 0 TO MAX_HERO_MISSILES - 1
        IF HeroMissile(i).bDraw THEN
            ' Update position
            UpdateSprite HeroMissile(i)
            ' Stop drawing when it's off screen
            IF HeroMissile(i).position.y < -(HeroMissile(i).size.y + HeroMissile(i).objSpec2) THEN
                HeroMissile(i).bDraw = FALSE
            END IF
        END IF
    NEXT

    ' Generate hero missiles
    IF UserInputFire AND AllowHeroFire AND Hero.bDraw THEN
        IF CreateHeroMissile(Hero.position.x + HERO_GUN_OFFSET_LEFT, Hero.position.y + HERO_GUN_OFFSET_UP) AND CreateHeroMissile(Hero.position.x + HERO_GUN_OFFSET_RIGHT, Hero.position.y + HERO_GUN_OFFSET_UP) THEN
            SNDPLAYCOPY LaserSound, , (2 * (Hero.position.x + Hero.size.x / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)
        END IF
        AllowHeroFire = FALSE
    END IF

    ' Update alien missiles
    FOR i = 0 TO MAX_ALIEN_MISSILES - 1
        IF AlienMissile(i).bDraw THEN
            ' Update position
            UpdateSprite AlienMissile(i)
            ' Stop drawing when it's off screen
            IF AlienMissile(i).position.y > (SCREEN_HEIGHT + AlienMissile(i).size.y + AlienMissile(i).objSpec2) THEN
                AlienMissile(i).bDraw = FALSE
            END IF
        END IF
    NEXT

    ' Move aliens
    FOR i = 0 TO MAX_ALIENS - 1
        IF Alien(i).bDraw THEN
            IF Alien(i).objSpec1 = 0 THEN
                ' Pick a new direction
                IF INT(TIMER) MOD 2 THEN
                    Alien(i).velocity.x = RND * ALIEN_X_VELOCITY
                ELSE
                    Alien(i).velocity.x = RND * -ALIEN_X_VELOCITY
                END IF
                Alien(i).objSpec1 = ALIEN_MOVE_TIME_BASE + RND * ALIEN_MOVE_TIME_VAR
            ELSE
                Alien(i).objSpec1 = Alien(i).objSpec1 - 1
            END IF
            ' Update alien position
            UpdateSprite Alien(i)

            ' Move alien to top when it gets to bottom
            IF Alien(i).position.y > SCREEN_HEIGHT + Alien(i).size.y THEN Alien(i).position.y = -Alien(i).size.y

            ' Generate alien missiles
            IF Alien(i).objSpec2 = 0 THEN
                AlienFireResult = RND * 100 ' in percent
                AlienProximity = Alien(i).position.x - Hero.position.x

                IF AlienProximity < 0 THEN AlienProximity = -AlienProximity

                IF ((AlienProximity < ALIEN_PROX_THRESHOLD) AND (AlienFireResult < ALIEN_FIRE_PROB_HERO)) OR (AlienFireResult < ALIEN_FIRE_PROB_RANDOM) THEN
                    CreateAlienMissile Alien(i).position.x + ALIEN_GUN_OFFSET_LEFT, Alien(i).position.y + ALIEN_GUN_OFFSET_DOWN
                    CreateAlienMissile Alien(i).position.x + ALIEN_GUN_OFFSET_RIGHT, Alien(i).position.y + ALIEN_GUN_OFFSET_DOWN
                    Alien(i).objSpec2 = ALIEN_FIRE_LOCKOUT
                    SNDPLAYCOPY LaserSound, , (2 * (Alien(i).position.x + Alien(i).size.x / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)
                END IF
            ELSE
                Alien(i).objSpec2 = Alien(i).objSpec2 - 1
            END IF
        END IF
    NEXT

    ' Generate aliens
    IF AlienGenCounter = 0 THEN
        ' Generate an alien
        CreateAlien
        ' Reinit generate counter
        AlienGenCounter = ALIEN_GEN_RATE_BASE + RND * ALIEN_GEN_RATE_VAR
    ELSE
        AlienGenCounter = AlienGenCounter - 1
    END IF

    ' Update explosions -- note, we don't really "move" them, just make the animation go
    FOR i = 0 TO MAX_EXPLOSIONS - 1
        IF Explosion(i).bDraw THEN
            IF Explosion(i).objSpec2 = 0 THEN
                Explosion(i).objSpec1 = Explosion(i).objSpec1 + 1
                Explosion(i).objSpec2 = EXPLOSION_FRAME_REPEAT_COUNT
                IF Explosion(i).objSpec1 >= MAX_EXPLOSION_BITMAPS THEN Explosion(i).bDraw = FALSE
            ELSE
                Explosion(i).objSpec2 = Explosion(i).objSpec2 - 1
            END IF
        END IF
    NEXT

    ' Check at what speed the map needs to be scrolled
    IF UserInputUp THEN MapScrollStep = MAP_SCROLL_STEP_FAST ELSE MapScrollStep = MAP_SCROLL_STEP_NORMAL
END SUB


' Check for collisions between various objects and start explosions if they collide
' Collision detection is performed between:
'   * aliens and hero
'   * aliens and hero missiles
'   * hero and alien missiles
' Note that all tests are performed between objects that are currently being drawn, not just active objects
SUB CheckCollisions
    DIM AS INTEGER i, j
    DIM AS Rectangle2DType r1, r2

    ' Check between hero and aliens
    FOR i = 0 TO MAX_ALIENS - 1
        ' Make sure both hero and alien are still being drawn
        ' They may still be active but have been removed from the screen and are just being erased
        ' If they are still onscreen, then perform a rectangle test
        GetRectangle Hero.position, Hero.size, r1
        GetRectangle Alien(i).position, Alien(i).size, r2
        IF Hero.bDraw AND Alien(i).bDraw AND RectanglesCollide(r1, r2) THEN
            Hero.bDraw = FALSE
            CreateExplosion Hero.position
            Alien(i).bDraw = FALSE
            CreateExplosion Alien(i).position
            SNDPLAYCOPY ExplosionSound, , (2 * (Alien(i).position.x + Alien(i).size.x / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)
        END IF
    NEXT

    ' Check between aliens and hero missiles
    FOR i = 0 TO MAX_ALIENS - 1
        IF NOT Alien(i).bDraw THEN CONTINUE

        FOR j = 0 TO MAX_HERO_MISSILES - 1
            ' Do similiar short circuit, mondo huge test as above
            GetRectangle Alien(i).position, Alien(i).size, r1
            GetRectangle HeroMissile(j).position, HeroMissile(j).size, r2
            IF HeroMissile(j).bDraw AND RectanglesCollide(r1, r2) THEN
                Alien(i).bDraw = FALSE
                HeroMissile(j).bDraw = FALSE
                CreateExplosion Alien(i).position
                Score = Score + POINTS_PER_ALIEN
                SNDPLAYCOPY ExplosionSound, , (2 * (Alien(i).position.x + Alien(i).size.x / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)
                EXIT FOR ' alien is destroyed
            END IF
        NEXT
    NEXT

    ' Check between hero and alien missiles
    FOR i = 0 TO MAX_ALIEN_MISSILES - 1
        ' Again, rely on short circuiting
        GetRectangle Hero.position, Hero.size, r1
        GetRectangle AlienMissile(i).position, AlienMissile(i).size, r2
        IF AlienMissile(i).bDraw AND Hero.bDraw AND RectanglesCollide(r1, r2) THEN
            AlienMissile(i).bDraw = FALSE ' destroy missile in any case
            IF HeroShields <= 0 THEN
                Hero.bDraw = FALSE
                CreateExplosion Hero.position
                SNDPLAYCOPY ExplosionSound, , (2 * (Hero.position.x + Hero.size.x / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)
                EXIT FOR ' hero is destroyed
            ELSE
                ' take away a bit of shields
                HeroShields = HeroShields - 5
                IF HeroShields < 0 THEN HeroShields = 0
            END IF
        END IF
    NEXT
END SUB


' Erase all current bitmaps from the hidden screen
' If the erasure marks the last time that the object will be erased because it is no longer being drawn, deactivate the object
FUNCTION EraseSprites%%
    DIM i AS INTEGER
    STATIC DeathCounter AS UNSIGNED INTEGER

    EraseSprites = FALSE

    ' Do player and possibly deactivate
    IF Hero.isActive THEN
        IF NOT Hero.bDraw THEN
            Hero.isActive = FALSE
            DeathCounter = DEATH_DELAY
        END IF
    END IF

    ' Erase and deactivate hero missiles
    FOR i = 0 TO MAX_HERO_MISSILES - 1
        ' Deactivate missile if we aren't going to draw or erase it anymore
        IF NOT HeroMissile(i).bDraw THEN
            HeroMissile(i).isActive = FALSE
        END IF
    NEXT

    ' Erase and deactivate aliens
    FOR i = 0 TO MAX_ALIENS - 1
        ' Deactive alien if it's been destroyed
        IF NOT Alien(i).bDraw THEN
            Alien(i).isActive = FALSE
        END IF
    NEXT

    ' Erase and deactivate alien missiles
    FOR i = 0 TO MAX_ALIEN_MISSILES - 1
        ' deactivate missile if we aren't going to draw or erase it anymore
        IF NOT AlienMissile(i).bDraw THEN
            AlienMissile(i).isActive = FALSE
        END IF
    NEXT

    ' Erase and deactivate explosions
    FOR i = 0 TO MAX_EXPLOSIONS - 1
        ' Deactivate if explosion has run its course
        IF NOT Explosion(i).bDraw THEN
            Explosion(i).isActive = FALSE
        END IF
    NEXT

    ' Hero has died - signal game over after brief delay
    IF NOT Hero.isActive THEN
        IF DeathCounter = 0 THEN
            EraseSprites = TRUE
        ELSE
            DeathCounter = DeathCounter - 1
        END IF
    END IF
END FUNCTION


' Draw all active objects that should be drawn on the screen
SUB DrawSprites
    DIM i AS INTEGER

    ' Do explosions
    FOR i = 0 TO MAX_EXPLOSIONS - 1
        IF Explosion(i).bDraw THEN
            ' draw explosion
            PUTIMAGE (Explosion(i).position.x, Explosion(i).position.y), ExplosionBitmap(Explosion(i).objSpec1)

        END IF
    NEXT

    ' Draw hero missiles
    FOR i = 0 TO MAX_HERO_MISSILES - 1
        IF HeroMissile(i).bDraw THEN
            ' Draw missile itself
            PUTIMAGE (HeroMissile(i).position.x, HeroMissile(i).position.y), MissileBitmap
            ' Draw missile trail. Remember we stored missile height in objspec2
            PUTIMAGE (HeroMissile(i).position.x, HeroMissile(i).position.y + HeroMissile(i).objSpec2), MissileTrailUpBitmap
        END IF
    NEXT

    ' Draw alien missiles
    FOR i = 0 TO MAX_ALIEN_MISSILES - 1
        IF AlienMissile(i).bDraw THEN
            ' Draw missile itself
            PUTIMAGE (AlienMissile(i).position.x, AlienMissile(i).position.y), MissileBitmap
            ' Draw missile trail. Again objspec2 has the missile height
            PUTIMAGE (AlienMissile(i).position.x, AlienMissile(i).position.y - AlienMissile(i).objSpec2), MissileTrailDnBitmap
        END IF
    NEXT

    ' Do aliens
    FOR i = 0 TO MAX_ALIENS - 1
        IF Alien(i).isActive AND Alien(i).bDraw THEN
            PUTIMAGE (Alien(i).position.x, Alien(i).position.y), AlienBitmap(GunBlinkState)
        END IF
    NEXT

    ' Do player
    IF Hero.isActive AND Hero.bDraw THEN
        PUTIMAGE (Hero.position.x, Hero.position.y), HeroBitmap(GunBlinkState)
    END IF

    ' Blink the guns
    IF GunBlinkCounter = 0 THEN
        GunBlinkState = 1 - GunBlinkState ' Flip it to other state
        GunBlinkCounter = GUN_BLINK_RATE
        AllowHeroFire = TRUE
    ELSE
        GunBlinkCounter = GunBlinkCounter - 1
    END IF
END SUB


' Performs all the program-wide initialization at start-up time
SUB InitializeProgram
    ' Initialize some stuff
    RANDOMIZE TIMER

    ' Set the Window title
    TITLE APP_NAME

    ' Load high-score file
    LoadHighScores

    ' Load sound fx and music
    InitializeSound

    ' Initialize graphics
    SCREEN NEWIMAGE(SCREEN_WIDTH, SCREEN_HEIGHT, 32)

    ' We want all text rendering to be done over the hardware screen
    DISPLAYORDER HARDWARE , HARDWARE1 , GLRENDER , SOFTWARE

    ' Set to fullscreen. We can also go to windowed mode using Alt+Enter
    FULLSCREEN SQUAREPIXELS , SMOOTH

    ' We want transparent text rendering
    PRINTMODE KEEPBACKGROUND

    ' Hide the mouse pointer
    MOUSEHIDE

    ' We want the framebuffer to be updated when we want
    DISPLAY

    ' Load game assets
    InitializeMap
END SUB


' Releases all allocated resources (use before exiting)
SUB FinalizeProgram
    ' Free memory used by assets
    FinalizeMap

    ' Set framebuffer to autoupdate
    AUTODISPLAY

    ' Release sound resources (esp. MIDI here)
    FinalizeSound

    ' Save high scores
    SaveHighScores
END SUB


' Run the game!
SUB RunGame
    DIM AS BYTE UserInputUp, UserInputDown, UserInputLeft, UserInputRight, UserInputFire, GameOver

    InitializeHUD
    InitializeSprites

    ' Initialize all counters, etc.
    Score = 0
    AlienGenCounter = ALIEN_GEN_RATE_BASE
    HeroShields = MAX_HERO_SHIELDS

    ' Play the in-game music
    PlayMIDIFile "dat/sfx/mus/alienmain.mid"

    ' Initialize some variables and enter main animation loop
    GameOver = FALSE

    ' Main game loop
    DO
        ' Get user input
        GameOver = GetInput(UserInputUp, UserInputDown, UserInputLeft, UserInputRight, UserInputFire)

        ' Move sprites
        MoveSprites UserInputUp, UserInputDown, UserInputLeft, UserInputRight, UserInputFire

        ' Check for collisions
        CheckCollisions

        ' Erase any sprites if required
        GameOver = GameOver OR EraseSprites

        ' Clear the screen
        CLS , 0

        ' Scroll screen
        UpdateMap

        ' Draw map (this will basically wipe the whole framebuffer so we do not clear anything)
        DrawMap

        ' Draw sprites
        DrawSprites

        ' Draw game HUD
        DrawHUD

        IF ShowFPS THEN PRINTSTRING (0, 0), STR$(Time_GetHertz) + " FPS"

        ' Page flip
        DISPLAY

        ' Only run the loop the number of times we want
        IF NOT NoLimit THEN LIMIT UPDATES_PER_SECOND
    LOOP WHILE NOT GameOver

    FinalizeSprites
    FinalizeHUD
END SUB
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/GraphicOps.bas'
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------
