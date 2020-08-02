''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'      _    _ _                 _    _ _                   '
'     / \  | (_) ___ _ __      / \  | | | ___ _   _        '
'    / _ \ | | |/ _ \ '_ \    / _ \ | | |/ _ \ | | |       '
'   / ___ \| | |  __/ | | |  / ___ \| | |  __/ |_| |       '
'  /_/   \_\_|_|\___|_| |_| /_/   \_\_|_|\___|\__, |       '
'                                             |___/        '
'                                                          '
'  Conversion/port copyright (c) Samuel Gomes, 1998-2010.  '
'  All rights reserved.                                    '
'                                                          '
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' All header files that we need
#Include "vbcompat.bi"
#Include "allegro.bi"

' Setup some language sematics
#Ifndef Boolean
#Define Boolean Integer
#EndIf

/' CONSTANTS '/
#Define INTRO_TEXT_COLOR			15
#Define MAX_ALIENS					4
#Define MAX_ALIEN_MISSILES			20
#Define MAX_HERO_MISSILES			10
#Define MAX_EXPLOSIONS				(MAX_ALIENS + 1) /' +1 for hero '/
#Define MAX_EXPLOSION_BITMAPS 		5
#Define GUN_COLOR					8
#Define GUN_BLINK_RATE				20
#Define HERO_X_VELOCITY				3
#Define HERO_Y_VELOCITY				3
#Define ALIEN_X_VELOCITY			3
#Define ALIEN_Y_VELOCITY			2
#Define HERO_MISSILE_VELOCITY		5
#Define ALIEN_MISSILE_VELOCITY		4
#Define MAX_MOVE_STEP				8	/' max sprite movement (hero missile) '/
#Define ALIEN_MOVE_TIME_VAR			50
#Define ALIEN_MOVE_TIME_BASE		20
#Define ALIEN_GEN_RATE_BASE			40
#Define ALIEN_GEN_RATE_VAR			40
#Define ALIEN_FIRE_LOCKOUT			60
#Define ALIEN_FIRE_PROB_HERO		20
#Define ALIEN_FIRE_PROB_RANDOM		10
#Define ALIEN_PROX_THRESHOLD		20
#Define HERO_GUN_OFFSET_LEFT		3
#Define HERO_GUN_OFFSET_RIGHT		26
#Define HERO_GUN_OFFSET_UP			10
#Define ALIEN_GUN_OFFSET_LEFT		4
#Define ALIEN_GUN_OFFSET_RIGHT		25
#Define ALIEN_GUN_OFFSET_DOWN		20
#Define DEATH_DELAY					60 /' 1 sec delay after player death '/
#Define POINTS_PER_ALIEN			10
#Define MAX_HERO_SHIELDS			(SHIELD_STATUS_WIDTH - 1)
#Define SHIELD_STATUS_WIDTH 		80
#Define SHIELD_STATUS_HEIGHT 		20
#Define SHIELD_STATUS_LEFT 			192
#Define SHIELD_STATUS_TOP 			440
#Define SHIELD_STATUS_RIGHT 		(SHIELD_STATUS_LEFT + SHIELD_STATUS_WIDTH - 1)
#Define SHIELD_STATUS_BOTTOM 		(SHIELD_STATUS_TOP + SHIELD_STATUS_HEIGHT - 1)
#Define SHIELD_STATUS_COLOR			47
#Define SHIELD_STATUS_INVERT_COLOR 	173
#Define STATUS_BACKGROUND_COLOR		27
#Define SCORE_NUMBERS_LEFT			474
#Define SCORE_NUMBERS_TOP			443
#Define EXPLOSION_FRAME_REPEAT_COUNT 3
#Define HIGH_SCORE_TEXT_LEN			20
#Define HIGH_SCORE_FILENAME 		ExePath & "/dat/highscore.dat"
#Define HIGH_SCORE_COLOR        	2
#Define TILE_WIDTH					32 /' in pixels '/
#Define TILE_HEIGHT					32
#Define NUM_TILES					3
#Define UPDATES_PER_SECOND			60
/' screen parameters '/
#Define SCREEN_WIDTH				640
#Define SCREEN_HEIGHT				480
#Define REDUCED_SCREEN_HEIGHT		(SCREEN_HEIGHT - STATUS_HEIGHT)
#Define STATUS_HEIGHT				60		' our hud is 60 pixels now 30 * 2 in 640x480 mode
/' scrolling parameters '/
#Define MAP_SCROLL_STEP_NORMAL		1
#Define MAP_SCROLL_STEP_FAST		2

/' STRUCTURES AND TYPES '/
Type POINT_T
	x As Integer
	y As Integer
End Type

Type RECT_T
	a As Point_t
	b As Point_t
End Type

Type SPRITE_T
	Active As Boolean
	p As POINT_T
	vx As Integer				' x velocity
	vy As Integer				' y velocity
	bDraw As Boolean			' was draw
	ObjectSpec1 As Integer
	ObjectSpec2 As Integer
	Bounds As Rect_t
End Type

Type HIGH_SCORE_T
	Text As String * HIGH_SCORE_TEXT_LEN
	Score As Integer
End Type


/' GLOBAL VARIABLES '/
Dim Shared GamePalette(0 To PAL_SIZE - 1) As Palette
Dim Shared Score As Integer
Dim Shared HeroShields As Integer = MAX_HERO_SHIELDS
Dim Shared HighScore(0 To 9) As HIGH_SCORE_T
Dim Shared ExplosionSound As SAMPLE Pointer
Dim Shared LaserSound As SAMPLE Pointer
Dim Shared GameMusic As MIDI Pointer
Dim Shared MapLine(0 To (SCREEN_WIDTH / TILE_WIDTH) - 1) As Integer		' each tile is 32x32. so 640 / 32 = 20
Dim Shared Tile(0 To NUM_TILES - 1) As BITMAP Pointer
Dim Shared MapBuffer As BITMAP Pointer									' this is the pre-rendered background bitmap
Dim Shared MapScrollStep As Integer = MAP_SCROLL_STEP_NORMAL			' # of pixels to scroll the background
Dim Shared MapLineCounter As Integer = -TILE_HEIGHT						' this keeps track of the new tiles positions
Dim Shared FrameBuffer As BITMAP Pointer
Dim Shared HUDBitmap As BITMAP Pointer
Dim Shared HUDNumberBitmap(0 To 9) As BITMAP Pointer
Dim Shared Hero As SPRITE_T
Dim Shared Alien(0 To MAX_ALIENS - 1) As SPRITE_T
Dim Shared HeroMissile(0 To MAX_HERO_MISSILES - 1) As SPRITE_T
Dim Shared AlienMissile(0 To MAX_ALIEN_MISSILES - 1) As SPRITE_T
Dim Shared Explosion(0 To MAX_EXPLOSIONS - 1) As SPRITE_T
Dim Shared HeroBitmap As BITMAP Pointer
Dim Shared AlienBitmap As BITMAP Pointer
Dim Shared MissileBitmap As BITMAP Pointer
Dim Shared MissileTrailUpBitmap As BITMAP Pointer
Dim Shared MissileTrailDnBitmap As BITMAP Pointer
Dim Shared ExplosionBitmap(0 To MAX_EXPLOSION_BITMAPS - 1) As BITMAP Pointer
Dim Shared As UInteger HeroWidth, HeroHeight
Dim Shared As UInteger HeroXMin, HeroXMax
Dim Shared As UInteger HeroYMin, HeroYMax
Dim Shared As UInteger AlienWidth, AlienHeight
Dim Shared As UInteger MissileWidth, MissileHeight
Dim Shared As UInteger MissileTrailWidth, MissileTrailHeight
Dim Shared As UInteger ExplosionWidth, ExplosionHeight
Dim Shared AlienGenCounter As UInteger
Dim Shared GunBlinkCounter As UInteger
Dim Shared GunBlinkState As Boolean
Dim Shared GunColor As Palette
Dim Shared HeroAllowFire As Boolean
Dim Shared Ticks As UInteger											' Timer ticks to control game speed


