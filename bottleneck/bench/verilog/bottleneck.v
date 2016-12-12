`timescale 1ns / 1ps

module test_bottleneck();
	reg clk_i, reset_i;
	reg [15:0] story_i;

	reg	[63:0]	m_adr_i;
	reg		m_cyc_i;
	reg	[63:0]	m_dat_i;
	reg		m_signed_i;
	reg	[1:0]	m_siz_i;
	reg		m_stb_i;
	reg		m_we_i;
	wire		m_ack_o;
	wire	[63:0]	m_dat_o;

	wire	[63:0]	s_adr_o;
	wire		s_cyc_o;
	wire		s_signed_o;
	wire		s_siz_o;
	wire		s_stb_o;
	wire		s_we_o;
	reg		s_ack_i;
	reg	[15:0]	s_dat_i;

	bottleneck b(
		.m_adr_i(m_adr_i),
		.m_cyc_i(m_cyc_i),
		.m_dat_i(m_dat_i),
		.m_signed_i(m_signed_i),
		.m_siz_i(m_siz_i),
		.m_stb_i(m_stb_i),
		.m_we_i(m_we_i),
		.m_ack_o(m_ack_o),
		.m_dat_o(m_dat_o),
		.s_adr_o(s_adr_o),
		.s_cyc_o(s_cyc_o),
		.s_signed_o(s_signed_o),
		.s_siz_o(s_siz_o),
		.s_stb_o(s_stb_o),
		.s_we_o(s_we_o),
		.s_ack_i(s_ack_i),
		.s_dat_i(s_dat_i)
	);

	always begin
		#20 clk_i <= ~clk_i;
	end

	task tick;
	input [7:0] substory;
	begin
		story_i <= {story_i[15:8], substory};
		@(clk_i);
		@(~clk_i);
		#10;
	end
	endtask

	task scenario;
	input [7:0] story;
	begin
		story_i <= {story, 8'h00};
		tick(8'h00);
		$display("@S SCENARIO %0d (8'h%02X)", story, story);
	end
	endtask

	task assert_s_adr_o;
	input [63:0] expected;
	begin
		if(s_adr_o !== expected) begin
			$display("@E %04X S_ADR_O Expected $%016X Got $%016X", story_i, expected, s_adr_o);
			$stop;
		end
	end
	endtask

	task assert_s_cyc_o;
	input expected;
	begin
		if(s_cyc_o !== expected) begin
			$display("@E %04X S_CYC_O Expected %d Got %d", story_i, expected, s_cyc_o);
			$stop;
		end
	end
	endtask

	task assert_s_signed_o;
	input expected;
	begin
		if(s_signed_o !== expected) begin
			$display("@E %04X S_SIGNED_O Expected %d Got %d", story_i, expected, s_signed_o);
			$stop;
		end
	end
	endtask

	task assert_s_siz_o;
	input expected;
	begin
		if(s_siz_o !== expected) begin
			$display("@E %04X S_SIZ_O Expected %d Got %d", story_i, expected, s_siz_o);
			$stop;
		end
	end
	endtask

	task assert_s_stb_o;
	input expected;
	begin
		if(s_stb_o !== expected) begin
			$display("@E %04X S_STB_O Expected %d Got %d", story_i, expected, s_stb_o);
			$stop;
		end
	end
	endtask

	task assert_s_we_o;
	input expected;
	begin
		if(s_we_o !== expected) begin
			$display("@E %04X S_WE_O Expected %d Got %d", story_i, expected, s_we_o);
			$stop;
		end
	end
	endtask

	task assert_m_ack_o;
	input expected;
	begin
		if(m_ack_o !== expected) begin
			$display("@E %04X M_ACK_O Expected %d Got %d", story_i, expected, m_ack_o);
			$stop;
		end
	end
	endtask

	task assert_m_dat_o;
	input [63:0] expected;
	begin
		if(m_dat_o !== expected) begin
			$display("@E %04X M_DAT_O Expected %016X Got %016X", story_i, expected, m_dat_o);
			$stop;
		end
	end
	endtask

	task test_byte_rd;
	begin
		scenario(8'h01);

		m_adr_i <= 64'h4444_3333_2222_1111;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b00;
		m_stb_i <= 1;
		m_we_i  <= 0;
		tick(8'h01);
		assert_s_adr_o(64'h4444_3333_2222_1111);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(2'b00);
		assert_s_stb_o(1);
		assert_s_we_o(0);

		s_ack_i <= 0;
		s_dat_i <= 16'h00AA;
		tick(8'h02);
		assert_m_ack_o(0);

		s_ack_i <= 1;
		tick(8'h03);
		assert_m_ack_o(1);
		assert_m_dat_o(64'hFFFF_FFFF_FFFF_FFAA);

		m_signed_i <= 0;
		tick(8'h04);
		assert_m_dat_o(64'h0000_0000_0000_00AA);
	end
	endtask

	initial begin
		clk_i <= 0;
		reset_i <= 0;
		tick(8'h00);

		test_byte_rd();

		$display("@I Done.");
		$stop;
	end
endmodule

