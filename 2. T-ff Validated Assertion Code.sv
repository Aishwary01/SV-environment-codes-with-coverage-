//////////////////////////Design cODE///////////////////////////////////

module t_ff(q,t,rst,clk);
  input t,rst,clk;
  output reg q;
  
  always@(posedge clk) begin
    if(!rst)
      q <= 1'b0;
    else
      q <= t;
  end
  
endmodule

////////////////////////Assertion.SV file //////////////////////////////////

module assertion_design(input q,t,rst,clk);
  
  property p1;
    @(posedge clk) disable iff(!rst)
    (t == q);
  endproperty
  
  assertp1 : assert property(p1);
    
endmodule

///////////////////////Testbench Code/////////////////////////////////////

`include "assertion.sv"
module tb;
  reg t,rst,clk;
  wire q;
  
  t_ff dut(q, t, rst, clk);
  
  bind t_ff assertion_design ass_int(.q(q), .t(t), .rst(rst), .clk(clk));
  
  always #5 clk = ~clk;
  
  initial begin
    clk = 0;
    rst = 0;
    #30 rst = 1;
    t = 0;
    #20 t = 1;
  end
  
  initial begin
    $monitor($time,"q = %b, t = %b, rst = %b, clk = %b",q,t,rst,clk);
    #100 $finish();
  end
  
endmodule