
Turbo Macro Pro v1.2 mod for Retro Replay 3.8b/3.8P
---------------------------------------------------
This text describes how to modify the Cyberpunx Retro Replay 3.8b cartridge 
software to load a custom assembler when invoking the TASS BASIC command.
More specifically it shows how to replace the Turbo Assembler contained in the 
cartridge with Turbo Macro Pro v1.2 from Style (http://turbo.style64.org).

A patched binary based on the 3.8P ROM has been included in this archive. It
contains the plain version of TMP v1.2. The only modifications to the TMP in
this image are the colors and the F6 key which has been re-mapped to the
delete-line command. Both of these settings are configurable using TMPPREFS on
the TMP binary.

In the following the offsets refer to the Retro Replay 3.8b ROM Image and are
also compatible with the 3.8P patched version by hannenz.


What TASS Does
--------------
The code loaded and started when entering TASS in BASIC is located at offset 
$800F:

   Offset  OpCodes    Mnemonics
   ----------------------------
   $800F   4C 28 80   JMP $8028
   ---
   $8028   A9 0B      LDA #$0B
   $802a   8D 11 D0   STA $D011
   $802d   A2 6A      LDX #$6A
   $802f   BD 39 80   LDA $8039,X
   $8032   9D 00 04   STA $0400,X
   $8035   CA         DEX
   $8036   10 F7      BPL $802F
   $8038   60         RTS

This copies the code at offset $8039-$80A2 to memory address $0400 and jumps to 
$0400 upon RTS (stack manipulation)

The code copied is:

   Offset  OpCodes    Mnemonics
   ----------------------------
   $8039   78         SEI
   $803a   A9 37      LDA #$37
   $803c   85 01      STA $01
   $803e   A9 90      LDA #$90
   $8040   85 AF      STA $AF
   $8042   A9 00      LDA #$00
   $8044   85 AE      STA $AE
   $8046   A9 88      LDA #$88    ;RR Bank 5
   $8048   8D 00 DE   STA $DE00
   $804b   A2 04      LDX #$04
   $804d   A0 00      LDY #$00
   $804f   B9 00 81   LDA $8100,Y
   $8052   91 AE      STA ($AE),Y
   $8054   C8         INY
   $8055   D0 F8      BNE $804F
   $8057   EE 18 04   INC $0418
   $805a   E6 AF      INC $AF
   $805c   CA         DEX
   $805d   10 F0      BPL $804F
   $805f   A9 90      LDA #$90    ;RR Bank 6
   $8061   8D 00 DE   STA $DE00
   $8064   A2 1C      LDX #$1C
   $8066   A0 00      LDY #$00
   $8068   B9 00 81   LDA $8100,Y
   $806b   91 AE      STA ($AE),Y
   $806d   C8         INY
   $806e   D0 F8      BNE $8068
   $8070   EE 31 04   INC $0431
   $8073   E6 AF      INC $AF
   $8075   CA         DEX
   $8076   10 F0      BPL $8068
   $8078   A9 98      LDA #$98    ;RR Bank 7
   $807a   8D 00 DE   STA $DE00
   $807d   A2 1C      LDX #$1C
   $807f   A0 00      LDY #$00
   $8081   B9 00 81   LDA $8100,Y
   $8084   91 AE      STA ($AE),Y
   $8086   C8         INY
   $8087   D0 F8      BNE $8081
   $8089   EE 4A 04   INC $044A
   $808c   E6 AF      INC $AF
   $808e   CA         DEX
   $808f   10 F0      BPL $8081
   $8091   A9 0A      LDA #$0A
   $8093   8D 00 DE   STA $DE00
   $8096   A9 37      LDA #$37
   $8098   85 01      STA $01
   $809a   A9 1B      LDA #$1B
   $809c   8D 11 D0   STA $D011
   $809f   58         CLI
   $80a0   4C 00 90   JMP $9000

Upon execution from address $0400 this code copies offsets:
  $A100-$A5FF (RR bank 5) to memory location $9000-$94FF
  $C100-$DDFF (RR bank 6) to memory location $9500-$B1FF
  $E100-$FDFF (RR bank 7) to memory location $B200-$CEFF

Finally it jumps to address $9000 to start TASS



How to Patch It
---------------
Turbo Macro Pro v1.2 comes in different versions and takes up a bit more space 
than the old Turbo Assembler. The start address is $8000 instead of $9000 and 
its end address depends on what version you choose. All current versions can be 
contained within $8000-$CAFF though and it seems to store its variables at $CB00 
so it should be OK to just modify the above code to copy the new Turbo Macro Pro 
into $8000-$CAFF and then jump to $8000.

Fortunately there are still some free pages in the Retro Replay ROM image to 
contain the extra code. A couple of these are at offsets $7800 and $B700

So we can place the new Turbo Macro Pro image at the following locations:

  $A100-$A7FF (RR bank 5) destination memory location $8000-$86FF
  $C100-$DDFF (RR bank 6) destination memory location $8700-$A3FF
  $E100-$FDFF (RR bank 7) destination memory location $A400-$C0FF
  $B700-$BDFF (RR bank 5) destination memory location $C100-$C7FF
  $7800-$7AFF (RR bank 3) destination memory location $C800-$CAFF


The following code copies the new data to the new memory location:

   Address OpCodes    Mnemonics
   ----------------------------
   $0400   78         SEI
   $0401   A9 37      LDA #$37
   $0403   85 01      STA $01
   $0405   A9 80      LDA #$80
   $0407   85 AF      STA $AF
   $0409   A9 00      LDA #$00
   $040b   85 AE      STA $AE
   $040d   A9 88      LDA #$88    ;RR Bank 5
   $040f   8D 00 DE   STA $DE00
   $0412   A2 06      LDX #$06
   $0414   A0 00      LDY #$00
   $0416   B9 00 81   LDA $8100,Y
   $0419   91 AE      STA ($AE),Y
   $041b   C8         INY
   $041c   D0 F8      BNE $0416
   $041e   EE 18 04   INC $0418
   $0421   E6 AF      INC $AF
   $0423   CA         DEX
   $0424   10 F0      BPL $0416
   $0426   A9 90      LDA #$90    ;RR Bank 6
   $0428   8D 00 DE   STA $DE00
   $042b   A2 1C      LDX #$1C
   $042d   A0 00      LDY #$00
   $042f   B9 00 81   LDA $8100,Y
   $0432   91 AE      STA ($AE),Y
   $0434   C8         INY
   $0435   D0 F8      BNE $042F
   $0437   EE 31 04   INC $0431
   $043a   E6 AF      INC $AF
   $043c   CA         DEX
   $043d   10 F0      BPL $042F
   $043f   A9 98      LDA #$98    ;RR Bank 7
   $0441   8D 00 DE   STA $DE00
   $0444   A2 1C      LDX #$1C
   $0446   A0 00      LDY #$00
   $0448   B9 00 81   LDA $8100,Y
   $044b   91 AE      STA ($AE),Y
   $044d   C8         INY
   $044e   D0 F8      BNE $0448
   $0450   EE 4A 04   INC $044A
   $0453   E6 AF      INC $AF
   $0455   CA         DEX
   $0456   10 F0      BPL $0448
   $0458   A9 88      LDA #$88    ;RR Bank 5
   $045a   8D 00 DE   STA $DE00
   $045d   A2 06      LDX #$06
   $045f   A0 00      LDY #$00
   $0461   B9 00 97   LDA $9700,Y
   $0464   91 AE      STA ($AE),Y
   $0466   C8         INY
   $0467   D0 F8      BNE $0461
   $0469   EE 63 04   INC $0463
   $046c   E6 AF      INC $AF
   $046e   CA         DEX
   $046f   10 F0      BPL $0461
   $0471   A9 18      LDA #$18    ;RR Bank 3
   $0473   8D 00 DE   STA $DE00
   $0476   A2 02      LDX #$02
   $0478   A0 00      LDY #$00
   $047a   B9 00 98   LDA $9800,Y
   $047d   91 AE      STA ($AE),Y
   $047f   C8         INY
   $0480   D0 F8      BNE $047A
   $0482   EE 7C 04   INC $047C
   $0485   E6 AF      INC $AF
   $0487   CA         DEX
   $0488   10 F0      BPL $047A
   $048a   A9 0A      LDA #$0A
   $048c   8D 00 DE   STA $DE00
   $048f   A9 37      LDA #$37
   $0491   85 01      STA $01
   $0493   A9 1B      LDA #$1B
   $0495   8D 11 D0   STA $D011
   $0498   58         CLI
   $0499   4C 00 80   JMP $8000

Note: The code is self-modifying and is here shown at its correct origin.


This new code takes up a bit more space than the old one so we cannot just 
overwrite the old with the new. Instead we can place it somewhere else in the 
same RR bank. Offset $8121 fulfills our requirements.

The code that copies the above code into address $0400 now needs to be changed 
as well. This is located at offset $8028. The new code looks like this:

   Offset  OpCodes    Mnemonics
   ----------------------------
   $8028   A9 0B      LDA #$0B
   $802a   8D 11 D0   STA $D011
   $802d   A2 00      LDX #$00
   $802f   BD 21 81   LDA $8121,X   ;New location
   $8032   9D 00 04   STA $0400,X
   $8035   E8         INX
   $8036   D0 F7      BNE $802F
   $8038   60         RTS


Now all we need is to split the Turbo Macro Pro into 5 pieces. Use your favorite 
HEX Editor like this:

  Part1: Take offset $0000-$06FF from TMP and put in $A100-$A7FF in RR ROM
  Part2: Take offset $0700-$23FF from TMP and put in $C100-$DDFF in RR ROM
  Part3: Take offset $2400-$40FF from TMP and put in $E100-$FDFF in RR ROM
  Part4: Take offset $4100-$47FF from TMP and put in $B700-$BDFF in RR ROM
  Part5: Take offset $4800-$4DFF from TMP and put in $7800-$7AFF in RR ROM

Note: Remember to remove the load address, i.e. strip the two first bytes of the
      Turbo Macro Pro PRG file before referring to the list above!


Changing the configuration of TMP 1.2
--------------------------------------
In the event you whish to customize the default settings for TMP 1.2 they are
located in the TMP binary at offset $001B (excluding the load address) which
should correspond to $A11B in your newly patched ROM:

   $A11B Border color
   $A11C Screen color
   $A11D Command Line color
   $A11E Status Line color
   $A11F Text color
   $A120 Error color
   $A121 Marked color
   $A122 Source tab column
   $A123 Return tab column


Patched Version
---------------
Following the well know 35-year old bug of Turbo Assembler series (spotted in "8-Bit Show And Tell" 
https://www.youtube.com/watch?v=bDbpntumA6A&list=PLvW2ZMbxgP9z9Un4LXivII_D1Hh5gZ7r9&index=6)
Robin has prepared patched version of this ROM. Patched disk version of TMP 1.2 can be found on: 
https://csdb.dk/release/?id=182920


  How to reproduce the bug: 
  -------------------------
   The buggy version can be detected by entering in TMP 1.2 (or in previous predecessors)

   sta 1272 ; which will be "corrected" to "sta 1273"   


  Fix:   
  ----
   The fix was made on offeset $7985: 

      replace 00 00 00 00 00 00 with: 18 65 39 85 39 60 
    
   And on $E82F:

      replace 65 39 85 39 with 20 85 c9 EA

   Reference Link: https://www.youtube.com/watch?v=bDbpntumA6A&list=PLvW2ZMbxgP9z9Un4LXivII_D1Hh5gZ7r9&index=6)
   
Enjoy!

Devia/Ancients - 2006.10.12
Plum/Hokuto Force - 2020.11.06

