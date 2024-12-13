module midnight_city_m83(
input clk,
input rst,
input mode,
input startsong,
input sinsquare,
input noteselect,
input [2:0]forbassselect,
input [2:0]forhiselect,
input forsw1select, // mixer via KEY[3]
output [6:0] HEX0,
output [6:0] HEX1,
output [6:0] HEX2,
output [6:0] HEX3,
output signed [31:0] tone,
output readValid);



//input startsong; //KEY1 Starts the song
//input mode; ///SW2 Will star the FSM
reg [2:0] notebassselect;
reg [2:0] notehiselect;
reg sw1select;
reg enablesong;

reg [25:0]tick_count;
reg [5:0]S;
reg [5:0]NS;

parameter START = 6'd0,
				GFNOTE= 6'd1,
				GDNOTE= 6'd2,
				GBNOTE= 6'd3,
				GFLONG= 6'd4,
				FFNOTE= 6'd5,
				FDNOTE= 6'd6,
				FBNOTE= 6'd7,
				FFLONG= 6'd8,
				EFNOTE= 6'd9,
				EDNOTE= 6'd10,
				EBNOTE= 6'd11,
				EFLONG= 6'd12,
				BFNOTE= 6'd13,
				BDNOTE= 6'd14,
				BBNOTE= 6'd15,
				BFLONG= 6'd16,
				WAIT1 = 6'd18,
				WAIT2 = 6'd19,
				WAIT3 = 6'd20,
				WAIT4 = 6'd21,
				WAIT5 = 6'd22,
				WAIT6 = 6'd23,
				WAIT7 = 6'd24,
				WAIT8 = 6'd25,
				WAIT9 = 6'd26,
				WAIT10 = 6'd27,
				WAIT11 = 6'd28,
				WAIT12 = 6'd29,
				WAIT13 = 6'd30,
				WAIT14 = 6'd31,
				WAIT15 = 6'd32,
				WAIT16 = 6'd33;
