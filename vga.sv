module vga (
	input logic clk_50MHz,  
   input logic rst_btn,    // Reset button (active-low)

   output logic hsync,
   output logic vsync,
   output logic [3:0] red,
   output logic [3:0] green,
   output logic [3:0] blue

);

	logic clk_25MHz;
	logic rst_n;
	
	logic [9:0] hc_out;
	logic [9:0] vc_out;
	
	//Graphics Module Signals
	logic [9:0] pixel_addr;
	logic [2:0] gfx_red;
	logic [2:0] gfx_green;
	logic [1:0] gfx_blue;
	
	localparam SEED = 2'b11;
	logic [1:0] rst_shift_reg = SEED;
	logic rst_feedback;
	
	always_ff @(posedge clk_50MHz) begin
		rst_shift_reg <= {rst_feedback, rst_shift_reg[1]};
		
		if (rst_shift_reg == 2'b01) begin
			rst_n <= 1'b1;
		end else begin
			rst_n <= 1'b0;
		end
	end
	
	always_comb begin
		rst_feedback = rst_btn;
	end
	
	vgaclk(rst_n, clk_50MHz, clk_25MHz);
	
	//ping-pong buffer
	logic [7:0] pp_pixel_data;
	logic [7:0] pixel_data_in_combined;
	assign pixel_data_in_combined[7:0] = {gfx_red, gfx_green, gfx_blue};
	
	pingpong_buffer #(768,20)(clk_25MHz, rst_n, hc_out, vc_out, pp_pixel_data, pixel_addr, pixel_data_in_combined, gfx_red, gfx_green, gfx_blue);
	
	logic [2:0] final_red;
	logic [2:0] final_green;
	logic [1:0] final_blue;
	
	assign final_red = pp_pixel_data[7:5];
	assign final_green = pp_pixel_data[4:2];
	assign final_blue = pp_pixel_data[1:0];
	
	//vga_skeleton(clk_25MHz, rst_n, gfx_red, gfx_green, gfx_blue, hc_out, vc_out, hsync, vsync, red, green, blue);
	vga_skeleton(clk_25MHz, rst_n, final_red, final_green, final_blue, hc_out, vc_out, hsync, vsync, red, green, blue);
	
	graphics(hc_out, vc_out, pixel_addr, gfx_red, gfx_green, gfx_blue);

endmodule