' Our timer interrupt handler
' Simply updates the global Ticks variable
Sub Ticker Cdecl()
	Ticks += 1
End Sub

' Plays an sfx keeping in mind the source of the sound
Sub SfxPlay(ByVal s As SAMPLE Pointer, ByVal x As Integer, ByVal y As Integer, ByVal b As BITMAP Pointer)
	' Find the midpoint absolute location of the object and scale it down to the Allegro limits
	Dim p As Integer = ((x + b->w / 2) / (SCREEN_WIDTH - 1)) * 255
	play_sample(s, 255, p, 1000 + IIf(Int(Timer) Mod 2, Rnd * p, Rnd * -p), FALSE)
End Sub


/'
	Function: ComputeBoundingRect
    Description:
    	Calculates the bounding rectangle for a sprite given its
        position, origin offset, width, and height.
'/
Sub BoundingRectCompute(ByVal x As Integer, ByVal y As Integer, ByVal W As Integer, ByVal H As Integer, ByRef r As RECT_T)
	r.a.x = x
	r.a.y = y
	r.b.x = r.a.x + W - 1
	r.b.y = r.a.y + H - 1
End Sub


' Collision testing routine (works only for 8-bit bitmaps at the moment!)
Function CollisionTest(ByVal bmp1 As BITMAP Pointer, bmp1pt As POINT_T, ByVal bmp2 As BITMAP Pointer, bmp2pt As POINT_T) As Boolean
	Dim As RECT_T r1, r2, r
	Dim As Integer x1, y1, x2, y2, x1s, x2s, w, h, i, j

	' Create 'bmp1' bounding rectangle
	BoundingRectCompute(bmp1pt.x, bmp1pt.y, bmp1->w, bmp1->h, r1)

	' Create 'bmp2' bounding rectangle
	BoundingRectCompute(bmp2pt.x, bmp2pt.y, bmp2->w, bmp2->h, r2)

	' Leave if the rectangle do not collide
	If (r1.a.x > r2.b.x Or r2.a.x > r1.b.x Or r1.a.y > r2.b.y Or r2.a.y > r1.b.y) Then
		Return FALSE
	End If

	' Rectangle collision; do a detailed check
	' Find the intersecting rectangle
	r.a.x = IIf(r1.a.x > r2.a.x, r1.a.x, r2.a.x)
	r.a.y = IIf(r1.a.y > r2.a.y, r1.a.y, r2.a.y)
	r.b.x = IIf(r1.b.x < r2.b.x, r1.b.x, r2.b.x)
	r.b.y = IIf(r1.b.y < r2.b.y, r1.b.y, r2.b.y)

	' Find the width and height of the intersecting rectangle
	w = 1 + r.b.x - r.a.x
	h = 1 + r.b.y - r.a.y

	' Find the starting x & y positions of intersection in the bitmaps
	y1 = r.a.y - bmp1pt.y
	y2 = r.a.y - bmp2pt.y
	x1s = r.a.x - bmp1pt.x
	x2s = r.a.x - bmp2pt.x

	' Check both bitmap for collission
	For j = 0 To h - 1
		x1 = x1s
		x2 = x2s
		For i = 0 To w - 1
			If (_getpixel(bmp1, x1, y1) <> 0 AndAlso _getpixel(bmp2, x2, y2) <> 0) Then
				Return TRUE
			End If

			x1 += 1
			x2 += 1
		Next

		y1 += 1
		y2 += 1
	Next

	Return FALSE
End Function


/'
	Function: LoadSprites
    Description:
    	Loads the hero, alien, and missile sprites and initializes the
		sprite structures.
'/
Sub SpritesInitialize()
	Dim i As Integer

	/' load hero spaceship '/
	HeroBitmap = load_bitmap(ExePath & "/dat/gfx/hero.pcx", @GamePalette(0))
	HeroWidth = HeroBitmap->W
	HeroHeight = HeroBitmap->H
	HeroXMin = 0
	HeroXMax =	SCREEN_WIDTH - HeroWidth
	HeroYMin = 0
	HeroYMax = REDUCED_SCREEN_HEIGHT - HeroHeight

	/' set up gun blink stuff '/
	GunColor.R = GamePalette(GUN_COLOR).R
	GunColor.G = GamePalette(GUN_COLOR).G
	GunColor.B = GamePalette(GUN_COLOR).B
	GunBlinkCounter = GUN_BLINK_RATE
	GunBlinkState = TRUE

	/' load alien spaceship '/
	AlienBitmap = load_bitmap(ExePath & "/dat/gfx/alien.pcx", @GamePalette(0))
	AlienWidth = AlienBitmap->W
	AlienHeight = AlienBitmap->H

	/' load missile '/
	MissileBitmap = load_bitmap(ExePath & "/dat/gfx/missile.pcx", @GamePalette(0))
	MissileWidth = MissileBitmap->W
	MissileHeight = MissileBitmap->H

	/' load missile trails '/
	MissileTrailUpBitmap = load_bitmap(ExePath & "/dat/gfx/missiletrail.pcx", @GamePalette(0))
	MissileTrailWidth = MissileTrailUpBitmap->W
	MissileTrailHeight = MissileTrailUpBitmap->H

	' Generate and initialize the other trail
	MissileTrailDnBitmap = create_bitmap(MissileTrailWidth, MissileTrailHeight)
	' Clear the bitmap to color 0
	clear_bitmap(MissileTrailDnBitmap)
	' Blit the missiletrailup v inverted
	draw_sprite_v_flip(MissileTrailDnBitmap, MissileTrailUpBitmap, 0, 0)

	/' load explosion bitmaps '/
	ExplosionBitmap(0) = load_bitmap(ExePath & "/dat/gfx/explosion1.pcx", @GamePalette(0))
	ExplosionWidth = ExplosionBitmap(0)->W
	ExplosionHeight = ExplosionBitmap(0)->H

	ExplosionBitmap(1) = load_bitmap(ExePath & "/dat/gfx/explosion2.pcx", @GamePalette(0))

	ExplosionBitmap(2) = load_bitmap(ExePath & "/dat/gfx/explosion3.pcx", @GamePalette(0))

	ExplosionBitmap(3) = load_bitmap(ExePath & "/dat/gfx/explosion4.pcx", @GamePalette(0))

	ExplosionBitmap(4) = load_bitmap(ExePath & "/dat/gfx/explosion5.pcx", @GamePalette(0))

	/' initialize Hero SPRITE '/
	Hero.Active = TRUE
	Hero.p.x = (HeroXMin + HeroXMax) / 2
	Hero.p.y = (HeroYMin + HeroYMax) / 2
	Hero.bDraw = TRUE

	/' initialize alien sprites '/
	For i = 0 To MAX_ALIENS - 1
		Alien(i).Active = FALSE
		Alien(i).bDraw = FALSE
	Next

	/' initialize alien missiles '/
	For i = 0 To MAX_ALIEN_MISSILES - 1
		AlienMissile(i).Active = FALSE
		AlienMissile(i).bDraw = FALSE
	Next

	/' initialize hero missiles '/
	For i = 0 To MAX_HERO_MISSILES - 1
		HeroMissile(i).Active = FALSE
		HeroMissile(i).bDraw = FALSE
	Next

	/' initialize explosions '/
	For i = 0 To MAX_EXPLOSIONS - 1
		Explosion(i).Active = FALSE
		Explosion(i).bDraw = FALSE
	Next