always@(*)
begin		
if(mode == 1'b1)
enablesong = 1'b1;
else
enablesong = 1'b0;

end


		always@(posedge clk or negedge rst)
			if(rst==1'b0)
				S<=START;
			else 
				S<=NS;
				
		always@* begin
			case(S)
						START: begin 
							if(rst == 1'b0)
								NS = START;
							else if(startsong == 1'b0 && enablesong == 1'b1) //// STARTSONG IN KEY 1 IIS ACTIVE LOW 
								NS = GFNOTE;
						       end
						GFNOTE: begin 
							if(tick_count == 26'd37015086)
								NS = WAIT1;
							else
								NS = GFNOTE;
							end
						GDNOTE: begin 
							if(tick_count == 26'd37015086)
								NS = WAIT2;
							else
								NS = GDNOTE;
							end
						GBNOTE:begin 
							if(tick_count == 26'd24676724) ///0,2 SECONDS
								NS = WAIT3;
							else
								NS = GBNOTE;
							end
						GFLONG: begin 
							if(tick_count == 26'd50000000) //0.4 SECONDS
								NS = WAIT4;
							else
								NS = GFLONG;
							end
						FFNOTE: begin 
							if(tick_count == 26'd37015086)
								NS = WAIT5;
							else
								NS = FFNOTE;
							end
						FDNOTE:begin 
							if(tick_count == 26'd37015086)
								NS = WAIT6;
							else
								NS = FDNOTE;
							end
						FBNOTE: begin 
							if(tick_count == 26'd24676724) /////// 0.2SECONDS
								NS = WAIT7;
							else
								NS = FBNOTE;
							end
						FFLONG:begin 
							if(tick_count == 26'd50000000) /////// 0.4 SECONDS
								NS = WAIT8;
							else
								NS = FFLONG;
							end
						EFNOTE: begin 
							if(tick_count == 26'd37015086)
								NS = WAIT9;
							else
								NS = EFNOTE;
							end
						EDNOTE: begin 
							if(tick_count == 26'd37015086)
								NS = WAIT10;
							else
								NS = EDNOTE;
							end
						EBNOTE: begin 
							if(tick_count == 26'd24676724) //////// 2
								NS = WAIT11;
							else
								NS = EBNOTE;
							end
						EFLONG: begin 
							if(tick_count == 26'd50000000) ////4
								NS = WAIT12;
							else
								NS = EFLONG;
							end
						BFNOTE:begin 
							if(tick_count == 26'd37015086)
								NS = WAIT13;
							else
								NS = BFNOTE;
							end
						BDNOTE: begin 
							if(tick_count == 26'd37015086)
								NS = WAIT14;
							else
								NS = BDNOTE;
							end
						BBNOTE:begin 
							if(tick_count == 26'd24676724) ///2
								NS = WAIT15;
							else
								NS = BBNOTE;
							end
						BFLONG: begin 
							if(tick_count == 26'd50000000) ///4
								NS = WAIT16;
							else
								NS = BFLONG;
							end
						WAIT1: NS = GDNOTE ;
						WAIT2 : NS = GBNOTE;
						WAIT3: NS = GFLONG ;
						WAIT4: NS = FFNOTE;
						WAIT5: NS = FDNOTE;
						WAIT6: NS = FBNOTE;
						WAIT7: NS = FFLONG;
						WAIT8: NS = EFNOTE;
						WAIT9: NS = EDNOTE;
						WAIT10: NS = EBNOTE;
						WAIT11: NS = EFLONG;
						WAIT12: NS = BFNOTE;
						WAIT13: NS = BDNOTE;
						WAIT14: NS = BBNOTE;
						WAIT15: NS = BFLONG;
						WAIT16: NS = GFNOTE;
			endcase
		end

		always@(posedge clk or negedge rst) ///update counts and update 
		begin
			if(rst==1'b0)
				begin
				notebassselect <= 3'd0;
				notehiselect <= 3'd0;
				sw1select <= 1'b0;
				end
			else
				case(S)
						START: begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'd0;
							notehiselect <= 3'd0;
							sw1select <= 1'b1;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						GFNOTE: begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b100;
							notehiselect <= 3'b011;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						GDNOTE: begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b100;
							notehiselect <= 3'b001;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						GBNOTE:
							begin 
							if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b100;
							notehiselect <= 3'b110;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						GFLONG: begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b100;
							notehiselect <= 3'b011;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						FFNOTE: begin 
							if(enablesong == 1'b1)
							begin
							notebassselect <= 3'b011;
							notehiselect <= 3'b011;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						FDNOTE:begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b011;
							notehiselect <= 3'b001;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						FBNOTE: begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b011;
							notehiselect <= 3'b110;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						FFLONG:begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b011;
							notehiselect <= 3'b011;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						EFNOTE: begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b010;
							notehiselect <= 3'b011;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						EDNOTE: begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b010;
							notehiselect <= 3'b001;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end 
							end
						EBNOTE: begin 
							if(enablesong == 1'b1)
							begin
							notebassselect <= 3'b010;
							notehiselect <= 3'b110;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						EFLONG: begin 
							if(enablesong == 1'b1)
							begin
							notebassselect <= 3'b010;
							notehiselect <= 3'b011;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						BFNOTE:begin 
							if(enablesong == 1'b1)
							begin
							notebassselect <= 3'b110;
							notehiselect <= 3'b011;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end 
							end
						BDNOTE: begin 
						if(enablesong == 1'b1)
						begin
							notebassselect <= 3'b110;
							notehiselect <= 3'b001;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end 
							end
						BBNOTE:begin 
							if(enablesong == 1'b1)
							begin
							notebassselect <= 3'b110;
							notehiselect <= 3'b110;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						BFLONG: begin 
							if(enablesong == 1'b1)
							begin
							notebassselect <= 3'b110;
							notehiselect <= 3'b011;
							sw1select <= 1'b0;
							tick_count <= tick_count + 1'b1;
							end
							else
							begin
							sw1select <= forsw1select;
							notebassselect <= forbassselect;
							notehiselect <= forhiselect;
							end
							end
						WAIT1: tick_count <= 26'd0;
						WAIT2: tick_count <= 26'd0;
						WAIT3: tick_count <= 26'd0;
						WAIT4: tick_count <= 26'd0;
						WAIT5: tick_count <= 26'd0;
						WAIT6: tick_count <= 26'd0;
						WAIT7: tick_count <= 26'd0;
						WAIT8: tick_count <= 26'd0;
						WAIT9: tick_count <= 26'd0;
						WAIT10: tick_count <= 26'd0;
						WAIT11: tick_count <= 26'd0;
						WAIT12: tick_count <= 26'd0;
						WAIT13: tick_count <= 26'd0;
						WAIT14: tick_count <= 26'd0;
						WAIT15: tick_count <= 26'd0;
						WAIT16: tick_count <= 26'd0;
			endcase
		end 
		
toneGENSelector topselector(
    .clock(clk),
   . mode(noteselect), // Switch to select note 1 or note 2 sw3
	. mixer(sw1select),  // Key to select output tone: No press for individual, Press for mixed tone KEY3
    .tone(tone),
    .readValid(readValid),
	 .switches1(notebassselect),
	 .switches2(notehiselect),
	 .switch(sinsquare), //// enable sine or square  SW1
	.HEX0(HEX0), /// add a hex 
	.HEX1(HEX1), //// add a hex 
	.HEX2(HEX2), /// add a hex 
	.HEX3(HEX3), /// add a hex 
);
endmodule