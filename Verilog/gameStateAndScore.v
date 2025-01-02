module game_state(
	input clk, clk_1ms, reset,
	input [4:0] scoreCounter, gameOver,
	output reg [1:0] game_state
	); //inputs and outputs of clock, reset, score of the player, gameover, and game states
	
//game is over when it reaches the score of 15
	reg [3:0] gameState = 4'b1111; 

	always @ (posedge clk)
	begin
		if (!reset)
			game_state = 0;
		else 
		begin
			if ( scoreCounter == gameState)
				//player wins
				game_state = 2'b10;
			else if ( gameOver == gameState)
				game_state = 2'b11;//player loses so game over
			else 
				game_state = 2'b01;//player is currently playing
		end
	end

endmodule




module score (
	input clk, clk_1ms, reset, // Initializing the inputs
	input [4:0] scoreCounter, // Player's score
	output reg [6:0] seg1 // 7-segment display output
	);
	
	always @ (*)
	begin
	if (!reset)
            // Resetting the display to default

	begin
		seg1 = 7'b1111111;
	end
	else 
	begin
            // Display player score

		case (scoreCounter)
			4'h0 : seg1 = 7'b1000000;  // 0
			4'h1 : seg1 = 7'b1111001;  // 1
			4'h2 : seg1 = 7'b0100100;  // 2
			4'h3 : seg1 = 7'b0110000;  // 3
			4'h4 : seg1 = 7'b0011001;  // 4
			4'h5 : seg1 = 7'b0010010;  // 5
			4'h6 : seg1 = 7'b0000010;  // 6
			4'h7 : seg1 = 7'b1111000;  // 7
			4'h8 : seg1 = 7'b0000000;  // 8
			4'h9 : seg1 = 7'b0010000;  // 9
			4'hA : seg1 = 7'b0001000;  // A
         4'hB : seg1 = 7'b0000011;  // B
         4'hC : seg1 = 7'b1000110;  // C
         4'hD : seg1 = 7'b0100001;  // D
         4'hE : seg1 = 7'b0000110;  // E
         4'hF : seg1 = 7'b0001110;  // F
			default : seg1 = 7'b1111111; // Default display which is blank

		endcase
		
	end
	end

endmodule

