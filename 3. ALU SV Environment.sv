////////////////////Design Code/////////////////////////

module ALU_m (out,zero,opcode,data,accum,clk);
  input [2:0] opcode;
  input data,accum,clk;
  
    output reg out;
    output reg zero;

    always @(negedge clk) begin
        case(opcode)
            3'b000: out = accum; // HLT
            3'b001: out = accum; // SKZ
            3'b010: out = data + accum; // ADD
            3'b011: out = data & accum; // AND
            3'b100: out = data ^ accum; // XOR
            3'b101: out = data; // LDA
            3'b110: out = accum; // STO
            3'b111: out = accum; // JMP
            default: out = 3'b000;
        endcase

      zero = (accum == 1'b0) ? 1'b1 : 1'b0;
    end

endmodule


interface intf(input logic clk);
  logic [2:0] opcode;
  logic data, accum;
  logic out;
  logic zero;
  
endinterface

////////////////////////TestBench Code/////////////////////////

class transection;
  randc bit [2:0] opcode;
  randc bit data;
  randc bit accum;
        bit out;
        bit zero;
  
endclass


class generator;
  transection trans;
  virtual intf vif;
  
  function new(virtual intf inf);
    this.vif = inf;
  endfunction
  
  task run;
    repeat(1000) begin
    trans = new();
    trans.randomize();
    vif.opcode <= trans.opcode;
    vif.data <= trans.data;
    vif.accum <= trans.accum;
    end
  endtask
  
endclass


class monitor;
  mailbox mbx_m1, mbx_m2;
  transection trans1, trans2;
  
  virtual intf vif;
  
  covergroup cg;
    A : coverpoint trans1.opcode {
      bins b1 = {0};
      bins b2 = {1};
    }
    B : coverpoint trans1.data {
      bins b1 = {1};
      bins b2 = {0};
    }
    
  endgroup
  
  function new(virtual intf inf, mailbox mbx1, mbx2);
    this.vif = inf;
    this.mbx_m1 = mbx1;
    this.mbx_m2 = mbx2;
    cg = new();
  endfunction
  
  task run;
    repeat(1000) begin
      trans1 = new();
      trans2 = new();
     // @(negedge clk);
      trans1.opcode = vif.opcode;
      trans2.opcode = vif.opcode;
      trans1.data = vif.data;
      trans1.accum = vif.accum;
      trans1.out = vif.out;
      trans1.zero = vif.zero;
      @(negedge vif.clk)
      case(vif.opcode)
            3'b000: trans2.out = vif.accum; // HLT
            3'b001: trans2.out = vif.accum; // SKZ
            3'b010: trans2.out = vif.data + vif.accum; // ADD
            3'b011: trans2.out = vif.data & vif.accum; // AND
            3'b100: trans2.out = vif.data ^ vif.accum; // XOR
            3'b101: trans2.out = vif.data; // LDA
            3'b110: trans2.out = vif.accum; // STO
            3'b111: trans2.out = vif.accum; // JMP
            default: trans2.out = 3'b000;
        endcase
      
      trans2.zero = (vif.accum == 1'b0) ? 1'b1 : 1'b0;
      cg.sample();
      mbx_m1.put(trans1);
      mbx_m2.put(trans2);
    end
  endtask
  
endclass


class scoreboard;
  mailbox mbx_s1, mbx_s2;
  transection trans1, trans2;
  bit clk;
  
  function new(mailbox mbx1,mbx2);
    this.mbx_s1 = mbx1;
    this.mbx_s2 = mbx2;
  endfunction
  
  task run;
    repeat(1000) begin
      mbx_s1.get(trans1);
      $display("clk = %0b, trans = %0p",clk,trans1);
      
      mbx_s2.get(trans2);
      $display("clk = %0b, trans = %0p",clk,trans2);
      
      if(trans1.zero == 1 && trans1.out == trans2.out)
        $display("ALU TEST PASSED!!");
      else
        $display("TRY AGAIN");
    end
  endtask
  
endclass


module top();
  bit clk;
  
  intf inf(clk);
  
  ALU_m dut(inf.out, inf.zero, inf.opcode, inf.data, inf.accum, inf.clk);
  
  always #10 clk = ~clk;
  
  mailbox mbx1 = new;
  mailbox mbx2 = new;
  generator gen;
  monitor mon;
  scoreboard scr;
  
  initial begin
    gen = new(inf);
    mon = new(inf,mbx1,mbx2);
    scr = new(mbx1,mbx2);
    
    fork 
      gen.run();
      mon.run();
      scr.run();
    join_any
  end
  
  initial begin
    $monitor($time," accum = %0b, data = %0b, opcode = %0p, clk = %0d, zero = %0d, out = %0b",inf.accum, inf.data, inf.opcode, inf.clk, inf.zero, inf.out);
    #1000 $finish();
  end
  
endmodule