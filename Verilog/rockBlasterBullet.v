
module rock(
    input clk, clk_1ms, reset,
    input [9:0] x, y,
    output rock_active,
    output [11:0] rgb_rockPXL,
    input [9:0] x_blaster, y_blaster, x_bullet, y_bullet,
    input [1:0] game_state,
    output reg [5:0] scoreCounter, gameOver
); //resets and clock signals

	//constant horizontal and vertical screens
    localparam Horizontal_Screen = 640;  
    localparam Vertical_Screen = 480;

	//constant size of the rock in width and height
    localparam rock_width = 50;
    localparam rock_height = 50;

	//x and y rock positions registers 
    reg [9:0] rock_x1, rock_y1; 
    reg [9:0] rock_x2, rock_y2; 
    reg [15:0] lfsr1, lfsr2; //lfsr random generator
    reg [4:0] miss_rockCount; //missed rock counter

    
    initial begin //lfsr random generation
        lfsr1 = 16'b1011010110011101;
        lfsr2 = 16'b1101101101011011;
    end

    //lfsr random generation logic
    always @(posedge clk_1ms) begin
        if (!reset) begin
            lfsr1 <= 16'b1011010110011101; //reset to initial state
            lfsr2 <= 16'b1101101101011011; 
        end else begin
            
            lfsr1 <= {lfsr1[14:0], lfsr1[15] ^ lfsr1[13]};
            lfsr2 <= {lfsr2[14:0], lfsr2[15] ^ lfsr2[14] ^ lfsr2[12] ^ lfsr2[3]}; //lfsr random new generation and shifts
        end
    end

    always @(posedge clk_1ms) begin
        if (!reset) begin
            //the game states, score of the player, and the rock positions resets
            rock_x1 <= Horizontal_Screen;
            rock_y1 <= Vertical_Screen / 3; 
            rock_x2 <= Horizontal_Screen + 200; 
            rock_y2 <= (Vertical_Screen * 2) / 3; 
            scoreCounter <= 0;
            gameOver <= 0;
            miss_rockCount <= 0;
        end else if (game_state == 2'b01) begin
            //first rock logic
            if (rock_x1 == 0) begin
                miss_rockCount <= miss_rockCount + 1;
                if (miss_rockCount == 25) begin //game is over after too many misses

                    gameOver <= 4'b1111; 
                end else begin
                    
                    rock_x1 <= Horizontal_Screen; //at random positions, first rock is respawned

                    rock_y1 <= (lfsr1 % (Vertical_Screen - rock_height)) + rock_height / 2;
                end
            end else begin
		//rock moves to the left to make it slower
                rock_x1 <= rock_x1 - 1; 
            end

            //second rock logic
            if (rock_x2 == 0) begin
                miss_rockCount <= miss_rockCount + 1;
                if (miss_rockCount == 25) begin //game is over after too many misses

                    gameOver <= 4'b1111; 
                end else begin
                    //at random positions, second rock is respawned
                    rock_x2 <= Horizontal_Screen;
                    rock_y2 <= (lfsr2 % (Vertical_Screen - rock_height)) + rock_height / 2;
                end
            end else begin
			//second rock moves faster than first rock
                rock_x2 <= rock_x2 - 2; 
            end

            //if statement for checking the hit from the first rock and the bullet
            if (
                (x_bullet + 8 >= rock_x1 - rock_width / 2) &&
                (x_bullet - 8 <= rock_x1 + rock_width / 2) &&
                (y_bullet + 8 >= rock_y1 - rock_height / 2) &&
                (y_bullet - 8 <= rock_y1 + rock_height / 2)
            ) begin
                scoreCounter <= scoreCounter + 1;
                rock_x1 <= Horizontal_Screen;
                rock_y1 <= (lfsr1 % (Vertical_Screen - rock_height)) + rock_height / 2;
            end

		//if statement for checking the hit from the second rock and the bullet
            if (
                (x_bullet + 8 >= rock_x2 - rock_width / 2) &&
                (x_bullet - 8 <= rock_x2 + rock_width / 2) &&
                (y_bullet + 8 >= rock_y2 - rock_height / 2) &&
                (y_bullet - 8 <= rock_y2 + rock_height / 2)
            ) begin
                scoreCounter <= scoreCounter + 1;
                rock_x2 <= Horizontal_Screen;
                rock_y2 <= (lfsr2 % (Vertical_Screen - rock_height)) + rock_height / 2;
            end

            //if statement to check for hit from first rock and blaster
            if (
                (x_blaster + 25 >= rock_x1 - rock_width / 2) &&
                (x_blaster - 25 <= rock_x1 + rock_width / 2) &&
                (y_blaster + 10 >= rock_y1 - rock_height / 2) &&
                (y_blaster - 10 <= rock_y1 + rock_height / 2)
            ) begin
//game is over when there’s a hit
                gameOver <= 4'b1111; 
            end

//if statement to check for hit from second rock and blaster	
            if (
                (x_blaster + 25 >= rock_x2 - rock_width / 2) &&
                (x_blaster - 25 <= rock_x2 + rock_width / 2) &&
                (y_blaster + 10 >= rock_y2 - rock_height / 2) &&
                (y_blaster - 10 <= rock_y2 + rock_height / 2)
            ) begin
			//game over after hit
                gameOver <= 4'b1111; 
            end
        end
    end

    //assigning to check if previous pixel falls in the bound logic of the first rock or second rock to render it
    assign rock_active = (
        (x >= rock_x1 - rock_width / 2 && x <= rock_x1 + rock_width / 2 &&
         y >= rock_y1 - rock_height / 2 && y <= rock_y1 + rock_height / 2) ||
        (x >= rock_x2 - rock_width / 2 && x <= rock_x2 + rock_width / 2 &&
         y >= rock_y2 - rock_height / 2 && y <= rock_y2 + rock_height / 2)
    );

    //rocks color are yellow
    assign rgb_rockPXL = 12'b111111110000 ;

endmodule

module bullet(
    input clk, clk_1ms, reset, shootBtn, // Initializing the inputs
    input [9:0] x, y, // The current position displayed on the screen
    output bulletON, // The signal to display the bullet
    output [11:0] bulletRGB, // The RBG colour of the bullet
    input [9:0] x_blaster, y_blaster, // The position of the blaster on the screen
    input [1:0] game_state, // The current state of the game

    output reg [9:0] x_bullet, // the x-coordinate of the bullet
    output reg [9:0] y_bullet // the y-coordinate of the bullet
    );

    // screen resolution and bullet size

    localparam Horizontal_Screen = 640;  // Screen width
    localparam Vertical_Screen = 480;  // Screen height

    // bullet dimensions
    localparam bulletRadius = 8; // bullet as a circle and its radius of 8

    reg flag = 0; // movement flag of the bullet
    reg [31:0] fire_counter = 0; // Counter for three second delay

    always @(posedge clk_1ms) begin
        if (!reset) begin
            // Resetting the bullet to blaster's position
            x_bullet <= x_blaster;
            y_bullet <= y_blaster;
            flag <= 0;
            fire_counter <= 0;
        end else if (game_state == 2'b01) begin
            if (shootBtn) begin
                fire_counter <= fire_counter + 1;
                if (flag == 0 || fire_counter == 3000) begin // Fire every 3 seconds
                    flag <= 1;
                    x_bullet <= x_blaster;
                    y_bullet <= y_blaster;
                    fire_counter <= 0;
                end
            end else begin
                fire_counter <= 0; // Reset counter whenever the button was not pressed
                flag <= 0;
            end

            // the bullet movement
            if (flag == 1) begin
                if (x_bullet < Horizontal_Screen) begin
                    x_bullet <= x_bullet + 4; // Moving the bullet forward
                end else begin
                    flag <= 0; // Reset flag whenever the bullet is moving out of bounds
                end
            end
        end
    end

    // bullet shape is Circle
    assign bulletON = flag && ( // Only display the bullet if the player is fiting
        (x - x_bullet) * (x - x_bullet) + (y - y_bullet) * (y - y_bullet) <= bulletRadius * bulletRadius
    );

    // bullet color
    assign bulletRGB = 12'b111111111111; // The bullet is White colour

endmodule


module blaster(
	input clk_1ms,reset, // The inputs which are the clock and reset
	input moveUpBtn, moveDownBtn, // Buttons for moving the blaster up and down

	input [9:0] x, y,   //x and y position of the blaster
	output blasterON,
	output [11:0] blasterRGB,
	output reg [9:0] x_blaster = L_position + (blasterWidth/2),  // x-coordinate of the blaster
	output reg [9:0] y_blaster = Vertical_Screen/2
	);
    // Screen and blaster sizes

	localparam Horizontal_Screen = 1600; // Horizontal screen resolution
	localparam Vertical_Screen = 900; // Vertical screen resolution
	
	localparam blasterWidth = 50;  // blaster’s width
	localparam blasterHeight = 20; // blaster’s height

	
	localparam L_position = 20; // Left boundary position
	localparam R_position = 20; // Right boundary position
		
	always @ (posedge clk_1ms)
	begin
		if(!reset)
		begin	
            // Resetting the  blaster to its initial position

			x_blaster <= L_position + (blasterWidth/2);   
			
			y_blaster <= Vertical_Screen/2;
		end
            // Moving the blaster down

		else if (moveDownBtn && y_blaster-(blasterHeight/2) >= 0)  
		
			y_blaster <= y_blaster-1;
			//upwards movment 
		else if (moveUpBtn && y_blaster+(blasterHeight/2) <= Vertical_Screen) 
		
			y_blaster <= y_blaster+1;
			
		else y_blaster <= y_blaster;
	end
	//drawing the blaster on the screen
	assign blasterON = (x >= x_blaster-(blasterWidth/2) && x <= x_blaster+(blasterWidth/2) && y >= y_blaster-(blasterHeight/2) && y < y_blaster+(blasterHeight/2))?1:0;

	assign blasterRGB = 12'b000000001111;      // Assign blaster color (blue)

	
	
endmodule





