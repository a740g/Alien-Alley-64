'-----------------------------------------------------------------------------------------------------
'      _    _ _                 _    _ _
'     / \  | (_) ___ _ __      / \  | | | ___ _   _
'    / _ \ | | |/ _ \ '_ \    / _ \ | | |/ _ \ | | |
'   / ___ \| | |  __/ | | |  / ___ \| | |  __/ |_| |
'  /_/   \_\_|_|\___|_| |_| /_/   \_\_|_|\___|\__, |
'                                             |___/
'
'  Conversion / port copyright (c) 1998-2022 Samuel Gomes
'
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------
$NoPrefix
DefLng A-Z
Option Explicit
Option ExplicitArray
Option Base 1
'$Static
$Resize:Smooth
$Color:32
$ExeIcon:'./AlienAlley.ico'
$VersionInfo:ProductName='Alien Alley'
$VersionInfo:CompanyName='Samuel Gomes'
$VersionInfo:LegalCopyright='Conversion / port copyright (c) 1998-2022 Samuel Gomes'
$VersionInfo:LegalTrademarks='All trademarks are property of their respective owners'
$VersionInfo:Web='https://github.com/a740g'
$VersionInfo:Comments='https://github.com/a740g'
$VersionInfo:InternalName='AlienAlley'
$VersionInfo:OriginalFilename='AlienAlley.exe'
$VersionInfo:FileDescription='Alien Alley executable'
$VersionInfo:FILEVERSION#=2,2,0,1
$VersionInfo:PRODUCTVERSION#=2,2,0,0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------
Const FALSE` = 0`, TRUE` = Not FALSE
Const NULL~` = 0~`
Const NULLSTRING$ = ""

' Game constants
Const APP_NAME$ = "Alien Alley"
Const MAX_ALIENS~%% = 4~%%
Const MAX_ALIEN_MISSILES~%% = 20~%%
Const MAX_HERO_MISSILES~%% = 10~%%
Const MAX_EXPLOSIONS~%% = MAX_ALIENS + 1~%% ' +1 for hero
Const MAX_EXPLOSION_BITMAPS~%% = 5~%%
Const GUN_BLINK_RATE~%% = 20~%%
Const GUN_BLINK_HERO_Y~% = 12~%
Const GUN_BLINK_HERO_X1~% = 4~%
Const GUN_BLINK_HERO_X2~% = 27~%
Const GUN_BLINK_ALIEN_Y~% = 18~%
Const GUN_BLINK_ALIEN_X1~% = 5~%
Const GUN_BLINK_ALIEN_X2~% = 26~%
Const HERO_X_VELOCITY~%% = 3~%%
Const HERO_Y_VELOCITY~%% = 3~%%
Const ALIEN_X_VELOCITY~%% = 3~%%
Const ALIEN_Y_VELOCITY~%% = 2~%%
Const HERO_MISSILE_VELOCITY~%% = 5~%%
Const ALIEN_MISSILE_VELOCITY~%% = 4~%%
Const ALIEN_MOVE_TIME_VAR~%% = 50~%%
Const ALIEN_MOVE_TIME_BASE~%% = 20~%%
Const ALIEN_GEN_RATE_BASE~%% = 40~%%
Const ALIEN_GEN_RATE_VAR~%% = 40~%%
Const ALIEN_FIRE_LOCKOUT~%% = 60~%%
Const ALIEN_FIRE_PROB_HERO~%% = 20~%%
Const ALIEN_FIRE_PROB_RANDOM~%% = 10~%%
Const ALIEN_PROX_THRESHOLD~%% = 20~%%
Const HERO_GUN_OFFSET_LEFT~%% = 3~%%
Const HERO_GUN_OFFSET_RIGHT~%% = 26~%%
Const HERO_GUN_OFFSET_UP~%% = 10~%%
Const ALIEN_GUN_OFFSET_LEFT~%% = 4~%%
Const ALIEN_GUN_OFFSET_RIGHT~%% = 25~%%
Const ALIEN_GUN_OFFSET_DOWN~%% = 20~%%
Const DEATH_DELAY~%% = 60~%% ' 1 sec delay after player death
Const POINTS_PER_ALIEN~%% = 10~%%
Const SHIELD_STATUS_WIDTH~% = 80~%
Const SHIELD_STATUS_HEIGHT~% = 20~%
Const SHIELD_STATUS_LEFT~% = 192~%
Const SHIELD_STATUS_TOP~% = 360~%
Const SHIELD_STATUS_RIGHT~% = SHIELD_STATUS_LEFT + SHIELD_STATUS_WIDTH - 1~%
Const SHIELD_STATUS_BOTTOM~% = SHIELD_STATUS_TOP + SHIELD_STATUS_HEIGHT - 1~%
Const MAX_HERO_SHIELDS~% = SHIELD_STATUS_WIDTH - 1~%
Const SCORE_NUMBERS_LEFT~% = 474~%
Const SCORE_NUMBERS_TOP~% = 363~%
Const EXPLOSION_FRAME_REPEAT_COUNT~%% = 3~%%
Const HIGH_SCORE_TEXT_LEN~%% = 20~%%
Const HIGH_SCORE_FILENAME$ = "highscore.csv"
Const NUM_HIGH_SCORES~%% = 10~%%
Const TILE_WIDTH~% = 32~% ' in pixels
Const TILE_HEIGHT~% = 32~%
Const NUM_TILES~%% = 3~%%
Const UPDATES_PER_SECOND~%% = 60~%%
' Screen parameters
Const SCREEN_WIDTH~% = 640~%
Const SCREEN_HEIGHT~% = 400~%
Const STATUS_HEIGHT~% = 60~% ' our hud is 60 pixels now 30 * 2 in 640x400 mode
Const REDUCED_SCREEN_HEIGHT~% = SCREEN_HEIGHT - STATUS_HEIGHT
' Scrolling parameters
Const MAP_SCROLL_STEP_NORMAL~%% = 1~%%
Const MAP_SCROLL_STEP_FAST~%% = 2~%%
' Keys that we use
Const KEY_WL& = 119&
Const KEY_WU& = 87&
Const KEY_SL& = 115&
Const KEY_SU& = 83&
Const KEY_AL& = 97&
Const KEY_AU& = 65&
Const KEY_DL& = 100&
Const KEY_DU& = 68&
Const KEY_UP& = 18432&
Const KEY_DOWN& = 20480&
Const KEY_LEFT& = 19200&
Const KEY_RIGHT& = 19712&
Const KEY_SPACE& = 32&
Const KEY_LCONTROL& = 100306&
Const KEY_RCONTROL& = 100305&
Const KEY_LALT& = 100308&
Const KEY_RALT& = 100306&
Const KEY_ESC& = 27&
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' USER DEFINED TYPES
'-----------------------------------------------------------------------------------------------------
Type Vector2DType
    x As Long
    y As Long
End Type

Type RectangleType
    a As Vector2DType
    b As Vector2DType
End Type

Type SpriteType
    isActive As Byte ' is this sprite active / in use?
    size As Vector2DType ' size of the sprite
    boundary As RectangleType ' sprite should not leave this area
    position As Vector2DType ' (left, top) position of the sprite on the 2D plane
    velocity As Vector2DType ' velocity of the sprite
    bDraw As Byte ' do we need to draw the sprite?
    objSpec1 As Long ' special data 1
    objSpec2 As Long ' special data 2
End Type

Type HighScoreType
    text As String * High_score_text_len
    score As Long
End Type

Type RGBTupleType
    r As Unsigned Byte
    g As Unsigned Byte
    b As Unsigned Byte
End Type
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' EXTERNAL LIBRARIES
'-----------------------------------------------------------------------------------------------------
Declare Library "./MIDIPlayer"
    Sub MIDIInit ' Initializes stuff - call this before using the library
    Sub MIDIDone ' Frees allocated memory - this must be called once we are done with the MIDI (or else we will leak memory)
    Function MIDIRegister& (mididata As String) ' Sets up and opens the WinMM MIDI stream - mididata here is string buffer!
    Sub MIDIUnregister ' Closes the WinMM MIDI stream
    Sub MIDIPlay (ByVal looping As Long) ' Kickstarts MIDI stream playback
    Sub MIDIPause ' Pauses a MIDI stream
    Sub MIDIResume ' Resumes a paused MIDI stream
    Sub MIDIStop ' Stops playing the MIDI file - this does not free resources!
End Declare
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------
Dim Shared Score As Long
Dim Shared HeroShields As Integer
Dim Shared HighScore(0 To NUM_HIGH_SCORES - 1) As HighScoreType
Dim Shared MapLine(0 To (SCREEN_WIDTH / TILE_WIDTH) - 1) As Unsigned Byte ' each tile is 32x32. so 640 / 32 = 20 (index to Tile[])
Dim Shared MapScrollStep As Integer ' # of pixels to scroll the background
Dim Shared MapLineCounter As Integer ' this keeps track of the new tiles positions
Dim Shared Hero As SpriteType
Dim Shared Alien(0 To MAX_ALIENS - 1) As SpriteType
Dim Shared HeroMissile(0 To MAX_HERO_MISSILES - 1) As SpriteType
Dim Shared AlienMissile(0 To MAX_ALIEN_MISSILES - 1) As SpriteType
Dim Shared Explosion(0 To MAX_EXPLOSIONS - 1) As SpriteType
Dim Shared HUDSize As Vector2DType
Dim Shared HUDDigitSize As Vector2DType
Dim Shared AlienGenCounter As Integer
Dim Shared GunBlinkCounter As Integer
Dim Shared GunBlinkState As Bit
Dim Shared AllowHeroFire As Bit
' Asset global variables
Dim Shared ExplosionSound As Long ' sample handle
Dim Shared LaserSound As Long ' sample handle
Dim Shared GameMusic As Bit ' have we initialized the MIDI subsystem?
Dim Shared HeroBitmap As Long
Dim Shared AlienBitmap As Long
Dim Shared MissileBitmap As Long
Dim Shared MissileTrailUpBitmap As Long
Dim Shared MissileTrailDnBitmap As Long
Dim Shared ExplosionBitmap(0 To MAX_EXPLOSION_BITMAPS - 1) As Long
Dim Shared TileBitmap(0 To NUM_TILES - 1) As Long
Dim Shared MapBitmap As Long ' this is for the background tilemap
Dim Shared HUDBitmap As Long
Dim Shared HUDDigitBitmap(0 To 9) As Long
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - Main program loop. Inits the program, draws intro screens and title pages,
' and waits for user to hit keystroke to indicated what they want to do
'-----------------------------------------------------------------------------------------------------
Dim Quit As Bit
Dim DrawTitle As Bit
Dim k As Unsigned Integer

' We want the title page to show the first time
DrawTitle = TRUE
' Initialize everything we need
InitializeProgram
' Display the into credits screen
DisplayIntroCredits
' Clear the keyboard buffer
ClearKeyboard

' Main menu loop
While Not Quit
    ' Draw title page (only if required)
    If DrawTitle Then
        DisplayTitlePage
        DrawTitle = FALSE
    End If

    ' Get a key from the user
    k = GetKey

    ' Check what key was press and action it
    Select Case k
        Case 27, Asc("q"), Asc("Q")
            Quit = TRUE
        Case Asc("k"), Asc("K"), Asc("m"), Asc("M"), Asc("j"), Asc("J"), 13
            RunGame
            NewHighScore Score
            ClearKeyboard
            DrawTitle = TRUE
        Case Asc("s"), Asc("S")
            DisplayHighScoresScreen
            ClearKeyboard
            DrawTitle = TRUE
        Case Else
            DrawTitle = FALSE
    End Select
Wend

' Fade out
Fade TRUE
' Release all resources
FinalizeProgram

System 0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------
'  Loads a 256 color (8-bit) PCX image to a QB64 32-bit image buffer
Function LoadPCX& (fileName As String, transparentColorIndex As Integer)
    ' By default we assume a failure
    LoadPCX = -1

    ' Check if the file exists
    If Not FileExists(fileName) Then Exit Function

    ' Attempt to open the file
    Dim fileHandle As Long
    fileHandle = FreeFile

    Open fileName For Binary Access Read As fileHandle

    ' Sanity check
    If Asc(Input$(1, fileHandle)) <> 10 Then
        Close fileHandle
        Exit Function
    End If
    If Asc(Input$(1, fileHandle)) <> 5 Then
        Close fileHandle
        Exit Function
    End If
    If Asc(Input$(1, fileHandle)) <> 1 Then
        Close fileHandle
        Exit Function
    End If

    ' TODO: Support 24BPP PCX?
    If Asc(Input$(1, fileHandle)) <> 8 Then
        Close fileHandle
        Exit Function
    End If

    Dim pcxSize As Vector2DType, word As Unsigned Integer
    Get fileHandle, , word
    pcxSize.x = -(word) ' xmin
    Get fileHandle, , word
    pcxSize.y = -(word) ' ymin
    Get fileHandle, , word
    pcxSize.x = pcxSize.x + word + 1 ' xmax
    Get fileHandle, , word
    pcxSize.y = pcxSize.y + word + 1 ' ymax

    Get fileHandle, , word ' skip DPI values
    Get fileHandle, , word ' skip DPI values

    Dim c As Unsigned Byte, pal(0 To 255) As RGBTupleType
    ' Read the 16 color pallete
    For c = 0 To 15
        pal(c).r = Asc(Input$(1, fileHandle))
        pal(c).g = Asc(Input$(1, fileHandle))
        pal(c).b = Asc(Input$(1, fileHandle))
    Next

    Get fileHandle, , c ' skip reserved byte

    ' How many color planes?
    If Asc(Input$(1, fileHandle)) <> 1 Then
        Close fileHandle
        Exit Function
    End If

    Dim bytesPerLine As Unsigned Integer
    Get fileHandle, , bytesPerLine

    ' Skip some more junk - (54 + (3 * 2)) / sizeof(word)
    For c = 1 To 30
        Get fileHandle, , word
    Next

    Dim As Unsigned Integer x, y
    Dim ch As Unsigned Byte
    Dim img(0 To pcxSize.x - 1, 0 To pcxSize.y - 1) As Unsigned Byte
    ' Read RLE encoded PCX data
    For y = 0 To pcxSize.y - 1
        x = 0
        While x < bytesPerLine
            ch = Asc(Input$(1, fileHandle))
            If (ch And &HC0) = &HC0 Then
                c = ch And &H3F
                ch = Asc(Input$(1, fileHandle))
            Else
                c = 1
            End If

            While c > 0
                If x < pcxSize.x Then img(x, y) = ch
                x = x + 1
                c = c - 1
            Wend
        Wend
    Next

    ' Read in the 256 color pallette
    If Asc(Input$(1, fileHandle)) = 12 Then
        For c = 0 To 255
            pal(c).r = Asc(Input$(1, fileHandle))
            pal(c).g = Asc(Input$(1, fileHandle))
            pal(c).b = Asc(Input$(1, fileHandle))
        Next
    End If

    Dim bmp As Long
    ' Create an empty bitmap
    bmp = NewImage(pcxSize.x, pcxSize.y, 32)
    If bmp >= -1 Then
        Close fileHandle
        Exit Function
    End If

    Dim oldDest As Long
    oldDest = Dest
    ' Now assemble the data into the QB64 image buffer
    ' We should probably do this with a mem ptr
    Dest bmp
    For y = 0 To pcxSize.y - 1
        For x = 0 To pcxSize.x - 1
            c = img(x, y)
            If c = transparentColorIndex Then
                PSet (x, y), RGB32(pal(c).r, pal(c).g, pal(c).b, 0)
            Else
                PSet (x, y), RGB32(pal(c).r, pal(c).g, pal(c).b, 255)
            End If
        Next
    Next
    Dest oldDest

    Close fileHandle
    LoadPCX = bmp
End Function


' Calculates the bounding rectangle for a sprite given its position & size
Sub GetRectangle (position As Vector2DType, size As Vector2DType, r As RectangleType)
    r.a.x = position.x
    r.a.y = position.y
    r.b.x = position.x + size.x - 1
    r.b.y = position.y + size.y - 1
End Sub


' Collision testing routine. This is a simple bounding box collision test
Function RectanglesCollide` (r1 As RectangleType, r2 As RectangleType)
    ' Leave if the rectangle do not collide
    If r1.a.x > r2.b.x Or r2.a.x > r1.b.x Or r1.a.y > r2.b.y Or r2.a.y > r1.b.y Then
        RectanglesCollide = FALSE
        Exit Function
    End If

    RectanglesCollide = TRUE
