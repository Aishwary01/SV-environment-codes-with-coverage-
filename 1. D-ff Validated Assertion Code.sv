///////////////////////Design Code////////////////////////////////

module d_ff(q,d,rst,clk);
  input d,rst,clk;
  output reg q;
  
  always@(posedge clk) begin
    if(!rst)
      q <= 1'b0;
    else
      q <= d;
  end
endmodule

///////////////////Assertion. SV file Code////////////////////////////////

module assertion_design(input q, d, rst, clk);

  property p1;
    @(posedge clk) disable iff(!rst) 
    (d == q);
  endproperty
 
  p1_assert: assert property(p1);
    
endmodule


///////////////////Testbench Code////////////////////////////////

`include "assertion.sv"
module tb;
  reg d,rst,clk;
  wire q;
  
  d_ff dut(q, d, rst, clk);
  
  bind d_ff assertion_design ass_int(.q(q), .d(d), .rst(rst), .clk(clk));
  
  initial begin
    clk = 0;
    rst = 0;
    #50 rst = 1;
    d = 0;
    #20 d = 1;
  end
  
  always #5 clk = ~clk;
  
  initial begin
    $monitor($time,"q = %b, d = %b, rst = %b, clk = %b",q,d,rst,clk);
    #100 $finish();
  end
  
endmodule