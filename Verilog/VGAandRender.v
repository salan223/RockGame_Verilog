module vga_sync(
	input clk,reset, // Initializing the inputs (clock and reset)
	output hsync,vsync, video_on,p_tick, // Outputs. VGA and video
	output [9:0] x,y//position of x and y // The current position of the pixel
	);

    // timing and resolution for VGA

	localparam H_DISPLAY       = 640; // width
	localparam H_L_BORDER      =  48; // Left border
	localparam H_R_BORDER      =  16; // Right border
	localparam H_RETRACE       =  96; // Height
	localparam H_MAX           = H_DISPLAY + H_L_BORDER + H_R_BORDER + H_RETRACE - 1;
	localparam START_H_RETRACE = H_DISPLAY + H_R_BORDER;
	localparam END_H_RETRACE   = H_DISPLAY + H_R_BORDER + H_RETRACE - 1;
	
	localparam V_DISPLAY       = 480; 
	localparam V_T_BORDER      =  10; // Top border
	localparam V_B_BORDER      =  33; // Bottom border
	localparam V_RETRACE       =   2; 
	localparam V_MAX           = V_DISPLAY + V_T_BORDER + V_B_BORDER + V_RETRACE - 1;

   localparam START_V_RETRACE = V_DISPLAY + V_B_BORDER;
	localparam END_V_RETRACE   = V_DISPLAY + V_B_BORDER + V_RETRACE - 1;
	
	// mod-2 counter to generate 25 MHz pixel tick
	reg pixel_reg; // The counter to generate the pixel clock

	wire pixel_next; // Next state of the pixel clock
	wire pixel_tick; // The tick signal of pixel
	
	always @(posedge clk, posedge reset)
		if(reset)
		  pixel_reg <= 0;
		else
		  pixel_reg <= pixel_next;
	
	assign pixel_next = pixel_reg + 1; // increment pixel reg 
	
	assign pixel_tick = (pixel_reg == 0); // asserting the tick 1/4 of the time
	
	reg [9:0] h_count_reg, h_count_next, v_count_reg, v_count_next;
	
	reg vsync_reg, hsync_reg;
	wire vsync_next, hsync_next;
 
	always @(posedge clk, posedge reset)
		if(reset)
			begin
           		v_count_reg <= 0;
            		h_count_reg <= 0;
            		vsync_reg   <= 0;
            		hsync_reg   <= 0;
			end
		else
			begin
            		v_count_reg <= v_count_next;
            		h_count_reg <= h_count_next;
            		vsync_reg   <= vsync_next;
            		hsync_reg   <= hsync_next;
			end
			
	// next-state logic of horizontal vertical sync counters
	always @*
		begin
		h_count_next = pixel_tick ? 
		               h_count_reg == H_MAX ? 0 : h_count_reg + 1
			       : h_count_reg;
		
		v_count_next = pixel_tick && h_count_reg == H_MAX ? 
		               (v_count_reg == V_MAX ? 0 : v_count_reg + 1) 
			       : v_count_reg;
		end
		

   assign hsync_next = h_count_reg >= START_H_RETRACE && h_count_reg <= END_H_RETRACE;
   
   assign vsync_next = v_count_reg >= START_V_RETRACE && v_count_reg <= END_V_RETRACE;

    // the video will be active only in visible area

   assign video_on = (h_count_reg < H_DISPLAY) && (v_count_reg < V_DISPLAY);

   // output signals
   assign hsync  = hsync_reg;
   assign vsync  = vsync_reg;
   assign x      = h_count_reg;
   assign y      = v_count_reg;
   assign p_tick = pixel_tick;


	
	
endmodule