End Function


' Get a 1 or 2 byte keycode from the keyboard buffer
Function GetKey~%
    Dim k As String, i As Byte

    k = InKey$
    i = Len(k)

    If i = 2 Then
        GetKey = 256 + Asc(k, 2)
    ElseIf i = 1 Then
        GetKey = Asc(k)
    Else
        GetKey = NULL
    End If
End Function


' Sleeps until the user presses a key on the keyboard
Sub WaitKeyPress
    Do
        Sleep
    Loop While GetKey = NULL
End Sub


' Clear the keyboard buffer
Sub ClearKeyboard
    While GetKey <> NULL
    Wend
End Sub


' Fades the screen from black
Sub Fade (bOut As Byte)
    ' Copy the whole screen to a temporary image buffer
    Dim tmp As Long
    tmp = CopyImage(0)

    Dim i As Unsigned Byte
    Dim As Unsigned Integer w, h

    w = Width(tmp) - 1
    h = Height(tmp) - 1

    For i = 0 To 255
        ' First bllit the image to the framebuffer
        PutImage (0, 0), tmp
        ' Now draw a black box over the image with changing alpha
        If bOut Then
            Line (0, 0)-(w, h), RGBA(0, 0, 0, i), BF
        Else
            Line (0, 0)-(w, h), RGBA(0, 0, 0, 255 - i), BF
        End If

        ' Flip the framebuffer
        Display
        ' Delay a bit
        Delay 0.005
    Next

    FreeImage tmp