End Sub


/'
	Function: FreeSprites
    Description:
    	Frees the memory occupied by the sprites.
'/
Sub SpritesFinalize()
	Dim i As Integer

	If (HeroBitmap <> NULL) Then
		destroy_bitmap(HeroBitmap)
		HeroBitmap = NULL
	End If

	If (AlienBitmap <> NULL) Then
		destroy_bitmap(AlienBitmap)
		AlienBitmap = NULL
	End If

	If (AlienBitmap <> NULL) Then
		destroy_bitmap(AlienBitmap)
		AlienBitmap = NULL
	End If

	If (MissileBitmap <> NULL) Then
		destroy_bitmap(MissileBitmap)
		MissileBitmap = NULL
	End If

	If (MissileTrailUpBitmap <> NULL) Then
		destroy_bitmap(MissileTrailUpBitmap)
		MissileTrailUpBitmap = NULL
	End If

	If (MissileTrailDnBitmap <> NULL) Then
		destroy_bitmap(MissileTrailDnBitmap)
		MissileTrailDnBitmap = NULL
	End If

	For i = 0 To MAX_EXPLOSION_BITMAPS - 1
		If (ExplosionBitmap(i) <> NULL) Then
			destroy_bitmap(ExplosionBitmap(i))
			ExplosionBitmap(i) = NULL
		End If
	Next
End Sub


/'
	Function: GetKeyboardInput
    Description:
    	Updates the "UserInput..." variables used by the MoveSprites
        routine from the keyboard input device.
'/
Function InputPoll(ByRef UserInputUp As Boolean, ByRef UserInputDown As Boolean, ByRef UserInputLeft As Boolean, ByRef UserInputRight As Boolean, ByRef UserInputFire As Boolean) As Boolean
	Dim As Integer MouseMickeyX, MouseMickeyY

	poll_mouse()
	poll_keyboard()
	get_mouse_mickeys(@MouseMickeyX, @MouseMickeyY)

	UserInputLeft = (MouseMickeyX < 0) Or key(KEY_LEFT)
	UserInputUp	= (MouseMickeyY < 0) Or key(KEY_UP)
	UserInputRight = (MouseMickeyX > 0) Or key(KEY_RIGHT)
	UserInputDown = (MouseMickeyY > 0) Or key(KEY_DOWN)
	UserInputFire = (mouse_b <> 0) Or key(KEY_SPACE) Or key(KEY_LCONTROL) Or key(KEY_RCONTROL) Or key(KEY_ALT) Or key(KEY_ALTGR)

	Return key(KEY_ESC)
End Function


/'
	Function: CreateHeroMissile
    Description:
    	Finds a non-active hero missile in the HeroMissile
        array and initializes it.
'/
Function HeroMissileCreate(ByVal x As Integer, ByVal y As Integer) As Boolean
	Dim i As Integer

	For i = 0 To MAX_HERO_MISSILES - 1
		If (Not HeroMissile(i).Active) Then
			HeroMissile(i).Active = TRUE
			HeroMissile(i).p.x = x
			HeroMissile(i).p.y = y
			HeroMissile(i).vx = 0
			HeroMissile(i).vy = -HERO_MISSILE_VELOCITY
			HeroMissile(i).bDraw = TRUE
			/' initialize bounding rect '/
			BoundingRectCompute(HeroMissile(i).p.x, HeroMissile(i).p.y, MissileWidth, MissileHeight, HeroMissile(i).Bounds)
			Return TRUE
		End If
	Next

	Return FALSE
End Function


/'
	Function: CreateAlien
    Description:
    	Finds a free alien in the Alien array and initializes it.
'/
Sub AlienCreate()
	Dim i As Integer

	For i = 0 To MAX_ALIENS - 1
		If (Not Alien(i).Active) Then
			Alien(i).Active	= TRUE
			Alien(i).p.x = Rnd * (SCREEN_WIDTH - AlienWidth)
			Alien(i).p.y = -AlienHeight							' we want the aliens off-screen
			Alien(i).vx = Rnd * ALIEN_X_VELOCITY + 1
			Alien(i).vy = Rnd * ALIEN_Y_VELOCITY + 1
			Alien(i).bDraw = TRUE
			Alien(i).ObjectSpec1 = ALIEN_MOVE_TIME_BASE + Rnd * ALIEN_MOVE_TIME_VAR
			Alien(i).ObjectSpec2 = 0 /' ability to fire immediately '/
			/' initialize alien bounding rect '/
			BoundingRectCompute(Alien(i).p.x, Alien(i).p.y, AlienWidth, AlienHeight, Alien(i).Bounds)
			Exit For
		End If
	Next
End Sub


/'
	Function: CreateAlienMissile
    Description:
    	Finds a free alien missile in the AlienMissile array and
        initializes it.  The x and y positions of the missile
        are set from the x and y parameters which will place
        them somewhere near an alien gun.
'/
Sub AlienMissileCreate(ByVal x As Integer, ByVal y As Integer)
	Dim i As Integer

	For i = 0 To MAX_ALIEN_MISSILES - 1
		If (Not AlienMissile(i).Active) Then
			AlienMissile(i).Active = TRUE
			AlienMissile(i).p.x = x
			AlienMissile(i).p.y = y
			AlienMissile(i).vx = 0
			AlienMissile(i).vy = ALIEN_MISSILE_VELOCITY
			AlienMissile(i).bDraw = TRUE
			/' initialize bounding rect '/
			BoundingRectCompute(AlienMissile(i).p.x, AlienMissile(i).p.y, MissileWidth, MissileHeight, AlienMissile(i).Bounds)
			Exit For
		End If
	Next
End Sub


/'
	Function: CreateExplosion
    Description:
    	Starts an explosion occuring at the appropriate x and y
        coordinates.
'/
Sub ExplosionCreate(ByVal x As Integer, ByVal y As Integer)
	Dim i As Integer

	For i = 0 To MAX_EXPLOSIONS - 1
		If (Not Explosion(i).Active) Then
			Explosion(i).Active = TRUE
			Explosion(i).p.x = x
			Explosion(i).p.y = y
			Explosion(i).bDraw = TRUE
			Explosion(i).ObjectSpec1 = 0	 /' current explosion bitmap '/
			Explosion(i).ObjectSpec2 = EXPLOSION_FRAME_REPEAT_COUNT
			Exit For
		End If
	Next
