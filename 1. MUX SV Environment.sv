////////////////////Design Code//////////////////////////

module mux_m(out,data_a,data_b,sel_a);
  input data_a,data_b;
  input sel_a;
  output reg out;
  
  always@(*) begin
    if(sel_a)
      out = data_a;
    else
      out = data_b;
  end
endmodule


interface intf();
  logic data_a, data_b;
  logic sel_a;
  logic out;
endinterface


class packet;
  randc bit data_a;
  randc bit data_b;
        bit sel_a;
        bit out;
endclass

class generator;
  packet pkt;
  
  virtual intf vif;
  function new(virtual intf inf);
    this.vif = inf;
  endfunction
  
  task run;
    repeat(1000) begin
    pkt = new();
    pkt.randomize();
    vif.data_a = pkt.data_a;
    vif.data_b = pkt.data_b;
    vif.sel_a = pkt.sel_a;
    end
  endtask
endclass


class monitor;
  mailbox mbx_m;
  packet pkt;
  
  virtual intf vif;
  
  covergroup cg;
    A : coverpoint pkt.data_a {
      bins b1 = {0};
      bins b2 = {1};
    }
    B : coverpoint pkt.data_b {
      bins b1 = {0};
      bins b2 = {1};
    }
    
  endgroup
  
  
  function new(virtual intf inf, mailbox mbx);
    this.vif = inf;
    this.mbx_m = mbx;
    cg = new();
  endfunction
  
  task run;
    repeat(1000) begin
      pkt = new();
      pkt.data_a = vif.data_a;
      pkt.data_b = vif.data_b;
      pkt.sel_a = vif.sel_a;
      //pkt.out = vif.out;

   
      if(vif.sel_a)
        pkt.out = pkt.data_a;
      else 
        pkt.out = pkt.data_b;
      
      cg.sample();
      mbx_m.put(pkt);
    end
  endtask
endclass




class scoreboard;
  mailbox mbx_s;
  packet pkt;
  
  function new(mailbox mbx);
    this.mbx_s = mbx;
  endfunction
  
  task run;
    repeat(1000) begin
      pkt = new();
      mbx_s.get(pkt);
      $display("pkt = %p",pkt);
      
      if(pkt.sel_a == 1 && pkt.out == pkt.data_a || pkt.out == pkt.data_b)
        $display("MUX Test Passed");
      else
        $display("Try more");
    end
  endtask
endclass


`include "interface.sv"
`include "packet.sv"
`include "generator.sv"
`include "monitor.sv"
`include "scoreboard.sv"

module top;
  intf inf();
  
  mux_m dut(inf.out, inf.data_a, inf.data_b, inf.sel_a);
  
  mailbox mbx = new;
  generator gen;
  monitor mon;
  scoreboard scr;
  
  initial begin
    gen = new(inf);
    mon = new(inf, mbx);
    scr = new(mbx);
    
    fork
      gen.run();
      mon.run();
      scr.run();
    join
  end
  
  initial
    $monitor($time, "\t data_a : %0b, data_b : %0b, sel_a : %0b, out : %0b",inf.data_a, inf.data_b, inf.sel_a, inf.out);
  
  initial
    #100 $finish();
  
endmodule