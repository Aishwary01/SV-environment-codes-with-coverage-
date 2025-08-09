//////////////////////Design code/////////////////////////
module jk_ff(q,qb,j,k,clk);
  input j,k,clk;
  output reg q;
  output qb;
  
  always@(posedge clk) begin
    if(j == 0 && k == 1)
      q <= 1'b0;
    else if(j == 1 && k == 0)
      q <= 1'b1;
    else if(j == 1 && k == 1)
      q <= ~q;
  end
  
  assign qb = ~q;
  
endmodule


///////////////////////////Assertion.sv File/////////////////////////

module assertion_design(input q,qb,j,k,clk);
  
  property p1;
    @(posedge clk)
    (j == 0 && k == 0) |-> q == q &&
    (j == 0 && k == 1) |-> q == 0 &&  
    (j == 1 && k == 0) |-> q == 1 && 
    (j == 1 && k == 1) |-> q == ~q;
  endproperty
  
  assertp1 : assert property(p1);
    
endmodule

///////////////////////Testbench Code//////////////////////////////

`include "assertion.sv"
module tb;
  reg j,k,clk;
  wire q, qb;
  
  jk_ff dut(q, qb, j, k, clk);
  
  bind jk_ff assertion_design ass_int(.q(q), .qb(qb), .j(j), .k(k), .clk(clk));
  
  always #5 clk = ~clk;
  
  initial begin
    clk = 0;
  #10  j = 0; k = 0;
  #10  j = 1; k = 0;
  #10  j = 0; k = 1;
  #10  j = 1; k = 1;
  end
  
  initial begin
    $monitor($time,"q = %b, qb = %b, j = %b, k = %b, clk = %b",q,qb,j,k,clk);
    #100 $finish();
  end
  
endmodule