End Sub


/'
	Function: DrawStatus
    Description:
    	Draws the status area at the bottom of the screen
        showing the player's current score and shield strength.
'/
Sub HUDDraw()
	Dim ScoreText As String * 6
	Dim i As Integer = HUDBitmap->h * 2			' Our HUD was originally for 320 x 240; so we gotta stretch it
	Dim j As Integer = SCORE_NUMBERS_LEFT
	Dim As Integer k, w, h

	' First draw the HUD panel onto the frame buffer
	stretch_sprite(FrameBuffer, HUDBitmap, 0, FrameBuffer->h - i, FrameBuffer->w, i)

	' Update the shield status
	rectfill(FrameBuffer, SHIELD_STATUS_LEFT, SHIELD_STATUS_TOP, SHIELD_STATUS_RIGHT, SHIELD_STATUS_BOTTOM, SHIELD_STATUS_INVERT_COLOR)
	rectfill(FrameBuffer, SHIELD_STATUS_LEFT, SHIELD_STATUS_TOP, SHIELD_STATUS_LEFT + HeroShields, SHIELD_STATUS_BOTTOM, SHIELD_STATUS_COLOR)

	ScoreText = Right("000000" & Str(Score), 6)

	' Render the score
	For i = 1 To 6
		k = Asc(ScoreText, i) - &H30		' &h30 is "0"
		w = HUDNumberBitmap(k)->w * 2
		h = HUDNumberBitmap(k)->h * 2
		stretch_sprite(FrameBuffer, HUDNumberBitmap(k), j, SCORE_NUMBERS_TOP, w, h)
		j += w
	Next
End Sub


/'
	Function: InitStatus
    Description:
    	Draw the background and "Shield" and "Score" bitmaps.
'/
Sub HUDInitialize()
	Dim i As Integer

	' Load the HUD bitmap
	HUDBitmap = load_bitmap(ExePath & "/dat/gfx/hud.pcx", @GamePalette(0))

	' Load the numbers bitmaps
	For i = 0 To 9
		HUDNumberBitmap(i) = load_bitmap(ExePath & "/dat/gfx/" & Str(i) & ".pcx", @GamePalette(0))
	Next
End Sub


' Destroys the HUD
Sub HUDFinalize()
	Dim i As Integer

	If (HUDBitmap <> NULL) Then
		destroy_bitmap(HUDBitmap)
		HUDBitmap = NULL
	End If

	For i = 0 To 9
		If (HUDNumberBitmap(i) <> NULL) Then
			destroy_bitmap(HUDNumberBitmap(i))
			HUDNumberBitmap(i) = NULL
		End If
	Next
End Sub


' Initialize the actual game FrameBuffer that we will draw to during play
Sub FrameBufferInitialize()
	' Create a h/w accelerated bitmap framebuffer first
	FrameBuffer = create_system_bitmap(SCREEN_WIDTH, SCREEN_HEIGHT)

	If (FrameBuffer = NULL) Then
		' Create a regular memory bitmap framebuffer
		FrameBuffer = create_bitmap(SCREEN_WIDTH, SCREEN_HEIGHT)
	End If
End Sub


' Destroys the framebuffer once we are out of the actual game
Sub FrameBufferFinalize()
	If (FrameBuffer <> NULL) Then
		destroy_bitmap(FrameBuffer)
		FrameBuffer = NULL
	End If
End Sub


' Renders the framebuffer contents to the screen
Sub FrameBufferFlip()
	blit(FrameBuffer, Screen, 0, 0, 0, 0, FrameBuffer->w, FrameBuffer->h)
End Sub


/'
	Function: InitMap
    Description:
    	Initialize the map with random tiles.
'/
Sub MapInitialize()
	Dim As Integer x, y, w, h, c

	' Create the main tile buffer first
	MapBuffer = create_bitmap(SCREEN_WIDTH, SCREEN_HEIGHT)

	/' load the background tiles to video memory '/
	Tile(0) = load_bitmap(ExePath & "/dat/gfx/stars1.pcx", @GamePalette(0))
	Tile(1) = load_bitmap(ExePath & "/dat/gfx/stars2.pcx", @GamePalette(0))
	Tile(2) = load_bitmap(ExePath & "/dat/gfx/earth.pcx", @GamePalette(0))

	' Set other variables
	MapScrollStep = MAP_SCROLL_STEP_NORMAL
	MapLineCounter = -TILE_HEIGHT

	' Just draw ramdom tiles on the background
	w = (MapBuffer->w / TILE_WIDTH) - 1
	h = (MapBuffer->h / TILE_HEIGHT) - 1

	For y = 0 To h
		For x = 0 To w
			' We just need more stars and less planets
			c = Rnd * 256
			If (c = 128) Then
				c = NUM_TILES - 1
			Else
				c Mod= 2
			End If

			' Blit the random tile
			blit(Tile(c), MapBuffer, 0, 0, x * TILE_WIDTH, y * TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)
		Next
	Next
End Sub


' Destroys the background tile map stuff
Sub MapFinalize()
	Dim i As Integer

	If (MapBuffer <> NULL) Then
		destroy_bitmap(MapBuffer)
		MapBuffer = NULL
	End If

	For i = 0 To NUM_TILES - 1
		If (Tile(i) <> NULL) Then
			destroy_bitmap(Tile(i))
			Tile(i) = NULL
		End If
	Next
End Sub


/'
	Function: ScrollScreen
    Description:
    	Scroll the hidden page up a few lines and draw the next row
		of tiles above, if necessary.  Moves the screen
'/
Sub MapScroll()
	Dim As Integer i, c

	' Check all new tiles are completely shown; if so reset it
	If (MapLineCounter > 0) Then MapLineCounter = -TILE_HEIGHT

	' Check if we have to generate a fresh set of tiles at the top of the map
	If (MapLineCounter <= -TILE_HEIGHT) Then
		' Okay. Generate all the new tiles to be draw at the top of the map
		For i = 0 To (SCREEN_WIDTH / TILE_WIDTH) - 1
			' We just need more stars and less planets
			c = Rnd * 256
			If (c = 128) Then
				c = NUM_TILES - 1
			Else
				c Mod= 2
			End If

			MapLine(i) = c
		Next
	End If

	' Shift the entire background down by "scrollstep" pixels
	blit(MapBuffer, MapBuffer, 0, 0, 0, MapScrollStep, MapBuffer->w, MapBuffer->h - MapScrollStep)

	' Move the new tiles down by "scrollstep"
	MapLineCounter += MapScrollStep

	' Draw the new tiles at the top
	For i = 0 To (SCREEN_WIDTH / TILE_WIDTH) - 1
		blit(Tile(MapLine(i)), MapBuffer, 0, 0, i * TILE_WIDTH, MapLineCounter, TILE_WIDTH, TILE_HEIGHT)
	Next
End Sub


' Draws the map buffer to the frame buffer
Sub MapDraw()
	blit(MapBuffer, FrameBuffer, 0, 0, 0, 0, MapBuffer->w, MapBuffer->h)
