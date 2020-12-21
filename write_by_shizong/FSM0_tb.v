`include "para.v"

// ============================================
// Finite State Machine Flag
// 0: Write data from DRAM to FSRAM
// ============================================

module FSM0_tb;

reg									clk;
reg									rst_n;
reg									start;
reg		[`CHANNEL_OUT * 8 - 1 : 0]	data_in_1;

wire								CENA_1;
wire								CENB_1;
wire	[`SRAM_NUM - 1 : 0]			WENA_1;
wire	[`SRAM_NUM - 1 : 0]			WENB_1;
wire	[10:0]						AA_1;
wire	[`SRAM_NUM * 16 - 1 : 0]	DA_1;
wire	[10:0]						AB_1;
wire	[`SRAM_NUM * 16 - 1 : 0]	DB_1;
wire	[`SRAM_NUM * 16 - 1 : 0]	QA_1;
wire	[`SRAM_NUM * 16 - 1 : 0]	QB_1;

wire								CEN1_ir;
wire	[`SRAM_NUM - 1 : 0]			WEN1_ir;

wire								CEN2_ir;
wire	[`SRAM_NUM - 1 : 0]			WEN2_ir;

wire	[7 - 1 : 0]					A1_ir;
wire	[`SRAM_NUM * 16 - 1 : 0]	D1_ir;

wire	[7 - 1 : 0]					A2_ir;
wire	[`SRAM_NUM * 16 - 1 : 0]	D2_ir;
wire 	[`SRAM_NUM * 16 - 1 : 0]	Q1;
wire 	[`SRAM_NUM * 16 - 1 : 0]	Q2;

reg		[99 * 8:0]					fin_name;
reg		[7:0]						data_mem_tmp[0 : `ROW * `COL - 1];
reg		[`CHANNEL_IN * 8 - 1 : 0]	data_mem[0:7][0:7];

integer								fp;
integer								scan_i;
integer								i;
integer								j;
integer								row;
integer								col;

sram_controller_newIRSRAM FSM0(
	.clk(clk),
	.rst_n(rst_n),
	.start(start),
	.data_in_1(data_in_1),
	.data_in_1_2(),
	.CENA_1(CENA_1),
	.CENB_1(CENB_1),
	.WENA_1(WENA_1),
	.WENB_1(WENB_1),
	.AA_1(AA_1),
	.DA_1(DA_1),
	.AB_1(AB_1),
	.DB_1(DB_1),
	.data_in_2(),
	.data_in_2_2(),
	.CENA_2(),
	.CENB_2(),
	.WENA_2(),
	.WENB_2(),
	.AA_2(),
	.DA_2(),
	.AB_2(),
	.DB_2(),
	.weight_in(),
	.CEN_w(),
	.WEN_w(),
	.A_w(),
	.D_w(),
	.CEN1_ir(CEN1_ir),
	.CEN2_ir(CEN2_ir),
	.WEN1_ir(WEN1_ir),
	.WEN2_ir(WEN2_ir),
	.A1_ir(A1_ir),
	.A2_ir(A2_ir),
	.D1_ir(D1_ir),
	.D2_ir(D2_ir),
	.Q1(Q1),
	.Q2(Q2),
	.CEN_or(),
	.WEN_or(),
	.A_or(),
	.D_or(),
	.sram_sel1(),
	.sram_sel2(),
	.data_process_reg(),
	.CCM_en(),
	.CCM_en_cnt(),
	.Weight_en()
);




generate
irsram irsram1(
	.clk(clk),
	.CEN(CEN1_ir),
	.WEN(WEN1_ir),
	.A({`SRAM_NUM{A1_ir}}),
	.D(D1_ir),
	.Q(Q1)
	);
	end

endgenerate


irsram irsram2(
	.clk(clk),
	.CEN(CEN2_ir),
	.WEN(WEN2_ir),
	.A({`SRAM_NUM{A2_ir}}),
	.D(D2_ir),
	.Q(Q2)
);

endgenerate


initial begin
	$dumpfile("wave/FSM0.vcd");
	$dumpvars(0, FSM0_tb);

	for(i = 0; i < 4; i = i + 1) begin
		fin_name = $sformatf("../input/input%0d.txt", i+1);
		fp = $fopen(fin_name, "r");

		for(j = 0; j < `ROW * `COL; j = j + 1) begin
			scan_i = $fscanf(fp, "%h", data_mem_tmp[j]);
		end

		for(row = 0; row < `ROW; row = row + 1) begin
			for(col = 0; col < `COL; col = col + 1) begin
				data_mem[row][col][(i + 1) * 8 - 1 -: 8] = data_mem_tmp[6*row+col];
			end
		end
	end

	clk = 0;
	#1 rst_n = 0;
	#3 rst_n = 1;

	#5
	start = 1;

	// ============================================
	// Simulate data output from DRAM (already sorted)
	// ============================================
	row = 0;
	@(posedge clk)
	for(col = 0; col < `COL; col = col + 1) begin
		@(posedge clk)
		data_in_1 = #1 {{28{8'd0}}, data_mem[row][col]};
	
		@(posedge clk)
		data_in_1 = #1 {{28{8'd0}}, data_mem[row+1][col]};
	end

	for(row = 2; row < `ROW; row = row + 1) begin
		for(col = 0; col < `COL; col = col + 1) begin
			@(posedge clk)
			if(row % 2 == 1) begin
				data_in_1 = #1 {{28{8'd0}}, data_mem[row][col]};
			end
			else begin
				data_in_1 = #1 {{28{8'd0}}, data_mem[row][`COL - col - 1]};
			end
		end
	end

	#1000 $finish;
end

always #`HALF_CLK clk = ~clk;

endmodule