End Sub


' Loads the hero, alien, and missile sprites and initializes the sprite structures
Sub InitializeSprites
    Dim i As Integer

    ' Load hero spaceship
    HeroBitmap = LoadPCX("dat/gfx/hero.pcx", 0)

    ' Set up gun blink stuff
    GunBlinkCounter = GUN_BLINK_RATE
    GunBlinkState = TRUE

    ' Load alien spaceship
    AlienBitmap = LoadPCX("dat/gfx/alien.pcx", 0)

    ' Load missile
    MissileBitmap = LoadPCX("dat/gfx/missile.pcx", 0)

    ' Load missile trails
    MissileTrailUpBitmap = LoadPCX("dat/gfx/missiletrail.pcx", 0)

    ' Generate and initialize the other trail
    MissileTrailDnBitmap = NewImage(Width(MissileTrailUpBitmap), Height(MissileTrailUpBitmap))
    ' Blit the missiletrailup v inverted
    PutImage (0, Height(MissileTrailUpBitmap) - 1)-(Width(MissileTrailUpBitmap) - 1, 0), MissileTrailUpBitmap, MissileTrailDnBitmap

    ' Load explosion bitmaps
    For i = 0 To MAX_EXPLOSION_BITMAPS - 1
        ExplosionBitmap(i) = LoadPCX("dat/gfx/explosion" + LTrim$(Str$(i + 1)) + ".pcx", 0) ' file names are 1 based
    Next

    ' Initialize Hero sprite
    Hero.isActive = TRUE
    Hero.size.x = Width(HeroBitmap)
    Hero.size.y = Height(HeroBitmap)
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
    For i = 0 To MAX_ALIENS - 1
        Alien(i).isActive = FALSE
        Alien(i).size.x = Width(AlienBitmap)
        Alien(i).size.y = Height(AlienBitmap)
        Alien(i).boundary.a.x = 0
        Alien(i).boundary.b.x = SCREEN_WIDTH
        Alien(i).bDraw = FALSE
    Next

    ' Initialize alien missiles
    For i = 0 To MAX_ALIEN_MISSILES - 1
        AlienMissile(i).isActive = FALSE
        AlienMissile(i).size.x = Width(MissileBitmap)
        AlienMissile(i).size.y = Height(MissileBitmap)
        AlienMissile(i).objSpec1 = Width(MissileTrailUpBitmap) ' Store these here
        AlienMissile(i).objSpec2 = Height(MissileTrailUpBitmap) ' Store these here
        AlienMissile(i).bDraw = FALSE
    Next

    ' Initialize hero missiles
    For i = 0 To MAX_HERO_MISSILES - 1
        HeroMissile(i).isActive = FALSE
        HeroMissile(i).size.x = Width(MissileBitmap)
        HeroMissile(i).size.y = Height(MissileBitmap)
        HeroMissile(i).objSpec1 = Width(MissileTrailUpBitmap) ' Store these here
        HeroMissile(i).objSpec2 = Height(MissileTrailUpBitmap) ' Store these here
        HeroMissile(i).bDraw = FALSE
    Next

    ' Initialize explosions
    For i = 0 To MAX_EXPLOSIONS - 1
        Explosion(i).isActive = FALSE
        Explosion(i).size.x = Width(ExplosionBitmap(0))
        Explosion(i).size.y = Height(ExplosionBitmap(0))
        Explosion(i).bDraw = FALSE
    Next
