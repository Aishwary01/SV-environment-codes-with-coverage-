//////////////////////////////Design Code////////////////////////////

module sr_ff(q,qb,s,r,clk);
  input s,r,clk;
  output reg q;
  output qb;
  
  always@(posedge clk) begin
    if(s == 0 && r == 1)
      q <= 1'b0;
    else if(s == 1 && r == 0)
      q <= 1'b1;
    else if(s == 1 && r == 1)
      q <= ~q;
  end
  
  assign qb = ~q;
  
endmodule


///////////////////////Assertion.sv file///////////////////////////////////

module assertion_design(input q,qb,s,r,clk);
  
  property p1;
    @(posedge clk) 
    (s == 0 && r == 0) |-> q == q &&
    (s == 0 && r == 1) |-> q == 0 &&
    (s == 1 && r == 0) |-> q == 1 &&
    (s == 1 && r == 1) |-> q == ~q;
  endproperty
  
  assert_p1 : assert property(p1);
    
endmodule

/////////////////////Testbench Code//////////////////////////////////////

`include "assertion.sv"
module tb;
  reg s,r,clk;
  wire q,qb;
  
  sr_ff dut(q, qb, s, r, clk);
  
  bind sr_ff assertion_design ass_inst(.q(q), .qb(qb), .s(s), .r(r), .clk(clk));
  
  always #5 clk = ~clk;
  
  initial begin
    clk = 0;
      s = 0;r = 0;
  #10 s = 0;r = 1;
  #10 s = 1;r = 0;
  #10 s = 1;r = 1;  
  end
  
  initial begin
    $monitor($time,"\t q = %b, qb = %b, s = %b, r = %b, clk = %b",q,qb,s,r,clk);
    #100 $finish();
  end
  
endmodule