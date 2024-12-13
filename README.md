# DE1-SoC-FPGA-Audio-Synthesizer

## Main Code and Modules
module DE1_SoC_Audio_Example (

	//////////// Audio //////////
	input 		          		AUD_ADCDAT,
	inout 		          		AUD_ADCLRCK,
	inout 		          		AUD_BCLK,
	output		          		AUD_DACDAT,
	inout 		          		AUD_DACLRCK,
	output		          		AUD_XCK,

	//////////// CLOCK //////////
	input 		          		CLOCK_50,


	//////////// I2C for Audio and Video-In //////////
	output		          		FPGA_I2C_SCLK,
	inout 		          		FPGA_I2C_SDAT,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,


	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		reg     [9:0]		LEDR,


	//////////// SW //////////
	input 		     [9:0]		SW
);

// Turn off hex displays.
assign	HEX4		=	7'd0;
assign	HEX5		=	7'd0;

// DONE STANDARD PORT DECLARATION ABOVE
/* HANDLE SIGNALS FOR CIRCUIT */

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
wire clk;
assign clk = CLOCK_50;
wire rst;
assign rst = KEY[0];
 
// Internal Wires
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
reg				read_audio_in;

wire				audio_out_allowed;
reg		[31:0]	left_channel_audio_out;
reg		[31:0]	right_channel_audio_out;
wire				write_audio_out;

// Internal Registers


// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/
// Controlling which filter is applied
always@(*) begin
	// MicIn input or Tone Generator input
	if(SW[0] == 1'b1)
	begin
		right_channel_audio_out = left_channel_audio_in;
		left_channel_audio_out = right_channel_audio_in;
		read_audio_in = audio_in_available & readValid;
		LEDR = {10{1'b1}};
	end
	else
	begin
		right_channel_audio_out = tone;
		left_channel_audio_out = tone;
		read_audio_in = readValid;
		LEDR = {10{1'b0}};
	end
end

assign write_audio_out			= audio_in_available & audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Audio_Controller Audio_Controllers (
	// Inputs
	.CLOCK_50					(clk),
	.reset						(~rst),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),

	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)
);

avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK				(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT				(FPGA_I2C_SDAT),
	.CLOCK_50					(clk),
	.reset						(~rst)
);

wire readValid;

/*****************************************************************************
 *                             Logic Circuit                            *
 *****************************************************************************/
 
wire [31:0] tone;

// Midnight City Module Instantiation
midnight_city_m83(
.clk(CLOCK_50),
.rst(KEY[0]),
.mode(SW[2]),
.startsong(KEY[1]),
.sinsquare(SW[1]),
.noteselect(SW[3]),
.forbassselect(SW[9:7]),
.forhiselect(SW[6:4]),
.forsw1select(KEY[3]),
.HEX0(HEX0),
.HEX1(HEX1),
.HEX2(HEX2),
.HEX3(HEX3),
.tone(tone),
.readValid(readValid)
);


endmodule

module toneSynthSquare(Counts, clock, Out, readValid);
	
	input clock;
	output signed [31:0] Out;
	input [19:0] Counts;
	output readValid;

	reg [18:0] Q;
	reg [11:0] enableCount;

	always@(posedge clock) 
	begin
		if(enableCount == 12'd0)
			enableCount <= 12'd1042;
		else
			enableCount <= enableCount - 1'b1;
	
		if(Q == 19'd0)
			Q <= Counts;
		else
			Q <= Q - 1'b1;	
	end

	
	assign Out = (Q > ((Counts + 1'd1) / 2'd2)? 32'd10000000: -32'd10000000);
	assign readValid = (enableCount == 12'd0)? 1'b1: 1'b0;
	
endmodule


module toneSynthSine(Counts, clock, Out, readValid);
	
	input clock;
	output signed [31:0] Out;
	input [19:0] Counts;
	output readValid;

	reg [18:0] Q;
	reg [11:0] enableCount;
	
	// Sine wave lookup table
    reg signed [31:0] sineLUT [0:255];
    initial begin
		sineLUT[0]   = 32'sh00000000;
		sineLUT[1]   = 32'sh0191F3EF;
		sineLUT[2]   = 32'sh0323E9DE;
		sineLUT[3]   = 32'sh04B5D0D4;
		sineLUT[4]   = 32'sh0647BFE6;
		sineLUT[5]   = 32'sh07D98AFC;
		sineLUT[6]   = 32'sh096B1737;
		sineLUT[7]   = 32'sh0AFD1972;
		sineLUT[8]   = 32'sh0C8F013E;
		sineLUT[9]   = 32'sh0E20F456;
		sineLUT[10]  = 32'sh0FB1D08D;
		sineLUT[11]  = 32'sh11428042;
		sineLUT[12]  = 32'sh12D2DFB0;
		sineLUT[13]  = 32'sh14628175;
		sineLUT[14]  = 32'sh15F14A15;
		sineLUT[15]  = 32'sh178F2306;
		sineLUT[16]  = 32'sh19158F9A;
		sineLUT[17]  = 32'sh1AB2D439;
		sineLUT[18]  = 32'sh1C3EC4F9;
		sineLUT[19]  = 32'sh1DCBB0C8;
		sineLUT[20]  = 32'sh1F570DF7;
		sineLUT[21]  = 32'sh20E0A203;
		sineLUT[22]  = 32'sh2268B9A1;
		sineLUT[23]  = 32'sh23EDEC8F;
		sineLUT[24]  = 32'sh25699695;
		sineLUT[25]  = 32'sh26E2ED99;
		sineLUT[26]  = 32'sh285A1F21;
		sineLUT[27]  = 32'sh29CFAF99;
		sineLUT[28]  = 32'sh2B3A1809;
		sineLUT[29]  = 32'sh2CA2A33C;
		sineLUT[30]  = 32'sh2E081A6E;
		sineLUT[31]  = 32'sh2F6A9D42;
		sineLUT[32]  = 32'sh30C9D5F0;
		sineLUT[33]  = 32'sh3226B92B;
		sineLUT[34]  = 32'sh338042F7;
		sineLUT[35]  = 32'sh34D70CF7;
		sineLUT[36]  = 32'sh362B1D48;
		sineLUT[37]  = 32'sh377BE3C2;
		sineLUT[38]  = 32'sh38C9556F;
		sineLUT[39]  = 32'sh3A1335CC;
		sineLUT[40]  = 32'sh3B59C103;
		sineLUT[41]  = 32'sh3C9CECE0;
		sineLUT[42]  = 32'sh3DDBA09C;
		sineLUT[43]  = 32'sh3F1636C1;
		sineLUT[44]  = 32'sh404C328B;
		sineLUT[45]  = 32'sh417E3A3F;
		sineLUT[46]  = 32'sh42ACF6B2;
		sineLUT[47]  = 32'sh43D64802;
		sineLUT[48]  = 32'sh44FB8AC0;
		sineLUT[49]  = 32'sh461C8236;
		sineLUT[50]  = 32'sh4738D09B;
		sineLUT[51]  = 32'sh4850DDE4;
		sineLUT[52]  = 32'sh4964685E;
		sineLUT[53]  = 32'sh4A72EE34;
		sineLUT[54]  = 32'sh4B7CBAB2;
		sineLUT[55]  = 32'sh4C815CB3;
		sineLUT[56]  = 32'sh4D813DFF;
		sineLUT[57]  = 32'sh4E7C1BE4;
		sineLUT[58]  = 32'sh4F71B0A1;
		sineLUT[59]  = 32'sh5062B1BC;
		sineLUT[60]  = 32'sh514E8288;
		sineLUT[61]  = 32'sh52352A40;
		sineLUT[62]  = 32'sh5316E0BB;
		sineLUT[63]  = 32'sh53F349F1;
		sineLUT[64]  = 32'sh54C9C21A;
		sineLUT[65]  = 32'sh559A91C8;
		sineLUT[66]  = 32'sh5666CB31;
		sineLUT[67]  = 32'sh572DDB93;
		sineLUT[68]  = 32'sh57EF7D99;
		sineLUT[69]  = 32'sh58AC3B95;
		sineLUT[70]  = 32'sh596319A0;
		sineLUT[71]  = 32'sh5A144A8D;
		sineLUT[72]  = 32'sh5AC0A546;
		sineLUT[73]  = 32'sh5B6788A6;
		sineLUT[74]  = 32'sh5C097AAB;
		sineLUT[75]  = 32'sh5CA5E70D;
		sineLUT[76]  = 32'sh5D3C6689;
		sineLUT[77]  = 32'sh5DCDBD04;
		sineLUT[78]  = 32'sh5E59A9A7;
		sineLUT[79]  = 32'sh5ED7DB42;
		sineLUT[80]  = 32'sh5F504B12;
		sineLUT[81]  = 32'sh5FC35611;
		sineLUT[82]  = 32'sh602A5D44;
		sineLUT[83]  = 32'sh608A1FA8;
		sineLUT[84]  = 32'sh60E4E3DC;
		sineLUT[85]  = 32'sh6139BA84;
		sineLUT[86]  = 32'sh6188DE21;
		sineLUT[87]  = 32'sh61D14BE9;
		sineLUT[88]  = 32'sh62137613;
		sineLUT[89]  = 32'sh624FA7CF;
		sineLUT[90]  = 32'sh6285A8FA;
		sineLUT[91]  = 32'sh62B56216;
		sineLUT[92]  = 32'sh62DFA860;
		sineLUT[93]  = 32'sh63045DD3;
		sineLUT[94]  = 32'sh6323913C; 
		sineLUT[95]  = 32'sh633C5508;
		sineLUT[96]  = 32'sh635FD30A;
		sineLUT[97]  = 32'sh637B9F2C;
		sineLUT[98]  = 32'sh6391E61B;
		sineLUT[99]  = 32'sh63A1C8F8;
		sineLUT[100] = 32'sh63AC3A2A;
		sineLUT[101] = 32'sh63B06660;
		sineLUT[102] = 32'sh63AE5054;
		sineLUT[103] = 32'sh63A7108D;
		sineLUT[104] = 32'sh6399A3B4;
		sineLUT[105] = 32'sh63863685;
		sineLUT[106] = 32'sh636CE629;
		sineLUT[107] = 32'sh634EBF3B;
		sineLUT[108] = 32'sh632ACED0;
		sineLUT[109] = 32'sh62F95954;
		sineLUT[110] = 32'sh62C28744;
		sineLUT[111] = 32'sh62868A2F;
		sineLUT[112] = 32'sh624582D4;
		sineLUT[113] = 32'sh61FE9E4A;
		sineLUT[114] = 32'sh61B2F10D;
		sineLUT[115] = 32'sh61629D9E;
		sineLUT[116] = 32'sh610DAFB0;
		sineLUT[117] = 32'sh60B4393E;
		sineLUT[118] = 32'sh60566A1E;
		sineLUT[119] = 32'sh5FF45910;
		sineLUT[120] = 32'sh5F8E24DF;
		sineLUT[121] = 32'sh5F23EB45;
		sineLUT[122] = 32'sh5EB5D408;
		sineLUT[123] = 32'sh5E43F6D1;
		sineLUT[124] = 32'sh5DCE693F;
		sineLUT[125] = 32'sh5D5548C2;
		sineLUT[126] = 32'sh5CD8B86C;
		sineLUT[127] = 32'sh5C58E6FC;
		sineLUT[128] = 32'sh5BD5FB06;
		sineLUT[129] = 32'sh5B5021F6;
		sineLUT[130] = 32'sh5AC775AB;
		sineLUT[131] = 32'sh5A3C1ED5;
		sineLUT[132] = 32'sh59AE471B;
		sineLUT[133] = 32'sh591E18FE;
		sineLUT[134] = 32'sh588BAFD7;
		sineLUT[135] = 32'sh57F73CFC;
		sineLUT[136] = 32'sh5760F886;
		sineLUT[137] = 32'sh56C9065F;
		sineLUT[138] = 32'sh56307C39;
		sineLUT[139] = 32'sh55968657;
		sineLUT[140] = 32'sh54FB47D8;
		sineLUT[141] = 32'sh5466D6AE;
		sineLUT[142] = 32'sh53D151F3;
		sineLUT[143] = 32'sh533AE5AA;
		sineLUT[144] = 32'sh52A3B53E;
		sineLUT[145] = 32'sh520BEED3;
		sineLUT[146] = 32'sh5173B576;
		sineLUT[147] = 32'sh50DB2E5E;
		sineLUT[148] = 32'sh50426E3C;
		sineLUT[149] = 32'sh4FA97B66;
		sineLUT[150] = 32'sh4F107464;
		sineLUT[151] = 32'sh4E7774C7;
		sineLUT[152] = 32'sh4DDE9408;
		sineLUT[153] = 32'sh4D45E34D;
		sineLUT[154] = 32'sh4CAD7E72;
		sineLUT[155] = 32'sh4C157A8E;
		sineLUT[156] = 32'sh4B7DE59F;
		sineLUT[157] = 32'sh4AE6DAF8;
		sineLUT[158] = 32'sh4A50759B;
		sineLUT[159] = 32'sh49BAE131;
		sineLUT[160] = 32'sh49262DFE;
		sineLUT[161] = 32'sh48927104;
		sineLUT[162] = 32'sh480FB3CC;
		sineLUT[163] = 32'sh4785F52E;
		sineLUT[164] = 32'sh46FD2E76;
		sineLUT[165] = 32'sh46756736;
		sineLUT[166] = 32'sh45EEA6C5;
		sineLUT[167] = 32'sh4568EB5C;
		sineLUT[168] = 32'sh44E442A8;
		sineLUT[169] = 32'sh4458B92A;
		sineLUT[170] = 32'sh43CE4B34;
		sineLUT[171] = 32'sh4345044E;
		sineLUT[172] = 32'sh42BCE84E;
		sineLUT[173] = 32'sh4235F7C5;
		sineLUT[174] = 32'sh41B046B0;
		sineLUT[175] = 32'sh412BE89D;
		sineLUT[176] = 32'sh40A8EB30;
		sineLUT[177] = 32'sh40275BEF;
		sineLUT[178] = 32'sh3FA7355F;
		sineLUT[179] = 32'sh3F287D0F;
		sineLUT[180] = 32'sh3EA8479F;
		sineLUT[181] = 32'sh3E2A9B80;
		sineLUT[182] = 32'sh3DAD7D73;
		sineLUT[183] = 32'sh3D31F29A;
		sineLUT[184] = 32'sh3CB80668;
		sineLUT[185] = 32'sh3C3FC0D7;
		sineLUT[186] = 32'sh3BC92525;
		sineLUT[187] = 32'sh3B544064;
		sineLUT[188] = 32'sh3AE11D50;
		sineLUT[189] = 32'sh3A6FCA34;
		sineLUT[190] = 32'sh3A004C3C;
		sineLUT[191] = 32'sh3992AF1B;
		sineLUT[192] = 32'sh3926FF1F;
		sineLUT[193] = 32'sh38BD404A;
		sineLUT[194] = 32'sh38557EB1;
		sineLUT[195] = 32'sh37EFC63D;
		sineLUT[196] = 32'sh378C1AA8;
		sineLUT[197] = 32'sh372A8F64;
		sineLUT[198] = 32'sh36CB2F9A;
		sineLUT[199] = 32'sh366D0626;
		sineLUT[200] = 32'sh36112489;
		sineLUT[201] = 32'sh35B68E03;
		sineLUT[202] = 32'sh355D567C;
		sineLUT[203] = 32'sh35057FF5;
		sineLUT[204] = 32'sh34AF15DB;
		sineLUT[205] = 32'sh345A2B58;
		sineLUT[206] = 32'sh3406CB3C;
		sineLUT[207] = 32'sh33B500E6;
		sineLUT[208] = 32'sh3364D78C;
		sineLUT[209] = 32'sh33165B1F;
		sineLUT[210] = 32'sh32C99E4A;
		sineLUT[211] = 32'sh327EA468;
		sineLUT[212] = 32'sh3235788E;
		sineLUT[213] = 32'sh31EE2D77;
		sineLUT[214] = 32'sh31A8C769;
		sineLUT[215] = 32'sh3165495B;
		sineLUT[216] = 32'sh3123BF0B;
		sineLUT[217] = 32'sh30E42898;
		sineLUT[218] = 32'sh30A68FCA;
		sineLUT[219] = 32'sh306AFD5C;
		sineLUT[220] = 32'sh30316AC7;
		sineLUT[221] = 32'sh2FF9E08F;
		sineLUT[222] = 32'sh2FC468D4;
		sineLUT[223] = 32'sh2F91054C;
		sineLUT[224] = 32'sh2F5FB765;
		sineLUT[225] = 32'sh2F30801E;
		sineLUT[226] = 32'sh2F035FD6;
		sineLUT[227] = 32'sh2ED864A3;
		sineLUT[228] = 32'sh2EAF8C33;
		sineLUT[229] = 32'sh2E88D3B8;
		sineLUT[230] = 32'sh2E644001;
		sineLUT[231] = 32'sh2E41D592;
		sineLUT[232] = 32'sh2E21907D;
		sineLUT[233] = 32'sh2E037456;
		sineLUT[234] = 32'sh2DE7825C;
		sineLUT[235] = 32'sh2DCDC44E;
		sineLUT[236] = 32'sh2DB64494;
		sineLUT[237] = 32'sh2DA0FD38;
		sineLUT[238] = 32'sh2D8DEEFB;
		sineLUT[239] = 32'sh2D7D1A2A;
		sineLUT[240] = 32'sh2D6E7E96;
		sineLUT[241] = 32'sh2D622A8F;
		sineLUT[242] = 32'sh2D5812E8;
		sineLUT[243] = 32'sh2D504506;
		sineLUT[244] = 32'sh2D49B9A0;
		sineLUT[245] = 32'sh2D457E0B;
		sineLUT[246] = 32'sh2D428E02;
		sineLUT[247] = 32'sh2D40E5BC;
		sineLUT[248] = 32'sh2D408844;
		sineLUT[249] = 32'sh2D417805;
		sineLUT[250] = 32'sh2D43B6F9;
		sineLUT[251] = 32'sh2D473DD3;
		sineLUT[252] = 32'sh2D4C00D9;
		sineLUT[253] = 32'sh2D51F838;
		sineLUT[254] = 32'sh2D591D0F;
		sineLUT[255] = 32'sh2D617B45;
    end

    reg [7:0] sineIndex;  // Index for sine LUT (8 bits for 256 values)

	always@(posedge clock) 
	begin
		if(enableCount == 12'd0)
			enableCount <= 12'd1042;
		else
			enableCount <= enableCount - 1'b1;
	
		if (Q == 19'd0) begin
			Q <= Counts;  // Reset Q to the specified count
			if (sineIndex == 8                                                                                                                                                                                                                                                                                                                                                                    )
				sineIndex <= 8'd0;
		else
			sineIndex <= sineIndex + 1'd1;  // Increment LUT index
    end else begin
        Q <= Q - 1'b1;  // Decrement Q
    end
	 end
	
	assign Out = sineLUT[sineIndex];
	
	assign readValid = (enableCount == 12'd0)? 1'b1: 1'b0;
	
endmodule

/* selects different timing speeds */
module toneGenerator(selection, clock, HEX0, HEX1, Tone, readValid, en); ///for base
	input en;
	input [2:0] selection;
	input clock;
	output [6:0] HEX0;
	output [6:0] HEX1;
	output signed [31:0] Tone;

	reg [3:0] Freq1;
	reg [3:0] Freq2;
	reg [19:0] counts;
	
	output readValid;

	always@(*) begin
		case(selection) // seven different choices
			3'b000:
				begin // These increment in frequency
					Freq1 = 4'd12;
					Freq2 = 4'd3;
					counts = 20'd191116;
				end
			3'b001:
				begin
					Freq1 = 4'd13;
					Freq2 = 4'd3;
					counts = 20'd170264; // 1/2 of last
				end
			3'b010:
				begin
					Freq1 = 4'd14;
					Freq2 = 4'd3;
					counts = 20'd151661; // 1/2 of last
				end
			3'b011:
				begin
					Freq1 = 4'd15;
					Freq2 = 4'd3;
					counts = 20'd135134;
				end
			3'b100:
				begin
					Freq1 = 4'd16;
					Freq2 = 4'd3;
					counts = 20'd127550;
				end
			3'b101:
				begin
					Freq1 = 4'd10;
					Freq2 = 4'd3;
					counts = 20'd113635;
				end
			3'b110:
				begin
					Freq1 = 4'd11;
					Freq2 = 4'd3;
					counts = 20'd101238;
				end
			default:
				begin
					Freq1 = 4'd12;
					Freq2 = 4'd4;
					counts = 20'd95554;
				end
		endcase 
	end

	
	toneSynthSelector select(
    .Counts(counts),
    .clock(clock),
    .mode(en), // Switch to select mode: 0 for square wave, 1 for sine wave
    .Out(Tone),
    .readValid(readValid)
);

	// Frequency HEX
	HEXDisplay h0(
		.In(Freq1),
		.Digit(HEX0)
	);
	
	HEXDisplay h1(
		.In(Freq2),
		.Digit(HEX1)
	);
endmodule


module toneGenerator2(selection, clock, HEX0, HEX1, Tone, readValid, en);
	input en;
	input [2:0] selection;
	input clock;
	output [6:0] HEX0;
	output [6:0] HEX1;
	output signed [31:0] Tone;

	reg [3:0] Freq1;
	reg [3:0] Freq2;
	reg [19:0] counts;
	
	output readValid;

	always@(*) begin
		case(selection) // seven different choices
			3'b000:
				begin // These increment in frequency
					Freq1 = 4'd12;
					Freq2 = 4'd5;
					counts = 20'd47777;
				end
			3'b001:
				begin
					Freq1 = 4'd13;
					Freq2 = 4'd5;
					counts = 20'd42565; // 1/2 of last
				end
			3'b010:
				begin
					Freq1 = 4'd14;
					Freq2 = 4'd5;
					counts = 20'd37921; // 1/2 of last
				end
			3'b011:
				begin
					Freq1 = 4'd15;
					Freq2 = 4'd5;
					counts = 20'd33783;
				end
			3'b100:
				begin
					Freq1 = 4'd16;
					Freq2 = 4'd5;
					counts = 20'd31887;
				end
			3'b101:
				begin
					Freq1 = 4'd10;
					Freq2 = 4'd5;
					counts = 20'd28408;
				end
			3'b110:
				begin
					Freq1 = 4'd11;
					Freq2 = 4'd5;
					counts = 20'd25309;
				end
			default:
				begin
					Freq1 = 4'd12;
					Freq2 = 4'd6;
					counts = 20'd23888;
				end
		endcase 

	end
	
	toneSynthSelector select(
    .Counts(counts),
    .clock(clock),
    .mode(en), // Switch to select mode: 0 for square wave, 1 for sine wave
    .Out(Tone),
    .readValid(readValid)
);

	// Frequency HEX
	HEXDisplay h0(
		.In(Freq1),
		.Digit(HEX0)
	);
	
	HEXDisplay h1(
		.In(Freq2),
		.Digit(HEX1)
	);
endmodule




module HEXDecoder (input c0, c1, c2, c3, output h0, h1, h2, h3, h4, h5, h6);
	
	assign h0 = !((c0 | c1 | c2 | !c3) & (c0 | !c1 | c2 | c3) & 
						(!c0 | c1 | !c2 | !c3) & (!c0 | !c1 | c2 | !c3));
						
	assign h1 = !((c0 | !c1 | c2 | !c3) & (c0 | !c1 | !c2 | c3) & 
						(!c0 | c1 | !c2 | !c3) & (!c0 | !c1 | c2 | c3) &
						(!c0 | !c1 | !c2 | c3) & (!c0 | !c1 | !c2 | !c3));
						
	assign h2 = !((c0 | c1 | !c2 | c3) & (!c0 | !c1 | c2 | c3) & 
						(!c0 | !c1 | !c2 | c3) & (!c0 | !c1 | !c2 | !c3));
	
	assign h3 = !((c0 | c1 | c2 | !c3) & (c0 | !c1 | c2 | c3) & 
						(c0 | !c1 | !c2 | !c3) & (!c0 | c1 | c2 | !c3) &
						(!c0 | c1 | !c2 | c3) & (!c0 | !c1 | !c2 | !c3));
						
	assign h4 = !((c0 | c1 | c2 | !c3) & (c0 | c1 | !c2 | !c3) & 
						(c0 | !c1 | c2 | c3) & (c0 | !c1 | c2 | !c3) &
						(c0 | !c1 | !c2 | !c3) & (!c0 | c1 | c2 | !c3));
					
	assign h5 = !((c0 | c1 | c2 | !c3) & (c0 | c1 | !c2 | c3) & 
						(c0 | c1 | !c2 | !c3) & (c0 | !c1 | !c2 | !c3) &
						(!c0 | !c1 | c2 | !c3));
						
	assign h6 = !((c0 | c1 | c2 | c3) & (c0 | c1 | c2 | !c3) & 
						(c0 | !c1 | !c2 | !c3) & (!c0 | !c1 | c2 | c3));
						
endmodule

module HEXDisplay(input [3:0] In, output [6:0] Digit);
	
	HEXDecoder U1(
		.c0(In[3]),
		.c1(In[2]),
		.c2(In[1]),
		.c3(In[0]),
		.h0(Digit[0]),
		.h1(Digit[1]),
		.h2(Digit[2]),
		.h3(Digit[3]),
		.h4(Digit[4]),
		.h5(Digit[5]),
		.h6(Digit[6])		
	);

endmodule

module toneSynthSelector(
    input [19:0] Counts,
    input clock,
    input mode, // Switch to select mode: 0 for square wave, 1 for sine wave
    output signed [31:0] Out,
    output readValid
);

    wire signed [31:0] squareOut;
    wire signed [31:0] sineOut;
    wire squareReadValid, sineReadValid;

    // Instantiate square wave toneSynth
    toneSynthSquare squareSynth (
        .Counts(Counts),
        .clock(clock),
        .Out(squareOut),
        .readValid(squareReadValid)
    );

    // Instantiate sine wave toneSynth
    toneSynthSine sineSynth (
        .Counts(Counts),
        .clock(clock),
        .Out(sineOut),
        .readValid(sineReadValid)
    );

    // Output multiplexer
    assign Out = mode ? sineOut : squareOut;

    // ReadValid signal multiplexer
    assign readValid = mode ? sineReadValid : squareReadValid;

endmodule

module toneGENSelector(
    input clock,
    input mode, // Switch to select mode: 0 for square wave, 1 for sine wave
	 input mixer, // Key to select output tone: No press for individual, Press for mixed tone
    output signed [31:0] tone,
    output readValid,
	 input [2:0]switches1,
	 input [2:0]switches2,
	 input switch,
	 output [6:0] HEX0,
	 output [6:0] HEX1,
	 output [6:0] HEX2,
	output [6:0] HEX3
);
	
    wire signed [31:0] TONE1Out;
    wire signed [31:0] TONE2Out;
    wire TONE1ReadValid, TONE2ReadValid;

    // Instantiate square wave toneSynth
    toneGenerator t0(
	.selection(switches1), // selecting between different frequencies
	.clock(clock),
	.HEX0(HEX0),
	.HEX1(HEX1),
	.Tone(TONE1Out),
	.readValid(TONE1ReadValid),
	.en(switch)   ////enable sine or sqaure
);

    // Instantiate sine wave toneSynth
    toneGenerator2 t1(
	.selection(switches2), // selecting between different frequencies
	.clock(clock),
	.HEX0(HEX2),
	.HEX1(HEX3),
	.Tone(TONE2Out),
	.readValid(TONE2ReadValid),
	.en(switch)///enable sine or sqaure 
);



    // Output multiplexer
	 
	 // Logic to combine tones or select individual tone based on KEY[3]
	 wire signed [31:0] combinedTone = TONE1Out + TONE2Out; // Summing the tones
	 assign tone = ~mixer ? combinedTone : (~mode ? TONE1Out : TONE2Out); // Combined tone if mixer is pressed
    
	 ////assign tone = ~mode ? TONE1Out : TONE2Out;

    // ReadValid signal multiplexer
	 assign readValid = ~mixer ? (TONE1ReadValid & TONE2ReadValid) : (~mode ? TONE1ReadValid : TONE2ReadValid);
	 
    ////assign readValid = ~mode ? TONE1ReadValid : TONE2ReadValid;

endmodule


## Midnight City by M83 Song Player Module
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
