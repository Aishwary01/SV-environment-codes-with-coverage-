///////////////////////////Design Code////////////////////////////

module counter_m(count,data,load,rst,clk);
  input [4:0] data;
  input load, rst, clk;
  output reg [4:0] count;
  
  always@(posedge clk) begin
    if(!rst)
      count <= 0;
    else if(load)
      count <= data;
    else 
      count <= count + 1;
  end
  
endmodule


interface intf(input logic clk);
  logic [4:0] data;
  logic load, rst;
  logic [4:0] count;
  
endinterface
/////////////////////////Testbench////////////////////////////////

class transection;
  randc bit [4:0] data;
  randc bit load;
        bit rst;
        bit [4:0] count;
endclass


class generator;
  transection trans;
  mailbox mbx_g;
  
  function new(mailbox mbx);
    this.mbx_g = mbx;
  endfunction
  
  task run;
    repeat(2000) begin
    trans = new();
    trans.randomize();
    mbx_g.put(trans);  
    end
  endtask
  
endclass

class driver;
  transection trans;
  mailbox mbx_d;
  
  virtual intf vif;
  
  function new(virtual intf inf, mailbox mbx);
    this.vif = inf;
    this.mbx_d = mbx;
  endfunction
  
  task run;
    repeat(2000) begin
      trans = new();
      mbx_d.get(trans);
    vif.rst <= trans.rst;
    vif.data <= trans.data;
    vif.load <= trans.load;
    end
  endtask
  
endclass


class monitor;
  
  transection trans;
  mailbox mbx_m;
  virtual intf vif;
  
  covergroup cg;
    A: coverpoint trans.data{
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
    repeat(2000) begin
      trans = new();
      trans.rst = vif.rst;
      trans.data = vif.data;
      trans.load = vif.load;
      trans.count = vif.count;
      
      @(posedge vif.clk);
      if(vif.load)
        trans.count = vif.data;
      else
        trans.count = vif.count + 1;
      
      cg.sample();
      mbx_m.put(trans);
    end
  endtask
  
endclass


class scoreboard;
  transection trans;
  mailbox mbx_s;
  bit clk;
  
  function new(mailbox mbx);
    this.mbx_s = mbx;
  endfunction
  
  task run;
    repeat(2000) begin
      trans = new;
      mbx_s.get(trans);
      $display("clk = %0b, trans = %p",clk, trans);
      
      if(trans.rst == 1 && trans.count == trans.data || trans.count + 1)
        $display("COUNTER TEST PASSED!!");
      else
        $display("TRY AGAIN");
    end
  endtask
endclass


module top;
  bit clk;
  
  intf inf(clk);
  
  counter_m dut(inf.count, inf.data, inf.load, inf.rst, inf.clk);
  
  always #5 clk = ~clk;
  
  mailbox mbx = new;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard scr;
  
  initial begin
     inf.rst = 0;
 #50 inf.rst = 1;   
  end
  
  initial begin
    gen = new(mbx);
    drv = new(inf,mbx);
    mon = new(inf,mbx);
    scr = new(mbx);
    
    fork
      gen.run();
      drv.run();
      mon.run();
      scr.run();
    join_any
  end
  
  initial begin
    $monitor($time,"\t data = %0d, load = %0d, rst = %0d, clk = %0d, count = %0d",inf.data, inf.load, inf.rst, inf.clk, inf.count);
    #200 $finish();
  end
  
endmodule