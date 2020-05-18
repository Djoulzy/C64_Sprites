VIC_bank_sel    = $DD00   ; Genralement Bank 0 ou 2 (#$00 ou #$02)

;Register            Description                     Comment
;$D000 (53248)       X-Coordinate Sprite#0           Sets vertical line position of Sprite#0 considering Bit#0 in $D010
;$D001 (53249)       Y-Coordinate Sprite#0           Sets horizontal position of Sprite#0
;$D002 (53250)       X-Coordinate Sprite#1           Sets vertical line position of Sprite#1 considering Bit#1 in $D010
;$D003 (53251)       Y-Coordinate Sprite#1           Sets horizontal position of Sprite#1
;$D004 (53252)       X-Coordinate Sprite#2           Sets vertical line position of Sprite#2 considering Bit#2 in $D010
;$D005 (53253)       Y-Coordinate Sprite#2           Sets horizontal position of Sprite#2
;$D006 (53254)       X-Coordinate Sprite#3           Sets vertical line position of Sprite#3 considering Bit#3 in $D010
;$D007 (53255)       Y-Coordinate Sprite#3           Sets horizontal position of Sprite#3
;$D008 (53256)       X-Coordinate Sprite#4           Sets vertical line position of Sprite#4 considering Bit#4 in $D010
;$D009 (53257)       Y-Coordinate Sprite#4           Sets horizontal position of Sprite#4
;$D00A (5325a)       X-Coordinate Sprite#5           Sets vertical line position of Sprite#5 considering Bit#5 in $D010
;$D00B (53259)       Y-Coordinate Sprite#5           Sets horizontal position of Sprite#5
;$D00C (53260)       X-Coordinate Sprite#6           Sets vertical line position of Sprite#6 considering Bit#6 in $D010
;$D00D (53261)       Y-Coordinate Sprite#6           Sets horizontal position of Sprite#6
;$D00E (53262)       X-Coordinate Sprite#7           Sets vertical line position of Sprite#7 considering Bit#7 in $D010
;$D00F (53263)       Y-Coordinate Sprite#7           Sets horizontal position of Sprite#7
;$D010 (53264)       Bit#9 for X-Coordinates         As the C64 screen has more than 255 lines each Bit represents the required 9th Bit to get pass the number 255 for each Sprite X-Coordinate
;$D011 (53265)       Control Register #1             Initial Value: %10011011
;                                                        Bit responsibilities:
;                                                        Bit#0-#2: Screen Soft Scroll Vertical
;                                                        Bit#3: Switch betweem 25 or 24 visible rows
;                                                        Bit#4: Switch VIC-II output on/off
;                                                        Bit#5: Turn Bitmap Mode on/off
;                                                        Bit#6: Turn Extended Color Mode on/off
;                                                        Bit#7: 9th Bit for $D012 Rasterline counter
;$D012 (53266)       Raster Counter                  When Reading:Return current Rasterline
;                                                    When Writing:Define Rasterline for Interrupt triggering
;                                                        Bit#7 of $D011 is (to be) set if line number exceeds 255
;$D013 (53267)       Light Pen X-Coordinate          Light Pen X-Coordinate
;$D014 (53268)       Light Pen Y-Coordinate          Light Pen Y-Coordinate
;$D015 (53269)       Sprite Enable Register          Each Bit corresponds to a Sprite.
;                                                        If set high the corresponding Sprite is enabled on Screen
;$D016 (53270)       Control Register 2              Initial Value: %00001000
;                                                        Bit responsibilities:
;                                                        Bit#0-#2: Screen Soft Scroll Horizontal
;                                                        Bit#3: Switch betweem 40 or 38 visible columns
;                                                        Bit#4: Turn Multicolor Mode on/off
;                                                        Bit#5-#7: not used
;$D017 (53271)       Sprite Y Expansion              Every Bit corresponds to one Sprite. If set high, the Sprite will be stretched vertically x2
;$D018 (53272)       VIC-II base addresses           Initial Value: %00010100
;                                                        Bit responsibilities:
;                                                        Bit#0: not used
;                                                        Bit#1-#3: Address Bits 11-13 of the Character Set (*2048)
;                                                        Bit#4-#7: Address Bits 10-13 of the Screen RAM (*1024)
;$D019 (53273)       Interrupt Request Register      Initial Value: %00001111
;                                                        Bit responsibilities:
;                                                        Bit#0: Interrupt by Rasterline triggered when high
;                                                        Bit#1: Interrupt by Spite-Background collision triggered when high
;                                                        Bit#2: Interrupt by Sprite-Sprite collision triggered when high
;                                                        Bit#3: Interrupt by Lightpen impulse triggered when high
;                                                        Bit#4-#6: not used
;                                                        Bit#7: If set high at least one of the Interrupts above were triggered
;$D01A (53274)       Interrupt Mask Register         Initial Value: %00000000
;                                                        Bit responsibilities:
;                                                        Bit#0: Request Interrupt by Rasterline by setting high
;                                                        Bit#1: Request Interrupt by Spite-Background collision by setting high
;                                                        Bit#2: Request Interrupt by Sprite-Sprite collision by setting high
;                                                        Bit#3: Request Interrupt by Lightpen impulse by setting high
;                                                        Bit#4-#7: not used
;$D01B (53275)       Sprite Collision Priority       Each Bit corresponds to a Sprite. If set high, the Background overlays the Sprite, if set low, the Sprite overlays Background.
;$D01C (53276)       Sprite Multicolor               Each Bit correspondents to a Sprite. If set high, the Sprite is considered to be a Multicolor-Sprite
;$D01D (53277)       Sprite X Expansion              Each Bit corresponds to a Sprite. If set high, the Sprite will be stretched horzontally x2
;$D01E (53278)       Sprite-Sprite Collision         Each Bit corresponds to a Sprite. If two sprites collide, then corresponding Bits involved in the collision are set to high. This event will also set Bit#2 of the Interrupt Request Register high.
;$D01F (53279)       Sprite-Background Collision     Each Bit corresponds to a Sprite. If a sprite collides with the backgroud, then its Bit is set to high. This event will also set Bit#1 of the Interrupt Request Register high.
;$D020 (53280)       Border color                    Set Border Color to one of the 16 Colors ($00-$0F)
;$D021 (53281)       Background Color 0              Set Background Color 0 to one of the 16 Colors ($00-$0F)
;$D022 (53282)       Background Color 1              Set Background Color 1 to one of the 16 Colors ($00-$0F)
;$D023 (53283)       Background Color 2              Set Background Color 2 to one of the 16 Colors ($00-$0F)
;$D024 (53284)       Background Color 3              Set Background Color 3 to one of the 16 Colors ($00-$0F)
;$D025 (53285)       Sprite Multicolor 0             Set Color 1 shared by Multicolor Sprites
;$D026 (53286)       Sprite Multicolor 1             Set Color 2 shared by Multiclor Sprites
;$D027 (53287)       Color Sprite#0                  Set individual color for Sprite#0
;$D028 (53288)       Color Sprite#1                  Set individual color for Sprite#1
;$D029 (53289)       Color Sprite#2                  Set individual color for Sprite#2
;$D02A (53290)       Color Sprite#3                  Set individual color for Sprite#3
;$D02B (53291)       Color Sprite#4                  Set individual color for Sprite#4
;$D02C (53292)       Color Sprite#5                  Set individual color for Sprite#5
;$D02D (53293)       Color Sprite#6                  Set individual color for Sprite#6
;$D02E (53294)       Color Sprite#7                  Set individual color for Sprite#7