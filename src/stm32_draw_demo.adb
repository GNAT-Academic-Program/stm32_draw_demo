------------------------------------------------------------------------------
--                                                                          --
--                  Copyright (C) 2015-2017, AdaCore                        --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of the copyright holder nor the names of its     --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
------------------------------------------------------------------------------

--  A simple example that blinks all the LEDs simultaneously, w/o tasking.
--  It does not use the various convenience functions defined elsewhere, but
--  instead works directly with the GPIO driver to configure and control the
--  LEDs.

--  Note that this code is independent of the specific MCU device and board
--  in use because we use names and constants that are common across all of
--  them. For example, "All_LEDs" refers to different GPIO pins on different
--  boards, and indeed defines a different number of LEDs on different boards.
--  The gpr file determines which board is actually used.

with STM32.Board;           use STM32.Board;
with HAL.Bitmap;            use HAL.Bitmap;
with HAL.Touch_Panel;       use HAL.Touch_Panel;
with BMP_Fonts;
with Ada.Real_Time; use Ada.Real_Time;

with Bitmapped_Drawing;
with Bitmap_Color_Conversion; use Bitmap_Color_Conversion;

with HAL.Framebuffer;

procedure Stm32_Draw_Demo is

   BG : constant Bitmap_Color := (Alpha => 255, others => 64);
   FG : constant Bitmap_Color := (Alpha => 255, others => 255);

   procedure Clear;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      Display.Hidden_Buffer (1).Set_Source (BG);
      Display.Hidden_Buffer (1).Fill;

      Bitmapped_Drawing.Draw_String
        (Display.Hidden_Buffer (1).all, 
         Start => (0, 0),
         Msg => "Hello, world!", 
         Font => BMP_Fonts.Font8x8,
         Foreground => FG,
         Background => BG);

      Display.Update_Layer (1, Copy_Back => True);
   end Clear;

   Last_X : Integer := -1;
   Last_Y : Integer := -1;
   Curr_X : Natural := 0;
   Curr_Y : Natural := 0;

   type Mode is (Drawing_Mode, Bitmap_Showcase_Mode);

   Current_Mode : Mode := Drawing_Mode;

begin

   Display.Initialize;
   Display.Set_Orientation (HAL.Framebuffer.Landscape);
   Display.Initialize_Layer (1, ARGB_8888);

   Touch_Panel.Initialize;

   Clear;

   loop
      declare
         State : constant TP_State := Touch_Panel.Get_All_Touch_Points;
      begin
         if Current_Mode = Drawing_Mode then

            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Green);

            if State'Length = 0 then
               Last_X := -1;
               Last_Y := -1;
            elsif State'Length = 1 then
               Curr_X := State (State'First).X;
               Curr_Y := State (State'First).Y;
               Display.Hidden_Buffer (1).Fill_Rounded_Rect
               (((Curr_X, Curr_Y), 40, 40), 20);
            elsif State'Length = 2 then
               Current_Mode := Bitmap_Showcase_Mode;
            else
               Last_X := -1;
               Last_Y := -1;
            end if;

            for Id in State'Range loop
               Fill_Circle
               (Display.Hidden_Buffer (1).all,
                  Center => (State (Id).X, State (Id).Y),
                  Radius => State (Id).Weight / 4);
            end loop;

            if State'Length > 0 then
               Display.Update_Layer (1, Copy_Back => True);
            end if;
         else

            --  Show some of the supported drawing primitives

            Display.Hidden_Buffer (1).Set_Source (Black);
            Display.Hidden_Buffer (1).Fill;

            Display.Hidden_Buffer (1).Set_Source (Green);
            Display.Hidden_Buffer (1).Fill_Rounded_Rect
            (((10, 10), 100, 100), 20);

            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Red);
            Display.Hidden_Buffer (1).Draw_Rounded_Rect
            (((10, 10), 100, 100), 20, Thickness => 4);

            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Yellow);
            Display.Hidden_Buffer (1).Fill_Circle ((60, 60), 20);

            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Blue);
            Display.Hidden_Buffer (1).Draw_Circle ((60, 60), 20);

            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Violet);
            Display.Hidden_Buffer (1).Cubic_Bezier (P1        => (10, 10),
                                                   P2        => (60, 10),
                                                   P3        => (60, 60),
                                                   P4        => (100, 100),
                                                   N         => 200,
                                                   Thickness => 5);

            Copy_Rect (Src_Buffer  => Display.Hidden_Buffer (1).all,
                     Src_Pt      => (0, 0),
                     Dst_Buffer  => Display.Hidden_Buffer (1).all,
                     Dst_Pt      => (100, 100),
                     Width       => 100,
                     Height      => 100,
                     Synchronous => True);

            Display.Update_Layer (1, Copy_Back => False);

            if State'Length = 3 then
               Display.Hidden_Buffer (1).Set_Source (BG);
               Display.Hidden_Buffer (1).Fill;

               Bitmapped_Drawing.Draw_String
               (Display.Hidden_Buffer (1).all, 
                  Start => (0, 0),
                  Msg => "Returning to Drawing Mode!", 
                  Font => BMP_Fonts.Font8x8,
                  Foreground => FG,
                  Background => BG);
            
               Current_Mode := Drawing_Mode;
            end if;
         end if;
      end;
   end loop;
end Stm32_Draw_Demo;