End Sub


' Frees the memory occupied by the sprites
Sub FinalizeSprites
    Dim i As Integer

    For i = 0 To MAX_EXPLOSION_BITMAPS - 1
        FreeImage ExplosionBitmap(i)
    Next

    FreeImage MissileTrailDnBitmap
    FreeImage MissileTrailUpBitmap
    FreeImage MissileBitmap
    FreeImage AlienBitmap
    FreeImage HeroBitmap
End Sub


' Updates the "UserInput..." variables used by the MoveSprites routine from supported input devices
' Return TRUE if ESC was pressed
' TODO: Add game controller support
Function PollInput` (UserInputUp As Byte, UserInputDown As Byte, UserInputLeft As Byte, UserInputRight As Byte, UserInputFire As Byte)
    Dim mouseMovement As Vector2DType
    Dim mouseFire As Bit

    ' Collect and aggregate mouse input
    While MouseInput
        mouseMovement.x = mouseMovement.x + MouseMovementX
        mouseMovement.y = mouseMovement.y + MouseMovementY
        mouseFire = mouseFire Or MouseButton(1) Or MouseButton(2)
    Wend

    UserInputLeft = (mouseMovement.x < 0) Or KeyDown(KEY_LEFT) Or KeyDown(KEY_AU) Or KeyDown(KEY_AL)
    UserInputRight = (mouseMovement.x > 0) Or KeyDown(KEY_RIGHT) Or KeyDown(KEY_DU) Or KeyDown(KEY_DL)
    UserInputUp = (mouseMovement.y < 0) Or KeyDown(KEY_UP) Or KeyDown(KEY_WU) Or KeyDown(KEY_WL)
    UserInputDown = (mouseMovement.y > 0) Or KeyDown(KEY_DOWN) Or KeyDown(KEY_SU) Or KeyDown(KEY_SL)
    UserInputFire = mouseFire Or KeyDown(KEY_SPACE) Or KeyDown(KEY_LCONTROL) Or KeyDown(KEY_RCONTROL) Or KeyDown(KEY_LALT) Or KeyDown(KEY_RALT)

    PollInput = KeyDown(KEY_ESC)
End Function


' Finds a non-active hero missile in the HeroMissile array and initializes it
' Return TRUE if it was successful
Function CreateHeroMissile` (x As Integer, y As Integer)
    Dim i As Integer

    For i = 0 To MAX_HERO_MISSILES - 1
        If Not HeroMissile(i).isActive Then
            HeroMissile(i).isActive = TRUE
            HeroMissile(i).position.x = x
            HeroMissile(i).position.y = y
            HeroMissile(i).velocity.x = 0
            HeroMissile(i).velocity.y = -HERO_MISSILE_VELOCITY
            HeroMissile(i).bDraw = TRUE
            CreateHeroMissile = TRUE
            Exit Function
        End If
    Next

    CreateHeroMissile = FALSE
End Function


' Finds a free alien in the Alien array and initializes it
Sub CreateAlien
    Dim i As Integer

    For i = 0 To MAX_ALIENS - 1
        If Not Alien(i).isActive Then
            Alien(i).isActive = TRUE
            Alien(i).position.x = Rnd * (SCREEN_WIDTH - Alien(i).size.x)
            Alien(i).position.y = -Alien(i).size.y
            Alien(i).velocity.x = Rnd * ALIEN_X_VELOCITY + 1
            Alien(i).velocity.y = Rnd * ALIEN_Y_VELOCITY + 1
            Alien(i).objSpec1 = ALIEN_MOVE_TIME_BASE + Rnd * ALIEN_MOVE_TIME_VAR
            Alien(i).objSpec2 = 0 ' ability to fire immediately
            Alien(i).bDraw = TRUE
            Exit For
        End If
    Next
End Sub


' Finds a free alien missile in the AlienMissile array and initializes it.
' The x and y positions of the missile are set from the x and y parameters which will place them somewhere near an alien gun.
Sub CreateAlienMissile (x As Integer, y As Integer)
    Dim i As Integer

    For i = 0 To MAX_ALIEN_MISSILES - 1
        If Not AlienMissile(i).isActive Then
            AlienMissile(i).isActive = TRUE
            AlienMissile(i).position.x = x
            AlienMissile(i).position.y = y
            AlienMissile(i).velocity.x = 0
            AlienMissile(i).velocity.y = ALIEN_MISSILE_VELOCITY
            AlienMissile(i).bDraw = TRUE
            Exit For
        End If
    Next
End Sub


' Starts an explosion occuring at the appropriate x and y coordinates.
Sub CreateExplosion (x As Integer, y As Integer)
    Dim i As Integer

    For i = 0 To MAX_EXPLOSIONS - 1
        If Not Explosion(i).isActive Then
            Explosion(i).isActive = TRUE
            Explosion(i).position.x = x
            Explosion(i).position.y = y
            Explosion(i).objSpec1 = 0 ' current explosion bitmap
            Explosion(i).objSpec2 = EXPLOSION_FRAME_REPEAT_COUNT
            Explosion(i).bDraw = TRUE
            Exit For
        End If
    Next
End Sub


' Loads HUD bitmaps and initialize the HUD
Sub InitializeHUD
    Dim i As Integer

    ' Load the HUD bitmap
    HUDBitmap = LoadPCX("dat/gfx/hud.pcx", 0)
    HUDSize.x = Width(HUDBitmap)
    HUDSize.y = Height(HUDBitmap)

    ' Load the digit bitmaps
    For i = 0 To 9
        HUDDigitBitmap(i) = LoadPCX("dat/gfx/" + LTrim$(Str$(i)) + ".pcx", 0)
    Next
    HUDDigitSize.x = Width(HUDDigitBitmap(0))
    HUDDigitSize.y = Height(HUDDigitBitmap(0))
End Sub


' Destroys the HUD
Sub FinalizeHUD
    Dim i As Integer

    For i = 0 To 9
        FreeImage HUDDigitBitmap(i)
    Next

    FreeImage HUDBitmap
End Sub


' Draws the status area at the bottom of the screen showing the player's current score and shield strength
Sub DrawHUD
    Dim ScoreText As String * 6
    Dim As Integer i, j, k, w, h

    ' First draw the HUD panel onto the frame buffer. Our HUD was originally for 320 x 240; so we gotta stretch it
    PutImage (0, SCREEN_HEIGHT - HUDSize.y * 2)-(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1), HUDBitmap

    ' Update the shield status
    Line (SHIELD_STATUS_LEFT, SHIELD_STATUS_TOP)-(SHIELD_STATUS_LEFT + HeroShields, SHIELD_STATUS_BOTTOM), RGB(255 - (255 * HeroShields / MAX_HERO_SHIELDS), 255 * HeroShields / MAX_HERO_SHIELDS, 0), BF
    Line (SHIELD_STATUS_LEFT, SHIELD_STATUS_TOP)-(SHIELD_STATUS_RIGHT, SHIELD_STATUS_BOTTOM), White, B , &B1001001001001001

    ScoreText = Right$("000000" + LTrim$(Str$(Score)), 6)
    j = SCORE_NUMBERS_LEFT
    w = HUDDigitSize.x * 2
    h = HUDDigitSize.y * 2

    ' Render the score
    For i = 1 To 6
        k = Asc(ScoreText, i) - Asc("0")
        PutImage (j, SCORE_NUMBERS_TOP)-(j + w - 1, SCORE_NUMBERS_TOP + h), HUDDigitBitmap(k)
        j = j + w
    Next