module render(
    input clk, reset,
    input [9:0] x, y,           
    input video_on,
    output [11:0] rgb,
    input clk_1ms,
    input blasterON, bulletON, rock_active, 
    input [11:0] blasterRGB, bulletRGB, rgb_rockPXL,
    input [1:0] game_state
);//inputs and outputs for clock, reset, positions, signal for video, rgb output, signals, colours, and game states

	//current colour of the pixel is in hold in this register 
    reg [11:0] rgb_reg;

    
    localparam Horizontal_Screen = 1600;
    localparam Vertical_Screen = 900;

    //game over text
    reg [7:0] font_rom [0:63];
    initial begin
        // “G”
        font_rom[0]  = 8'b00111100; font_rom[1]  = 8'b01100110;
        font_rom[2]  = 8'b01100000; font_rom[3]  = 8'b01101110;
        font_rom[4]  = 8'b01100110; font_rom[5]  = 8'b01100110;
        font_rom[6]  = 8'b00111100; font_rom[7]  = 8'b00000000;
        // “A”
        font_rom[8]  = 8'b00111100; font_rom[9]  = 8'b01100110;
        font_rom[10] = 8'b01100110; font_rom[11] = 8'b01111110;
        font_rom[12] = 8'b01100110; font_rom[13] = 8'b01100110;
        font_rom[14] = 8'b01100110; font_rom[15] = 8'b00000000;
        // “M”
        font_rom[16] = 8'b01100011; font_rom[17] = 8'b01110111;
        font_rom[18] = 8'b01111111; font_rom[19] = 8'b01101011;
        font_rom[20] = 8'b01100011; font_rom[21] = 8'b01100011;
        font_rom[22] = 8'b01100011; font_rom[23] = 8'b00000000;
        // “E”
        font_rom[24] = 8'b01111110; font_rom[25] = 8'b01100000;
        font_rom[26] = 8'b01100000; font_rom[27] = 8'b01111100;
        font_rom[28] = 8'b01100000; font_rom[29] = 8'b01100000;
        font_rom[30] = 8'b01111110; font_rom[31] = 8'b00000000;
        // “O”
        font_rom[32] = 8'b00111100; font_rom[33] = 8'b01100110;
        font_rom[34] = 8'b01100110; font_rom[35] = 8'b01100110;
        font_rom[36] = 8'b01100110; font_rom[37] = 8'b01100110;
        font_rom[38] = 8'b00111100; font_rom[39] = 8'b00000000;
        // “V”
        font_rom[40] = 8'b01100110; font_rom[41] = 8'b01100110;
        font_rom[42] = 8'b01100110; font_rom[43] = 8'b01100110;
        font_rom[44] = 8'b00111100; font_rom[45] = 8'b00011000;
        font_rom[46] = 8'b00000000; font_rom[47] = 8'b00000000;
        // “E”
        font_rom[48] = 8'b01111110; font_rom[49] = 8'b01100000;
        font_rom[50] = 8'b01100000; font_rom[51] = 8'b01111100;
        font_rom[52] = 8'b01100000; font_rom[53] = 8'b01100000;
        font_rom[54] = 8'b01111110; font_rom[55] = 8'b00000000;
        // “R”
        font_rom[56] = 8'b01111100; font_rom[57] = 8'b01100110;
        font_rom[58] = 8'b01100110; font_rom[59] = 8'b01111100;
        font_rom[60] = 8'b01101100; font_rom[61] = 8'b01100110;
        font_rom[62] = 8'b01100110; font_rom[63] = 8'b00000000;
    end

    //you win text
    reg [7:0] font_rom_win [0:47]; 
    initial begin
        // “Y”
        font_rom_win[0]  = 8'b01100110; font_rom_win[1]  = 8'b01100110;
        font_rom_win[2]  = 8'b01100110; font_rom_win[3]  = 8'b00111100;
        font_rom_win[4]  = 8'b00011000; font_rom_win[5]  = 8'b00011000;
        font_rom_win[6]  = 8'b00011000; font_rom_win[7]  = 8'b00000000;
        // “O”
        font_rom_win[8]  = 8'b00111100; font_rom_win[9]  = 8'b01100110;
        font_rom_win[10] = 8'b01100110; font_rom_win[11] = 8'b01100110;
        font_rom_win[12] = 8'b01100110; font_rom_win[13] = 8'b01100110;
        font_rom_win[14] = 8'b00111100; font_rom_win[15] = 8'b00000000;
        // “U”
        font_rom_win[16] = 8'b01100110; font_rom_win[17] = 8'b01100110;
        font_rom_win[18] = 8'b01100110; font_rom_win[19] = 8'b01100110;
        font_rom_win[20] = 8'b01100110; font_rom_win[21] = 8'b01100110;
        font_rom_win[22] = 8'b00111100; font_rom_win[23] = 8'b00000000;
        // “W”
        font_rom_win[24] = 8'b01100011; font_rom_win[25] = 8'b01100011;
        font_rom_win[26] = 8'b01100011; font_rom_win[27] = 8'b01101011;
        font_rom_win[28] = 8'b01111111; font_rom_win[29] = 8'b01110111;
        font_rom_win[30] = 8'b01100011; font_rom_win[31] = 8'b00000000;
        // “I”
        font_rom_win[32] = 8'b00111100; font_rom_win[33] = 8'b00011000;
        font_rom_win[34] = 8'b00011000; font_rom_win[35] = 8'b00011000;
        font_rom_win[36] = 8'b00011000; font_rom_win[37] = 8'b00011000;
        font_rom_win[38] = 8'b00111100; font_rom_win[39] = 8'b00000000;
        // “N”
        font_rom_win[40] = 8'b01100011; font_rom_win[41] = 8'b01110011;
        font_rom_win[42] = 8'b01111011; font_rom_win[43] = 8'b01101111;
        font_rom_win[44] = 8'b01100111; font_rom_win[45] = 8'b01100011;
        font_rom_win[46] = 8'b01100011; font_rom_win[47] = 8'b00000000;
    end

	localparam TEXT_X_START = 240;      // X start position for "GAME OVER"
    localparam TEXT_Y_START = 200;      // Y start position for "GAME OVER"
    localparam WIN_TEXT_X_START = 200; // X start position for "YOU WIN"
    localparam WIN_TEXT_Y_START = 150; // Y start position for "YOU WIN"

    reg text_on;
    reg [7:0] char_line;

    always @(posedge clk) begin
        if (game_state == 2'b11) begin // Game over screen
            if ((x >= TEXT_X_START) && (x < TEXT_X_START + 8*8) &&
                (y >= TEXT_Y_START) && (y < TEXT_Y_START + 8)) begin
                char_line <= font_rom[(y - TEXT_Y_START) + 8 * ((x - TEXT_X_START) / 8)];
                text_on <= char_line[7 - (x - TEXT_X_START) % 8];
            end else begin
                text_on <= 0;
            end
        end else if (game_state == 2'b10) begin // Win screen
            if ((x >= WIN_TEXT_X_START) && (x < WIN_TEXT_X_START + 8*6) &&
                (y >= WIN_TEXT_Y_START) && (y < WIN_TEXT_Y_START + 8)) begin
                char_line <= font_rom_win[(y - WIN_TEXT_Y_START) + 8 * ((x - WIN_TEXT_X_START) / 8)];
                text_on <= char_line[7 - (x - WIN_TEXT_X_START) % 8];
            end else begin
                text_on <= 0;
            end
        end else begin
            text_on <= 0;
        end
    end

    always @(posedge clk) begin
        if (!reset) begin
            rgb_reg <= 12'b000000000000; // Default to black screen
        end else begin
            if (game_state == 2'b01) begin // Game in progress
                if (blasterON)
                    rgb_reg <= blasterRGB;
                else if (bulletON)
                    rgb_reg <= bulletRGB;
                else if (rock_active)
                    rgb_reg <= rgb_rockPXL;
                else
                    rgb_reg <= 12'b000000000000; // Black background
            end else if (game_state == 2'b10) begin // Win screen
                if (text_on)
                    rgb_reg <= 12'b111111111111; // White text for "YOU WIN"
                else
                    rgb_reg <= 12'b000011110000; // Green background
            end else if (game_state == 2'b11) begin // Game over screen
                if (text_on)
                    rgb_reg <= 12'b111111111111; // White text for "GAME OVER"
                else
                    rgb_reg <= 12'b111000000000; // Red background
            end else begin
                rgb_reg <= 12'b000000000000; // Default to black
            end
        end
    end

    assign rgb = (video_on) ? rgb_reg : 12'b0;

endmodule