End Sub


' Loads and plays a MIDI file (loops it too)
Sub MIDIPlay(s As String)
	' Unload music if loaded
	If (GameMusic <> NULL) Then
		destroy_midi(GameMusic)
		GameMusic = NULL
	End If

	' Load the music file
	GameMusic = load_midi(ExePath & "/dat/snd/mus/" & s)

	' Play it if loading was successful
	If (GameMusic <> NULL) Then	play_midi(GameMusic, TRUE)
End Sub


/'
	Function: InitSound
    Description:
		Initialize sound stuff.
'/
Sub SoundInitialize()
	/' load the sound effects '/
	ExplosionSound = load_sample(ExePath & "/dat/snd/explode.wav")
	LaserSound = load_sample(ExePath & "/dat/snd/laser.wav")
End Sub


/'
	Function: DeInitSound
	Description:
    	Unloads both MidPak and DigPak.
'/
Sub SoundFinalize()
	If (ExplosionSound <> NULL) Then
		destroy_sample(ExplosionSound)
		ExplosionSound = NULL
	End If

	If (LaserSound <> NULL) Then
		destroy_sample(LaserSound)
		LaserSound = NULL
	End If

	If (GameMusic <> NULL) Then
		destroy_midi(GameMusic)
		GameMusic = NULL
	End If
End Sub


/'
	Function: CenterString
    Description:
    	Centers a string on the screen.  The function calculates
        the correct starting column position to center the string
		on the screen and then calls DrawString to do the actual
        drawing of the text.
'/
Sub StringDrawCenter(s As String, ByVal y As Integer, ByVal c As Byte)
	textout_centre(Screen, font, StrPtr(s), SCREEN_WIDTH / 2, y * text_height(font), c)
End Sub


/'
	Function: DisplayHighScores
    Description:
    	Displays the HighScore array on the screen.
'/
Sub HighScoresDisplay()
	Dim i As Integer

	StringDrawCenter("####===-- High Scores --===####", 4, 14)
	For i = 0 To UBound(HighScore)
		textprintf_centre(Screen, font, SCREEN_WIDTH / 2, 72 + i * text_height(font) * 4, HIGH_SCORE_COLOR, "%2d. %-20s  %5d", i + 1, StrPtr(HighScore(i).Text), HighScore(i).Score)
	Next
End Sub


/'
	Function: DisplayHighScoreScreen
    Description:
    	Displays the high score screen from the title page.
'/
Sub HighScoresScreenDisplay()
	/' clear screen '/
	clear_bitmap(Screen)

	/' set everything to black so we can draw without being seen '/
	set_palette(@black_palette(0))

	HighScoresDisplay()

	' Fade in
	fade_in(@default_palette(0), 1)

	' Wait until a key is pressed
	clear_keybuf()
	readkey()

	' Fade out
	fade_out(1)
End Sub


/'
	Function: NewHighScore
    Description:
    	Manipulates the HighScore array to make room for the
        users score and gets the new text.
'/
Sub HighScoresNew(ByVal NewScore As Integer)
	Dim As Integer i, Row, Column, sLen, k

	' check to see if it's really a high score
	If (NewScore <= HighScore(9).Score) Then Return

	/' start high score music '/
	MIDIPlay("alienend.mid")

	/' move other scores down to make room '/
	For i = 8 To 0 Step -1
		If (NewScore > HighScore(i).Score) Then
			HighScore(i + 1).Text = HighScore(i).Text
			HighScore(i + 1).Score = HighScore(i).Score
		Else
			Exit For
		End If
	Next
	i += 1

	/' blank out text of correct slot '/
	HighScore(i).Text = vbNullString
	HighScore(i).Score = NewScore

	/' clear screen '/
	clear_bitmap(Screen)

	/' set everything to black so we can draw without being seen '/
	set_palette(@black_palette(0))

	HighScoresDisplay()

	' Fade in
	fade_in(@default_palette(0), 1)

	/' get user text string '/
	Row	= 72 + i * text_height(font) * 4
	Column = 228
	sLen = 0
	clear_keybuf()
	' This section is a mess; got to clear up and comment this someday
	Do
		textout(Screen, font, Chr(127), Column, Row, HIGH_SCORE_COLOR)
		k = LoByte(readkey())
		If (Asc(" ") <= k And k <= 126 And sLen < HIGH_SCORE_TEXT_LEN) Then
			textout(Screen, font, Chr(k), Column, Row, HIGH_SCORE_COLOR)
			HighScore(i).Text[sLen] = Chr(k)
			sLen += 1
			HighScore(i).Text[sLen] = Chr(0)
			Column += text_length(font, "X")
		ElseIf (8 = k And sLen > 0) Then
			textout(Screen, font, " ", Column, Row, HIGH_SCORE_COLOR)
			sLen -= 1
			Column -= text_length(font, "X")
			HighScore(i).Text[sLen] = Chr(0)
		End If
	Loop While (k <> 13)

	/' erase cursor '/
	textout(Screen, font, " ", Column, Row, HIGH_SCORE_COLOR)

	/' fade to black... '/
	fade_out(1)
End Sub


/'
	Function: TitlePage
    Description:
		Displays the Alien Alley title page.