End Sub


' Initialize the map with random tiles
Sub InitializeMap
    Dim As Integer x, y, w, h, c

    ' Create the main tile buffer first
    MapBitmap = NewImage(SCREEN_WIDTH, SCREEN_HEIGHT)

    ' Load the background tiles
    TileBitmap(0) = LoadPCX("dat/gfx/stars1.pcx", -1)
    TileBitmap(1) = LoadPCX("dat/gfx/stars2.pcx", -1)
    TileBitmap(2) = LoadPCX("dat/gfx/earth.pcx", -1)

    ' Set other variables
    MapScrollStep = MAP_SCROLL_STEP_NORMAL
    MapLineCounter = -TILE_HEIGHT

    ' Just draw ramdom tiles on the background
    w = (SCREEN_WIDTH / TILE_WIDTH) - 1
    h = (SCREEN_HEIGHT / TILE_HEIGHT) - 1

    For y = 0 To h
        For x = 0 To w
            ' We just need more stars and less planets
            c = Rnd * 256
            If c = 128 Then
                c = NUM_TILES - 1
            Else
                c = c Mod 2
            End If

            ' Blit the random tile
            PutImage (x * TILE_WIDTH, y * TILE_HEIGHT), TileBitmap(c), MapBitmap
        Next
    Next
End Sub


' Destroys the background tile map stuff
Sub FinalizeMap
    Dim i As Integer

    For i = 0 To NUM_TILES - 1
        FreeImage TileBitmap(i)
    Next

    FreeImage MapBitmap
End Sub


' Scrolls the background using the backgound tiles
Sub UpdateMap
    Dim As Integer i, c

    ' Check if all new tiles are completely shown; if so reset it
    If MapLineCounter > 0 Then MapLineCounter = -TILE_HEIGHT

    ' Check if we have to generate a fresh set of tiles at the top of the map
    If MapLineCounter <= -TILE_HEIGHT Then
        ' Okay. Generate all the new tiles to be draw at the top of the map
        For i = 0 To (SCREEN_WIDTH / TILE_WIDTH) - 1
            ' We just need more stars and less planets
            c = Rnd * 256
            If c = 128 Then
                c = NUM_TILES - 1
            Else
                c = c Mod 2
            End If

            MapLine(i) = c
        Next
    End If

    ' Shift the entire background down by "scrollstep" pixels
    Dim tmp As Long
    tmp = CopyImage(MapBitmap)
    PutImage (0, MapScrollStep), tmp, MapBitmap
    FreeImage tmp

    ' Move the new tiles down by "scrollstep"
    MapLineCounter = MapLineCounter + MapScrollStep

    ' Draw the new tiles at the top
    For i = 0 To (SCREEN_WIDTH / TILE_WIDTH) - 1
        PutImage (i * TILE_WIDTH, MapLineCounter), TileBitmap(MapLine(i)), MapBitmap
    Next
End Sub


' Draws the map buffer to the frame buffer
Sub DrawMap
    PutImage (0, 0), MapBitmap
End Sub


' Loads and plays a MIDI file (loops it too)
Sub PlayMIDIFile (fileName As String)
    ' Check if the file exists
    If FileExists(fileName) Then
        ' Unload music if loaded
        If GameMusic Then
            MIDIStop
            MIDIUnregister
            MIDIDone
            GameMusic = FALSE
        End If

        Dim fh As Long
        Dim buffer As String

        ' Open the file
        fh = FreeFile
        Open fileName For Binary Access Read As fh

        ' Load the whole file into memory
        buffer = Input$(LOF(fh), fh)

        ' Close the file
        Close fh

        ' Send the buffer for parsing and preperation
        If MIDIRegister(buffer) Then
            MIDIPlay TRUE ' loop the track
            GameMusic = TRUE
        End If
    End If
End Sub


' Initialize sound stuff
Sub InitializeSound
    MIDIInit
    ' Load the sound effects
    ExplosionSound = SndOpen("dat/sfx/snd/explode.wav")
    LaserSound = SndOpen("dat/sfx/snd/laser.wav")
End Sub


' Close all sound related stuff and frees resources
Sub FinalizeSound
    SndClose ExplosionSound
    SndClose LaserSound

    If GameMusic Then
        MIDIStop
        MIDIUnregister
        MIDIDone
    End If
End Sub


' Centers a string on the screen
' The function calculates the correct starting column position to center the string on the screen and then draws the actual text
Sub DrawStringCenter (s As String, y As Integer, c As Long)
    Color c
    PrintString ((SCREEN_WIDTH / 2) - (PrintWidth(s) / 2), y), s
End Sub


' Fills in the HighScore array with some defaults.
Sub DefaultHighScores
    HighScore(0).text = "Gill Bates"
    HighScore(0).score = 1000

    HighScore(1).text = "Sam Stone"
    HighScore(1).score = 900

    HighScore(2).text = "Mad Mike"
    HighScore(2).score = 800

    HighScore(3).text = "Fanatic Joe"
    HighScore(3).score = 700

    HighScore(4).text = "Joe Dirt"
    HighScore(4).score = 600

    HighScore(5).text = "Sonic Hedgehog"
    HighScore(5).score = 500

    HighScore(6).text = "Donald Duck"
    HighScore(6).score = 400

    HighScore(7).text = "Popeye Sailor"
    HighScore(7).score = 300

    HighScore(8).text = "Flash Gordon"
    HighScore(8).score = 200

    HighScore(9).text = "John Blade"
    HighScore(9).score = 100
End Sub


' Displays the HighScore array on the screen.
Sub DrawHighScores
    Dim As Integer h, i
    Dim s As String

    UpdateMap
    DrawMap

    h = FontHeight
    DrawStringCenter "####===-- HIGH SCORES --===####", h * 2, LemonYellow
    For i = 0 To NUM_HIGH_SCORES - 1
        s = Right$(" " + Str$(i + 1), 2) + ". " + HighScore(i).text + "  " + Right$(Space$(4) + Str$(HighScore(i).score), 5)
        DrawStringCenter s, (h * 4) + i * FontHeight * 2, SkyBlue
    Next
End Sub


' Displays the high score screen from the title page
Sub DisplayHighScoresScreen
    ' Fade out
    Fade TRUE

    ' Clear screen
    Cls

    DrawHighScores

    ' Fade in
    Fade FALSE

    ClearKeyboard

    Do
        DrawHighScores

        Display
        Limit UPDATES_PER_SECOND
    Loop While GetKey = NULL

    ' Fade out
    Fade TRUE
