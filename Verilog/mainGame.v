module clock_divider(
    input clk,
    output reg clk_1ms = 0
    ); //clock and register for clock 1ms initialized
    
//register counter that divides the input of the clock freq
    reg [27:0] i = 0;
    
	 always @ (posedge clk)
    begin
        if (i == 124999) //if the counter is ~1ms, counter is reset and the output for the clock signal is toggled

        begin
            i <= 0;
            clk_1ms = ~clk_1ms;
        end
        else i <= i+1; //the count increment by 1
    end
    
endmodule


module game (
	input clk, reset, moveUpBtn, moveDownBtn, shootBtn,
	output [11:0] rgb,
	output hsync, vsync, 
	output [6:0] seg1
	);
	
	
	wire [9:0] x,y;
	
	wire video_on;
	wire clk_1ms;
	
	wire [11:0] blasterRGB, bulletRGB, rgb_rockPXL;
	wire bulletON, blasterON, rock_active;
	wire [9:0] x_blaster,  y_blaster, x_bullet, y_bullet;
	wire [4:0] scoreCounter, gameOver;
	wire [1:0] game_state;
	
	vga_sync v1	(.clk(clk), .hsync(hsync), .vsync(vsync), .x(x), .y(y), .video_on(video_on));
	
	render r1	(.clk(clk), .reset(reset), .x(x), .y(y), .video_on(video_on), .rgb(rgb), .clk_1ms(clk_1ms),
					.blasterON(blasterON),  .bulletON(bulletON), .rock_active(rock_active),
					.blasterRGB(blasterRGB),  .bulletRGB(bulletRGB), .rgb_rockPXL(rgb_rockPXL),
					.game_state(game_state));
				
	clock_divider c1 (.clk(clk), .clk_1ms(clk_1ms));
	
	blaster s1	(.clk_1ms(clk_1ms), .reset(reset), .x(x), .y(y),
					 .moveUpBtn(moveUpBtn), .moveDownBtn(moveDownBtn), 
					.blasterON(blasterON), .blasterRGB(blasterRGB),  
					.x_blaster(x_blaster),  .y_blaster(y_blaster) );
	
	
	
	rock a1 (.clk(clk), .clk_1ms(clk_1ms), .reset(reset), .x(x), .y(y),  .rock_active(rock_active), .rgb_rockPXL(rgb_rockPXL),
				.x_blaster(x_blaster), .y_blaster(y_blaster), .game_state(game_state), .x_bullet(x_bullet), .y_bullet(y_bullet), 
				.scoreCounter(scoreCounter), .gameOver(gameOver));
				
	
	bullet ro1 	(.clk(clk), .clk_1ms(clk_1ms), .reset(reset), .shootBtn(shootBtn), .x(x), .y(y),  .bulletON(bulletON), .bulletRGB(bulletRGB),
				.x_blaster(x_blaster),  .y_blaster(y_blaster),  .x_bullet(x_bullet), .y_bullet(y_bullet),
				  .game_state(game_state));
	// controls the logic for the bullet 

	game_state(.clk(clk), .clk_1ms(clk_1ms), .reset(reset), .scoreCounter(scoreCounter), .gameOver(gameOver), .game_state(game_state));
	
	score (.clk(clk), .clk_1ms(clk_1ms), .reset(reset), .scoreCounter(scoreCounter), .seg1(seg1));
	
	
endmodule