'/
Sub TitlePageDisplay()
	Dim Image As BITMAP Pointer

	/' start title music '/
	MIDIPlay("alienintro.mid")

	/' clear screen '/
	clear_bitmap(Screen)

	/' set everything to black so we can draw without being seen '/
	set_palette(@black_palette(0))

	/' first page of stuff '/
	Image = load_bitmap(ExePath & "/dat/gfx/title.pcx", @GamePalette(0))

	' Stretch bmp to fill the screen
	If (Image <> NULL) Then
		stretch_blit(Image, Screen, 0, 0, Image->w, Image->h, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
		destroy_bitmap(Image)
	End If

	' Fade in
	fade_in(@GamePalette(0), 1)
End Sub


/'
	Function: IntroCredits
    Description:
        Displays the introduction credits.
'/
Sub IntroCreditsDisplay()
	' Clear the screen
	clear_bitmap(Screen)

	/' set everything to black so we can draw without being seen '/
	set_palette(@black_palette(0))

	/' first page of stuff '/
	StringDrawCenter("Coriolis Group Books", 28, INTRO_TEXT_COLOR)
	StringDrawCenter("Presents", 31, INTRO_TEXT_COLOR)
	fade_in(@default_palette(0), 1)
	fade_out(1)

	' Clear the screen
	clear_bitmap(Screen)

	/' second page of stuff '/
	StringDrawCenter("A", 27, INTRO_TEXT_COLOR)
	StringDrawCenter("Dave Roberts", 29, INTRO_TEXT_COLOR)
	StringDrawCenter("Production", 31, INTRO_TEXT_COLOR)
	fade_in(@default_palette(0), 1)
	fade_out(1)
End Sub


/'
	Function: DefaultHighScores
	Description:
		Fills in the HighScore array with some defaults.
		Have fun with this.
'/
Sub HighScoresDefault()
	HighScore(0).Text = "Gill Bates"
	HighScore(0).Score = 1000

	HighScore(1).Text = "Sam Stone"
	HighScore(1).Score = 900

	HighScore(2).Text = "Mad Mike"
	HighScore(2).Score = 800

	HighScore(3).Text = "Fanatic Joe"
	HighScore(3).Score = 700

	HighScore(4).Text = "Joe Dirt"
	HighScore(4).Score = 600

	HighScore(5).Text = "Sonic Hedgehog"
	HighScore(5).Score = 500

	HighScore(6).Text = "Donald Duck"
	HighScore(6).Score = 400

	HighScore(7).Text = "Popeye Sailor"
	HighScore(7).Score = 300

	HighScore(8).Text = "Flash Gordon"
	HighScore(8).Score = 200

	HighScore(9).Text = "John Blade"
	HighScore(9).Score = 100
End Sub


/'
	Function: LoadHighScores
    Description:
    	Loads the high-score file from disk.  If a high-score file
        cannot be found or cannot be read, a default list of
        high-score entries is created.
'/
Sub HighScoresLoad()
	Dim As Integer HighScoreFile, i

	' Load default highscores if there is no highscore file
	If (Not FileExists(HIGH_SCORE_FILENAME)) Then
		HighScoresDefault()
		Return
	End If

	' Open the highscore file; if there is a problem load defaults
	HighScoreFile = FreeFile
	If (Open(HIGH_SCORE_FILENAME For Binary As HighScoreFile) <> 0) Then
		HighScoresDefault()
		Return
	End If

	' Read the name and the scores
	For i = 0 To UBound(HighScore)
		Get #HighScoreFile, , HighScore(i).Text
		Get #HighScoreFile, , HighScore(i).Score
	Next

	' Close file
	Close HighScoreFile
End Sub


/'
	Function: SaveHighScores
    Description:
    	Writes the HighScore array out to the high-score file.
'/
Sub HighScoresSave()
	Dim As Integer HighScoreFile, i

	' Open the file for writing
	HighScoreFile = FreeFile
	If (Open(HIGH_SCORE_FILENAME For Binary As HighScoreFile) <> 0) Then
		' Error; just ignore it
		Return
	End If

	For i = 0 To UBound(HighScore)
		Put #HighScoreFile, , HighScore(i).Text
		Put #HighScoreFile, , HighScore(i).Score
	Next

	Close HighScoreFile
End Sub


/'
	Function: MoveSprites
    Description:
    	Takes care of moving hero ship and alien sprites, based on
        user input and their behavioral algorithms.  MoveSprites
        is also where missiles are generated and off-screen images
        are removed from play.
'/
Sub SpritesMove(ByVal UserInputUp As Boolean, ByVal UserInputDown As Boolean, ByVal UserInputLeft As Boolean, ByVal UserInputRight As Boolean, ByVal UserInputFire As Boolean)
	Dim i As Integer
	Dim AlienFireResult As Integer
	Dim AlienProximity As Integer

	/' first, take care of the hero '/
	If (UserInputUp) Then Hero.p.y -= HERO_Y_VELOCITY
	If (UserInputDown) Then Hero.p.y += HERO_Y_VELOCITY
	If (UserInputLeft) Then Hero.p.x -= HERO_X_VELOCITY
	If (UserInputRight) Then Hero.p.x += HERO_X_VELOCITY

	/' limit player movement '/
	If (Hero.p.y > HeroYMax) Then Hero.p.y = HeroYMax
	If (Hero.p.y < HeroYMin) Then Hero.p.y = HeroYMin
	If (Hero.p.x > HeroXMax) Then Hero.p.x = HeroXMax
	If (Hero.p.x < HeroXMin) Then Hero.p.x = HeroXMin

	/' update hero bounding rect '/
	BoundingRectCompute(Hero.p.x, Hero.p.y, HeroWidth, HeroHeight, Hero.Bounds)

	/' update hero missiles '/
	For i = 0 To MAX_HERO_MISSILES - 1
		If (HeroMissile(i).bDraw) Then
			/' update position '/
			HeroMissile(i).p.y += HeroMissile(i).vy
			' stop drawing when it's off screen
			If (HeroMissile(i).p.y < -(MissileHeight + MissileTrailHeight)) Then
				HeroMissile(i).bDraw = FALSE
			Else
				/' if still onscreen, update bounding rect '/
				BoundingRectCompute(HeroMissile(i).p.x, HeroMissile(i).p.y, MissileWidth, MissileHeight, HeroMissile(i).Bounds)
			End If
		End If
	Next

	/' generate hero missiles '/
	If (UserInputFire And HeroAllowFire And Hero.bDraw) Then
		If (HeroMissileCreate(Hero.p.x + HERO_GUN_OFFSET_LEFT, Hero.p.y + HERO_GUN_OFFSET_UP) And HeroMissileCreate(Hero.p.x + HERO_GUN_OFFSET_RIGHT, Hero.p.y + HERO_GUN_OFFSET_UP)) Then
			SfxPlay(LaserSound, Hero.p.x, Hero.p.y, HeroBitmap)
		End If
		HeroAllowFire = FALSE
	End If

	/' update alien missiles '/
	For i = 0 To MAX_ALIEN_MISSILES - 1
		If (AlienMissile(i).bDraw) Then
			/' update position '/
			AlienMissile(i).p.y += AlienMissile(i).vy
			' stop drawing when it's off screen
			If (AlienMissile(i).p.y > (SCREEN_HEIGHT + MissileHeight + MissileTrailHeight)) Then
				AlienMissile(i).bDraw = FALSE
			Else
				/' if still onscreen, update bounding rect '/
				BoundingRectCompute(AlienMissile(i).p.x, AlienMissile(i).p.y, MissileWidth, MissileHeight, AlienMissile(i).Bounds)
			End If
		End If
	Next

	/' move aliens '/
	For i = 0 To MAX_ALIENS - 1
		If (Alien(i).bDraw) Then
			If (Alien(i).ObjectSpec1 = 0) Then
				/' pick a new direction '/
				Alien(i).vx = IIf(Int(Timer) Mod 2, Rnd * ALIEN_X_VELOCITY, Rnd * -ALIEN_X_VELOCITY)
				Alien(i).ObjectSpec1 = ALIEN_MOVE_TIME_BASE + Rnd * ALIEN_MOVE_TIME_VAR
			Else
				Alien(i).ObjectSpec1 -= 1
			End If
			/' update alien position '/
			Alien(i).p.x += Alien(i).vx
			Alien(i).p.y += Alien(i).vy

			/' clip alien movement horizontally '/
			If (Alien(i).p.x < 0) Then Alien(i).p.x = 0
			If (Alien(i).p.x > SCREEN_WIDTH - AlienWidth) Then Alien(i).p.x = SCREEN_WIDTH - AlienWidth

			/' move alien to top when it gets to bottom '/
			If (Alien(i).p.y > SCREEN_HEIGHT + AlienHeight) Then Alien(i).p.y = -AlienHeight

			/' update alien bouding rect '/
			BoundingRectCompute(Alien(i).p.x, Alien(i).p.y, AlienWidth, AlienHeight, Alien(i).Bounds)

			/' generate alien missiles '/
			If (Alien(i).ObjectSpec2 = 0) Then
				AlienFireResult	= Rnd * 100	/' in percent '/
				AlienProximity = Alien(i).p.x - Hero.p.x

				If (AlienProximity < 0) Then AlienProximity = -AlienProximity

				If (((AlienProximity < ALIEN_PROX_THRESHOLD) And (AlienFireResult < ALIEN_FIRE_PROB_HERO)) Or (AlienFireResult < ALIEN_FIRE_PROB_RANDOM)) Then
					AlienMissileCreate(Alien(i).p.x + ALIEN_GUN_OFFSET_LEFT, Alien(i).p.y + ALIEN_GUN_OFFSET_DOWN)
					AlienMissileCreate(Alien(i).p.x + ALIEN_GUN_OFFSET_RIGHT, Alien(i).p.y + ALIEN_GUN_OFFSET_DOWN)
					Alien(i).ObjectSpec2 = ALIEN_FIRE_LOCKOUT
					SfxPlay(LaserSound, Alien(i).p.x, Alien(i).p.y, AlienBitmap)
				End If
			Else
				Alien(i).ObjectSpec2 -= 1
			End If
		End If
	Next

	/' generate aliens '/
	If (AlienGenCounter = 0) Then
		/' generate an alien '/
		AlienCreate()
		/' reinit generate counter '/
		AlienGenCounter = ALIEN_GEN_RATE_BASE + Rnd * ALIEN_GEN_RATE_VAR
	Else
		AlienGenCounter -= 1
	End If

	' update explosions -- note, we don't really "move" them, just make the animation go
	For i = 0 To MAX_EXPLOSIONS - 1
		If (Explosion(i).bDraw) Then
			If (Explosion(i).ObjectSpec2 = 0) Then
				Explosion(i).ObjectSpec1 += 1
				Explosion(i).ObjectSpec2 = EXPLOSION_FRAME_REPEAT_COUNT
				If (Explosion(i).ObjectSpec1 >= MAX_EXPLOSION_BITMAPS) Then Explosion(i).bDraw = FALSE
			Else
				Explosion(i).ObjectSpec2 -= 1
			End If
		End If
	Next

	' Check at what speed the map needs to be scrolled
	MapScrollStep = IIf(UserInputUp, MAP_SCROLL_STEP_FAST, MAP_SCROLL_STEP_NORMAL)
End Sub


/'
	Function: CheckCollisions
    Description:
    	Check for collisions between various objects and start
        explosions if they collide.  Collision detection is
        performed between:
        	* aliens and hero
            * aliens and hero missiles
			* hero and alien missiles
        Note that all tests are performed between objects that are
        currently being drawn, not just active objects.
'/
Sub CollisionsCheck()
	Dim As Integer i, j

	/' check between hero and aliens '/
	For i = 0 To MAX_ALIENS - 1
		/' Use C short circuit boolean evaluation in a big way. '/
		/' Make sure both hero and alien are still being drawn '/
		/' (they may still be active but have been removed '/
		/' from the screen and are just being erased). '/
		/' If they are still onscreen, then perform a rectangle test. '/
		/' If the rectangle collision indicates a possible hit, then '/
		/' perform a bitmap test. '/
		If (Hero.bDraw AndAlso Alien(i).bDraw AndAlso CollisionTest(HeroBitmap, Hero.p, AlienBitmap, Alien(i).p)) Then
			Hero.bDraw = FALSE
			ExplosionCreate(Hero.p.x, Hero.p.y)
			Alien(i).bDraw = FALSE
			ExplosionCreate(Alien(i).p.x, Alien(i).p.y)
			SfxPlay(ExplosionSound, Alien(i).p.x, Alien(i).p.y, ExplosionBitmap(0))
		End If
	Next

	/' check between aliens and hero missiles '/
	For i = 0 To MAX_ALIENS - 1
		If (Not Alien(i).bDraw) Then Continue For

		For j = 0 To MAX_HERO_MISSILES - 1
			/' do similiar short circuit, mondo huge test as above '/
			If (HeroMissile(j).bDraw AndAlso CollisionTest(AlienBitmap, Alien(i).p, MissileBitmap, HeroMissile(j).p)) Then
				Alien(i).bDraw = FALSE
				HeroMissile(j).bDraw = FALSE
				ExplosionCreate(Alien(i).p.x, Alien(i).p.y)
				Score += POINTS_PER_ALIEN
				SfxPlay(ExplosionSound, Alien(i).p.x, Alien(i).p.y, ExplosionBitmap(0))
				Exit For /' alien is destroyed '/
			End If
		Next
	Next

	/' check between hero and alien missiles '/
	For i = 0 To MAX_ALIEN_MISSILES - 1
		/' again, rely on short circuiting '/
		If (AlienMissile(i).bDraw AndAlso Hero.bDraw AndAlso CollisionTest(MissileBitmap, AlienMissile(i).p, HeroBitmap, Hero.p)) Then
			AlienMissile(i).bDraw = FALSE	/' destroy missile in any case '/
			If (HeroShields <= 0) Then
				Hero.bDraw = FALSE
				ExplosionCreate(Hero.p.x, Hero.p.y)
				SfxPlay(ExplosionSound, Hero.p.x, Hero.p.y, ExplosionBitmap(0))
				Exit For	/' hero is destroyed '/
			Else
				/' take away a bit of shields '/
				HeroShields -= 5
				If (HeroShields < 0) Then HeroShields = 0
			End If
		End If
	Next
End Sub


/'
	Function: EraseSprites
    Description:
    	Erase all current bitmaps from the hidden screen.  If the
        erasure marks the last time that the object will be erased
        because it is no longer being drawn, deactivate the object.
'/
Function SpritesErase() As Boolean
	Dim i As Integer
	Static DeathCounter As UInteger

	/' do player and possibly deactivate '/
	If (Hero.Active) Then
		If (Not Hero.bDraw) Then
			Hero.Active = FALSE
			DeathCounter = DEATH_DELAY
		End If
	End If

	/' erase and deactivate hero missiles '/
	For i = 0 To MAX_HERO_MISSILES - 1
		' deactivate missile if we aren't going to draw or erase it anymore
		If (Not HeroMissile(i).bDraw) Then
			HeroMissile(i).Active = FALSE
		End If
	Next

	/' erase and deactivate aliens '/
	For i = 0 To MAX_ALIENS - 1
		' deactive alien if it's been destroyed
		If (Not Alien(i).bDraw ) Then
			Alien(i).Active = FALSE
		End If
	Next

	/' erase and deactivate alien missiles '/
	For i = 0 To MAX_ALIEN_MISSILES - 1
		' deactivate missile if we aren't going to draw or erase it anymore
		If (Not AlienMissile(i).bDraw) Then
			AlienMissile(i).Active = FALSE
		End If
	Next

	/' erase and deactivate explosions '/
	For i = 0 To MAX_EXPLOSIONS - 1
		/' deactivate if explosion has run its course '/
		If (Not Explosion(i).bDraw) Then
			Explosion(i).Active = FALSE
		End If
	Next

	/' hero has died -- signal game over after brief delay '/
	If (Not Hero.Active) Then
		If (DeathCounter = 0) Then
			Return TRUE
		Else
			DeathCounter -= 1
		End If
	End If

	Return FALSE
End Function


/'
	Function: DrawSprites
    Description:
    	Draw all active objects that should be drawn on the
        screen.
'/
Sub SpritesDraw()
	Dim i As Integer

	/' do explosions '/
	For i = 0 To MAX_EXPLOSIONS - 1
		If (Explosion(i).bDraw) Then
			/' draw explosion '/
			draw_sprite(FrameBuffer, ExplosionBitmap(Explosion(i).ObjectSpec1), Explosion(i).p.x, Explosion(i).p.y)
		End If
	Next

	/' draw hero missiles '/
	For i = 0 To MAX_HERO_MISSILES - 1
		If (HeroMissile(i).bDraw) Then
			/' draw missile itself '/
			draw_sprite(FrameBuffer, MissileBitmap, HeroMissile(i).p.x, HeroMissile(i).p.y)
			/' draw missile trail '/
			draw_sprite(FrameBuffer, MissileTrailUpBitmap, HeroMissile(i).p.x, HeroMissile(i).p.y + MissileBitmap->h)
		End If
	Next

	/' draw alien missiles '/
	For i = 0 To MAX_ALIEN_MISSILES - 1
		If (AlienMissile(i).bDraw) Then
			/' draw missile itself '/
			draw_sprite(FrameBuffer, MissileBitmap, AlienMissile(i).p.x, AlienMissile(i).p.y)
			/' draw missile trail '/
			draw_sprite(FrameBuffer, MissileTrailDnBitmap, AlienMissile(i).p.x, AlienMissile(i).p.y - MissileTrailDnBitmap->h)
		End If
	Next

	/' do aliens '/
	For i = 0 To MAX_ALIENS - 1
		If (Alien(i).Active And Alien(i).bDraw) Then
			draw_sprite(FrameBuffer, AlienBitmap, Alien(i).p.x, Alien(i).p.y)
		End If
	Next

	/' do player '/
	If (Hero.Active And Hero.bDraw) Then
		draw_sprite(FrameBuffer, HeroBitmap, Hero.p.x, Hero.p.y)
	End If

	/' blink the guns '/
	If (GunBlinkCounter = 0) Then
		If (GunBlinkState) Then
			set_color(GUN_COLOR, @black_palette(0))
		Else
			set_color(GUN_COLOR, @GunColor)
		End If
		GunBlinkState = Not GunBlinkState /' flip it to other state '/
		GunBlinkCounter = GUN_BLINK_RATE
		HeroAllowFire = TRUE
	Else
		GunBlinkCounter -= 1
	End If
End Sub


/'
	Function: ProgramInit
	Description:
		Performs all the program-wide initialization at start-up
		time.  This includes sensing the presence of alternate input
		devices and ensuring they are calibrated.
'/
Sub ProgramInitialize()
	' Initialize some stuff
	Randomize Timer

	' Initialize Allegro
	allegro_init()

	' Initialize the timer
	install_timer()

	' Initialize the keyboard
	install_keyboard()

	' Initialize the mouse
	install_mouse()

	/' Initialize the sound and stuff '/
	install_sound(DIGI_AUTODETECT, MIDI_AUTODETECT, NULL)

	' Set the Window title
	set_window_title("Alien Alley")

	' Set screen properties
	set_color_depth(8)

	/' get into graphics '/
	set_gfx_mode(GFX_AUTODETECT_WINDOWED, SCREEN_WIDTH, SCREEN_HEIGHT, 0, 0)

	/' initialize palette '/
	set_palette(@black_palette(0))

	' Load sound fx and music
	SoundInitialize()

	/' load high-score file '/
	HighScoresLoad()
End Sub


Sub ProgramFinalize()
	' Save high scores
	HighScoresSave()

	' Release sound resources (esp. MIDI here)
	SoundFinalize()

	' Clean up Allegro stuff
	allegro_exit()
End Sub


/'
	Function: Play
    Description:
    	Play the game!
'/
Sub Play()
	Dim As Boolean UserInputUp, UserInputDown, UserInputLeft, UserInputRight, UserInputFire
	Dim As Boolean GameOver, GameOverInput, GameOverDeath

	/' initialize all counters, etc. '/
	Score = 0
	AlienGenCounter = ALIEN_GEN_RATE_BASE
	HeroShields = MAX_HERO_SHIELDS

	FrameBufferInitialize()
	MapInitialize()
	HUDInitialize()
	SpritesInitialize()

	' Load game palette
	set_palette(@GamePalette(0))

	' Play the in-game music
	MIDIPlay("alienmain.mid")

	' Install our timer interrupt
	install_int_ex(@Ticker, BPS_TO_TIMER(UPDATES_PER_SECOND))

	/' Initialize some variables and enter main animation loop '/
	Ticks = 0
	GameOver = FALSE

	Do
		If (Ticks > 0) Then
			/' get user input '/
			GameOverInput = InputPoll(UserInputUp, UserInputDown, UserInputLeft, UserInputRight, UserInputFire)

			/' move sprites '/
			SpritesMove(UserInputUp, UserInputDown, UserInputLeft, UserInputRight, UserInputFire)

			/' check for collisions '/
			CollisionsCheck()

			/' erase '/
			GameOverDeath = SpritesErase()

			/' scroll screen '/
			MapScroll()

			' Draw map
			MapDraw()

			/' draw '/
			SpritesDraw()

			' Draw HUD
			HUDDraw()

			/' Page flip '/
			FrameBufferFlip()

			Ticks -= 1
		Else
			rest(0)
		End If

		/' player either aborts or dies '/
		GameOver = GameOverInput Or GameOverDeath
	Loop While (Not GameOver)

	' Remove timer interrupt
	remove_int(@Ticker)

	SpritesFinalize()
	HUDFinalize()
	MapFinalize()
	FrameBufferFinalize()

	/' fade to black... '/
	fade_out(1)
End Sub


/'
	Function: main
    Description:
    	Main program loop.  Init's the program, draws intro screens
        and title pages, and waits for user to hit keystroke
		to indicated what they want to do.
'/
Function Main() As Integer
	Dim Quit As Boolean = FALSE
	Dim DrawTitle As Boolean = TRUE
	Dim k As UByte

	' Initialize everything we need
	ProgramInitialize()

	' Display the into credits screen
	IntroCreditsDisplay()

	' Main menu loop
	While (Not Quit)
		' Draw title page (only if required)
		If (DrawTitle) Then
			TitlePageDisplay()
			DrawTitle = FALSE
		End If

		' Read the key and mask the scancode
		clear_keybuf()
		k = LoByte(readkey())

		' Check what key was press and action it
		Select Case k
			Case 27, Asc("q"), Asc("Q")
				Quit = TRUE
			Case Asc("k"), Asc("K"), Asc("m"), Asc("M"), Asc("j"), Asc("J"), 13
				Play()
				HighScoresNew(Score)
				DrawTitle = TRUE
			Case Asc("s"), Asc("S")
				HighScoresScreenDisplay()
				DrawTitle = TRUE
			Case Else
				DrawTitle = FALSE
		End Select
	Wend

	' Fade out
	fade_out(1)

	' Release all resources
	ProgramFinalize()

	Return 0
End Function


' Program entry point
End Main()