End Sub


' Manipulates the HighScore array to make room for the users score and gets the new text
Sub NewHighScore (NewScore As Long)
    Dim As Integer i, y, x, sPos
    Dim k As Unsigned Integer

    ' Check to see if it's really a high score
    If NewScore <= HighScore(NUM_HIGH_SCORES - 1).score Then Exit Sub

    ' Start high score music
    PlayMIDIFile "dat/sfx/mus/alienend.mid"

    ' Move other scores down to make room
    For i = NUM_HIGH_SCORES - 2 To 0 Step -1
        If NewScore > HighScore(i).score Then
            HighScore(i + 1).text = HighScore(i).text
            HighScore(i + 1).score = HighScore(i).score
        Else
            Exit For
        End If
    Next
    i = i + 1

    ' Blank out text of correct slot
    HighScore(i).text = NULLSTRING
    HighScore(i).score = NewScore

    ' Clear screen
    Cls

    DrawHighScores

    ' Fade in
    Fade FALSE

    y = (FontHeight * 4) + i * FontHeight * 2
    x = 228
    sPos = 0
    ClearKeyboard
    Color DeepSkyBlue

    ' Get user text string
    Do
        DrawHighScores
        PrintString (x, y), Chr$(179)

        k = GetKey
        If k >= 32 And k <= 126 And sPos < HIGH_SCORE_TEXT_LEN Then
            Asc(HighScore(i).text, sPos + 1) = k
            sPos = sPos + 1
            x = x + FontWidth
        ElseIf k = 8 And sPos > 0 Then
            Asc(HighScore(i).text, sPos) = 32
            sPos = sPos - 1
            x = x - FontWidth
        End If

        Display
        Limit UPDATES_PER_SECOND
    Loop While k <> 13

    ' Fade to black...
    Fade TRUE
End Sub


' Displays the Alien Alley title page
Sub DisplayTitlePage
    ' Start title music
    PlayMIDIFile "dat/sfx/mus/alienintro.mid"

    ' Clear screen
    Cls

    ' First page of stuff
    Dim tmp As Long
    tmp = LoadPCX("dat/gfx/title.pcx", -1)

    ' Stretch bmp to fill the screen
    PutImage (0, 0)-(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1), tmp

    FreeImage tmp

    ' Fade in
    Fade FALSE
End Sub


' Displays the introduction credits
Sub DisplayIntroCredits
    ' Clear the screen
    Cls

    ' First page of stuff
    DrawStringCenter "Coriolis Group Books", 8 * 19, White
    DrawStringCenter "Presents", 8 * 21, White

    Fade FALSE ' fade in
    Fade TRUE ' fade out

    ' Clear the screen
    Cls

    ' Second page of stuff
    DrawStringCenter "A", 8 * 18, White
    DrawStringCenter "Dave Roberts", 8 * 20, White
    DrawStringCenter "Production", 8 * 22, White

    Fade FALSE ' fade in
    Fade TRUE ' fade out
End Sub


' Loads the high score file from disk
' If a high score file cannot be found or cannot be read, a default list of high-score entries is created
Sub LoadHighScores
    Dim i As Integer
    Dim hsFile As Long

    ' Load default highscores if there is no highscore file
    If Not FileExists(HIGH_SCORE_FILENAME) Then
        DefaultHighScores
        Exit Sub
    End If

    ' Open the highscore file; if there is a problem load defaults
    hsFile = FreeFile
    Open HIGH_SCORE_FILENAME For Input As hsFile

    ' Read the name and the scores
    For i = 0 To NUM_HIGH_SCORES - 1
        Input #hsFile, HighScore(i).text, HighScore(i).score
    Next

    ' Close file
    Close hsFile
End Sub


' Writes the HighScore array out to the high score file
Sub SaveHighScores
    Dim i As Integer
    Dim hsFile As Long

    ' Open the file for writing
    hsFile = FreeFile

    Open HIGH_SCORE_FILENAME For Output As hsFile

    For i = 0 To NUM_HIGH_SCORES - 1
        Write #hsFile, HighScore(i).text, HighScore(i).score
    Next

    Close hsFile
End Sub


' This moves the sprite based on the velocity and if there is a boundary specified then keeps it confined
Sub UpdateSprite (s As SpriteType)
    ' First move the sprite
    s.position.x = s.position.x + s.velocity.x
    s.position.y = s.position.y + s.velocity.y

    ' Next limit movement if boundary is specified
    If s.boundary.b.x > s.boundary.a.x Then
        If s.position.x < s.boundary.a.x Then s.position.x = s.boundary.a.x
        If s.position.x > s.boundary.b.x - s.size.x Then s.position.x = s.boundary.b.x - s.size.x
    End If
    If s.boundary.b.y > s.boundary.a.y Then
        If s.position.y < s.boundary.a.y Then s.position.y = s.boundary.a.y
        If s.position.y > s.boundary.b.y - s.size.y Then s.position.y = s.boundary.b.y - s.size.y
    End If
End Sub


