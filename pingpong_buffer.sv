module pingpong_buffer #(parameter PIXEL_COUNT = 768, parameter ADDR_WIDTH  = 20)(
    input  logic clk,         
    input  logic rst, 
	 input  vsync, 

    input  logic [9:0] vga_hc,     
    input  logic [9:0] vga_vc,      
    output logic [7:0] pixel_data_out, // pixel data to drive VGA (1 byte per pixel)

    input  logic [ADDR_WIDTH-1:0] write_addr,   // address for writing updated pixel
    input  logic [7:0] pixel_data_in // new pixel data (color)
);

  reg [7:0] buffer0 [0:PIXEL_COUNT-1];
  reg [7:0] buffer1 [0:PIXEL_COUNT-1];

  //selects which buffer is used for reading:
  logic read_sel;

  // Toggle the buffer selection at the start of a new frame.
  always_ff @(posedge clk) begin
    if (rst)
      read_sel <= 1'b0;
    else if (vga_hc == 10'b0 && vga_vc == 10'b0)
      read_sel <= ~read_sel;
  end

  // Calculate the read address from the VGA's horizontal and vertical counters.
  // Here we assume that your graphics controller also uses a blocked (reduced) resolution.
  // For example, if you block by a factor of 20, you might compute:
  logic [4:0] xpos, ypos;  // 5 bits are enough for 32 and 24 values respectively.
  assign xpos = vga_hc / 20;
  assign ypos = vga_vc / 20;
  
  // Combine x and y to form a linear address. In our example, there are 32 pixels per row.
  logic [ADDR_WIDTH-1:0] read_addr;
  assign read_addr = ypos * 5'd32 + xpos;

  // Read from the selected buffer.
  logic [7:0] read_data_reg;
  always_comb begin
    if (read_sel == 1'b0)
      read_data_reg = buffer0[read_addr];
    else
      read_data_reg = buffer1[read_addr];
  end

  assign pixel_data_out = read_data_reg;

  // Write to the *non-displayed* buffer.

  always_ff @(posedge clk) begin
      if (read_sel == 1'b0)
        buffer0[write_addr] <= pixel_data_in;
      else
        buffer1[write_addr] <= pixel_data_in;
  end

endmodule