' Takes care of moving hero ship and alien sprites, based on user input and their behavioral algorithms
' MoveSprites is also where missiles are generated and off-screen images are removed from play
Sub MoveSprites (UserInputUp As Byte, UserInputDown As Byte, UserInputLeft As Byte, UserInputRight As Byte, UserInputFire As Byte)
    Dim i As Integer
    Dim AlienFireResult As Integer
    Dim AlienProximity As Integer

    ' First, take care of the hero
    If UserInputUp Then Hero.velocity.y = -HERO_Y_VELOCITY
    If UserInputDown Then Hero.velocity.y = HERO_Y_VELOCITY
    If UserInputLeft Then Hero.velocity.x = -HERO_X_VELOCITY
    If UserInputRight Then Hero.velocity.x = HERO_X_VELOCITY
    UpdateSprite Hero
    ' Set these to zero so that we don't keep moving
    Hero.velocity.x = 0
    Hero.velocity.y = 0

    ' Update hero missiles
    For i = 0 To MAX_HERO_MISSILES - 1
        If HeroMissile(i).bDraw Then
            ' Update position
            UpdateSprite HeroMissile(i)
            ' Stop drawing when it's off screen
            If HeroMissile(i).position.y < -(HeroMissile(i).size.y + HeroMissile(i).objSpec2) Then
                HeroMissile(i).bDraw = FALSE
            End If
        End If
    Next

    ' Generate hero missiles
    If UserInputFire And AllowHeroFire And Hero.bDraw Then
        If CreateHeroMissile(Hero.position.x + HERO_GUN_OFFSET_LEFT, Hero.position.y + HERO_GUN_OFFSET_UP) And CreateHeroMissile(Hero.position.x + HERO_GUN_OFFSET_RIGHT, Hero.position.y + HERO_GUN_OFFSET_UP) Then
            SndPlayCopy LaserSound
        End If
        AllowHeroFire = FALSE
    End If

    ' Update alien missiles
    For i = 0 To MAX_ALIEN_MISSILES - 1
        If AlienMissile(i).bDraw Then
            ' Update position
            UpdateSprite AlienMissile(i)
            ' Stop drawing when it's off screen
            If AlienMissile(i).position.y > (SCREEN_HEIGHT + AlienMissile(i).size.y + AlienMissile(i).objSpec2) Then
                AlienMissile(i).bDraw = FALSE
            End If
        End If
    Next

    ' Move aliens
    For i = 0 To MAX_ALIENS - 1
        If Alien(i).bDraw Then
            If Alien(i).objSpec1 = 0 Then
                ' Pick a new direction
                If Int(Timer) Mod 2 Then
                    Alien(i).velocity.x = Rnd * ALIEN_X_VELOCITY
                Else
                    Alien(i).velocity.x = Rnd * -ALIEN_X_VELOCITY
                End If
                Alien(i).objSpec1 = ALIEN_MOVE_TIME_BASE + Rnd * ALIEN_MOVE_TIME_VAR
            Else
                Alien(i).objSpec1 = Alien(i).objSpec1 - 1
            End If
            ' Update alien position
            UpdateSprite Alien(i)

            ' Move alien to top when it gets to bottom
            If Alien(i).position.y > SCREEN_HEIGHT + Alien(i).size.y Then Alien(i).position.y = -Alien(i).size.y

            ' Generate alien missiles
            If Alien(i).objSpec2 = 0 Then
                AlienFireResult = Rnd * 100 ' in percent
                AlienProximity = Alien(i).position.x - Hero.position.x

                If AlienProximity < 0 Then AlienProximity = -AlienProximity

                If ((AlienProximity < ALIEN_PROX_THRESHOLD) And (AlienFireResult < ALIEN_FIRE_PROB_HERO)) Or (AlienFireResult < ALIEN_FIRE_PROB_RANDOM) Then
                    CreateAlienMissile Alien(i).position.x + ALIEN_GUN_OFFSET_LEFT, Alien(i).position.y + ALIEN_GUN_OFFSET_DOWN
                    CreateAlienMissile Alien(i).position.x + ALIEN_GUN_OFFSET_RIGHT, Alien(i).position.y + ALIEN_GUN_OFFSET_DOWN
                    Alien(i).objSpec2 = ALIEN_FIRE_LOCKOUT
                    SndPlayCopy LaserSound
                End If
            Else
                Alien(i).objSpec2 = Alien(i).objSpec2 - 1
            End If
        End If
    Next

    ' Generate aliens
    If AlienGenCounter = 0 Then
        ' Generate an alien
        CreateAlien
        ' Reinit generate counter
        AlienGenCounter = ALIEN_GEN_RATE_BASE + Rnd * ALIEN_GEN_RATE_VAR
    Else
        AlienGenCounter = AlienGenCounter - 1
    End If

    ' Update explosions -- note, we don't really "move" them, just make the animation go
    For i = 0 To MAX_EXPLOSIONS - 1
        If Explosion(i).bDraw Then
            If Explosion(i).objSpec2 = 0 Then
                Explosion(i).objSpec1 = Explosion(i).objSpec1 + 1
                Explosion(i).objSpec2 = EXPLOSION_FRAME_REPEAT_COUNT
                If Explosion(i).objSpec1 >= MAX_EXPLOSION_BITMAPS Then Explosion(i).bDraw = FALSE
            Else
                Explosion(i).objSpec2 = Explosion(i).objSpec2 - 1
            End If
        End If
    Next

    ' Check at what speed the map needs to be scrolled
    If UserInputUp Then MapScrollStep = MAP_SCROLL_STEP_FAST Else MapScrollStep = MAP_SCROLL_STEP_NORMAL
End Sub


' Check for collisions between various objects and start explosions if they collide
' Collision detection is performed between:
'   * aliens and hero
'   * aliens and hero missiles
'   * hero and alien missiles
' Note that all tests are performed between objects that are currently being drawn, not just active objects
Sub CheckCollisions
    Dim As Integer i, j
    Dim As RectangleType r1, r2

    ' Check between hero and aliens
    For i = 0 To MAX_ALIENS - 1
        ' Make sure both hero and alien are still being drawn
        ' They may still be active but have been removed from the screen and are just being erased
        ' If they are still onscreen, then perform a rectangle test
        GetRectangle Hero.position, Hero.size, r1
        GetRectangle Alien(i).position, Alien(i).size, r2
        If Hero.bDraw And Alien(i).bDraw And RectanglesCollide(r1, r2) Then
            Hero.bDraw = FALSE
            CreateExplosion Hero.position.x, Hero.position.y
            Alien(i).bDraw = FALSE
            CreateExplosion Alien(i).position.x, Alien(i).position.y
            SndPlayCopy ExplosionSound
        End If
    Next

    ' Check between aliens and hero missiles
    For i = 0 To MAX_ALIENS - 1
        If Not Alien(i).bDraw Then Continue

        For j = 0 To MAX_HERO_MISSILES - 1
            ' Do similiar short circuit, mondo huge test as above
            GetRectangle Alien(i).position, Alien(i).size, r1
            GetRectangle HeroMissile(j).position, HeroMissile(j).size, r2
            If HeroMissile(j).bDraw And RectanglesCollide(r1, r2) Then
                Alien(i).bDraw = FALSE
                HeroMissile(j).bDraw = FALSE
                CreateExplosion Alien(i).position.x, Alien(i).position.y
                Score = Score + POINTS_PER_ALIEN
                SndPlayCopy ExplosionSound
                Exit For ' alien is destroyed
            End If
        Next
    Next

    ' Check between hero and alien missiles
    For i = 0 To MAX_ALIEN_MISSILES - 1
        ' Again, rely on short circuiting
        GetRectangle Hero.position, Hero.size, r1
        GetRectangle AlienMissile(i).position, AlienMissile(i).size, r2
        If AlienMissile(i).bDraw And Hero.bDraw And RectanglesCollide(r1, r2) Then
            AlienMissile(i).bDraw = FALSE ' destroy missile in any case
            If HeroShields <= 0 Then
                Hero.bDraw = FALSE
                CreateExplosion Hero.position.x, Hero.position.y
                SndPlayCopy ExplosionSound
                Exit For ' hero is destroyed
            Else
                ' take away a bit of shields
                HeroShields = HeroShields - 5
                If HeroShields < 0 Then HeroShields = 0
            End If
        End If
    Next
End Sub


' Erase all current bitmaps from the hidden screen
' If the erasure marks the last time that the object will be erased because it is no longer being drawn, deactivate the object
Function EraseSprites`
    Dim i As Integer
    Static DeathCounter As Unsigned Integer

    EraseSprites = FALSE

    ' Do player and possibly deactivate
    If Hero.isActive Then
        If Not Hero.bDraw Then
            Hero.isActive = FALSE
            DeathCounter = DEATH_DELAY
        End If
    End If

    ' Erase and deactivate hero missiles
    For i = 0 To MAX_HERO_MISSILES - 1
        ' Deactivate missile if we aren't going to draw or erase it anymore
        If Not HeroMissile(i).bDraw Then
            HeroMissile(i).isActive = FALSE
        End If
    Next

    ' Erase and deactivate aliens
    For i = 0 To MAX_ALIENS - 1
        ' Deactive alien if it's been destroyed
        If Not Alien(i).bDraw Then
            Alien(i).isActive = FALSE
        End If
    Next

    ' Erase and deactivate alien missiles
    For i = 0 To MAX_ALIEN_MISSILES - 1
        ' deactivate missile if we aren't going to draw or erase it anymore
        If Not AlienMissile(i).bDraw Then
            AlienMissile(i).isActive = FALSE
        End If
    Next

    ' Erase and deactivate explosions
    For i = 0 To MAX_EXPLOSIONS - 1
        ' Deactivate if explosion has run its course
        If Not Explosion(i).bDraw Then
            Explosion(i).isActive = FALSE
        End If
    Next

    ' Hero has died - signal game over after brief delay
    If Not Hero.isActive Then
        If DeathCounter = 0 Then
            EraseSprites = TRUE
        Else
            DeathCounter = DeathCounter - 1
        End If
    End If
End Function


' Unlike the 8BPP version which changes the pallette, this changes the actual sprite pixels
Sub BlinkGuns (bRed As Byte)
    ' Save the current write page
    Dim oldDest As Long
    oldDest = Dest

    ' Now just set the pixels with the color we want
    Dest HeroBitmap
    If bRed Then
        PSet (GUN_BLINK_HERO_X1, GUN_BLINK_HERO_Y), NP_Red
        PSet (GUN_BLINK_HERO_X2, GUN_BLINK_HERO_Y), NP_Red
    Else
        PSet (GUN_BLINK_HERO_X1, GUN_BLINK_HERO_Y), Black
        PSet (GUN_BLINK_HERO_X2, GUN_BLINK_HERO_Y), Black
    End If

    Dest AlienBitmap
    If Not bRed Then
        PSet (GUN_BLINK_ALIEN_X1, GUN_BLINK_ALIEN_Y), NP_Red
        PSet (GUN_BLINK_ALIEN_X2, GUN_BLINK_ALIEN_Y), NP_Red
    Else
        PSet (GUN_BLINK_ALIEN_X1, GUN_BLINK_ALIEN_Y), Black
        PSet (GUN_BLINK_ALIEN_X2, GUN_BLINK_ALIEN_Y), Black
    End If

    Dest oldDest
End Sub


' Draw all active objects that should be drawn on the screen
Sub DrawSprites
    Dim i As Integer

    ' Do explosions
    For i = 0 To MAX_EXPLOSIONS - 1
        If Explosion(i).bDraw Then
            ' draw explosion
            PutImage (Explosion(i).position.x, Explosion(i).position.y), ExplosionBitmap(Explosion(i).objSpec1)

        End If
    Next

    ' Draw hero missiles
    For i = 0 To MAX_HERO_MISSILES - 1
        If HeroMissile(i).bDraw Then
            ' Draw missile itself
            PutImage (HeroMissile(i).position.x, HeroMissile(i).position.y), MissileBitmap
            ' Draw missile trail. Remember we stored missile height in objspec2
            PutImage (HeroMissile(i).position.x, HeroMissile(i).position.y + HeroMissile(i).objSpec2), MissileTrailUpBitmap
        End If
    Next

    ' Draw alien missiles
    For i = 0 To MAX_ALIEN_MISSILES - 1
        If AlienMissile(i).bDraw Then
            ' Draw missile itself
            PutImage (AlienMissile(i).position.x, AlienMissile(i).position.y), MissileBitmap
            ' Draw missile trail. Again objspec2 has the missile height
            PutImage (AlienMissile(i).position.x, AlienMissile(i).position.y - AlienMissile(i).objSpec2), MissileTrailDnBitmap
        End If
    Next

    ' Do aliens
    For i = 0 To MAX_ALIENS - 1
        If Alien(i).isActive And Alien(i).bDraw Then
            PutImage (Alien(i).position.x, Alien(i).position.y), AlienBitmap
        End If
    Next

    ' Do player
    If Hero.isActive And Hero.bDraw Then
        PutImage (Hero.position.x, Hero.position.y), HeroBitmap
    End If

    ' Blink the guns
    If GunBlinkCounter = 0 Then
        BlinkGuns GunBlinkState
        GunBlinkState = Not GunBlinkState ' Flip it to other state
        GunBlinkCounter = GUN_BLINK_RATE
        AllowHeroFire = TRUE
    Else
        GunBlinkCounter = GunBlinkCounter - 1
    End If
End Sub


' Performs all the program-wide initialization at start-up time
Sub InitializeProgram
    ' Initialize some stuff
    Randomize Timer

    ' Set the Window title
    Title APP_NAME

    ' Load high-score file
    LoadHighScores

    ' Load sound fx and music
    InitializeSound

    ' Initialize graphics
    Screen NewImage(SCREEN_WIDTH, SCREEN_HEIGHT, 32)

    ' Set to fullscreen. We can also go to windowed mode using Alt+Enter
    FullScreen SquarePixels , Smooth

    ' We want transparent text rendering
    PrintMode KeepBackground

    ' Hide the mouse pointer
    MouseHide

    ' We want the framebuffer to be updated when we want
    Display

    ' We need the scrolling map during high score screens
    InitializeMap
End Sub


' Releases all allocated resources (use before exiting)
Sub FinalizeProgram
    ' Free map resources
    FinalizeMap

    ' Set framebuffer to autoupdate
    AutoDisplay

    ' Release sound resources (esp. MIDI here)
    FinalizeSound

    ' Save high scores
    SaveHighScores
End Sub


' Run the game!
Sub RunGame
    Dim As Byte UserInputUp, UserInputDown, UserInputLeft, UserInputRight, UserInputFire
    Dim As Bit GameOver

    ' Initialize all counters, etc.
    Score = 0
    AlienGenCounter = ALIEN_GEN_RATE_BASE
    HeroShields = MAX_HERO_SHIELDS

    InitializeHUD
    InitializeSprites

    ' Play the in-game music
    PlayMIDIFile "dat/sfx/mus/alienmain.mid"

    ' Initialize some variables and enter main animation loop
    GameOver = FALSE

    ' Main game loop
    Do
        ' Get user input
        GameOver = PollInput(UserInputUp, UserInputDown, UserInputLeft, UserInputRight, UserInputFire)

        ' Move sprites
        MoveSprites UserInputUp, UserInputDown, UserInputLeft, UserInputRight, UserInputFire

        ' Check for collisions
        CheckCollisions

        ' Erase any sprites if required
        GameOver = GameOver Or EraseSprites

        ' Scroll screen (this will basically wipe the whole framebuffer so we do not clear anything)
        UpdateMap

        ' Draw map
        DrawMap

        ' Draw sprites
        DrawSprites

        ' Draw game HUD
        DrawHUD

        ' Page flip
        Display

        ' Only run the loop the number of times we want
        Limit UPDATES_PER_SECOND
    Loop While Not GameOver

    FinalizeSprites
    FinalizeHUD

    ' Fade to black...
    Fade TRUE
End Sub

