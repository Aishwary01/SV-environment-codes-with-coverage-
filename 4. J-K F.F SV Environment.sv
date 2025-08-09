//////////////////////////Design Code///////////////////////////////

module jk_ff(q,qb,j,k,clk);
  input j,k,clk;
  output reg q;
  output qb;
  
  always@(posedge clk) begin
    if(j == 1 && k == 0)
      q <= 1'b0;
    else if(j == 0 && k == 1)
      q <= 1'b1;
    else if(j == 1 && k == 1)
      q <= ~q;
  end
  
  assign qb = ~q;
endmodule

interface intf();
  logic clk;
  logic j,k,q;
  logic qb;
endinterface

////////////////////////TestBench Code///////////////////////////////

class packet;
  randc bit j;
  randc bit k;
  bit clk;
  bit q;
  bit qb;
  
  
  function void disp();
    $display($time,"\t clk : %0d, j : %0d, k : %0d, q : %0d, qb : %0d",clk,j,k,q,qb);
  endfunction
  
endclass

class generator;
  packet pkt;
  mailbox mbx_g;
  
  function new(mailbox mbx);
    this.mbx_g = mbx;
  endfunction
  
  task run();
    repeat(10) begin
    pkt = new();
    pkt.randomize();
    mbx_g.put(pkt);
    end
  endtask
  
  
endclass

class driver;
  packet pkt;
  mailbox mbx_d;
  virtual intf vif;
  
  function new(virtual intf inf, mailbox mbx);
    this.vif = inf;
    this.mbx_d = mbx;
  endfunction
  
  task run();
    repeat(10) begin
    pkt = new();
    mbx_d.get(pkt);
    vif.clk <= pkt.clk;
    vif.j <= pkt.j;
    vif.k <= pkt.k;
    end
  endtask
  
endclass

class monitor;
  packet pkt;
  mailbox mbx_m;
  virtual intf vif;
  
  function new(virtual intf inf, mailbox mbx);
    this.vif = inf;
    this.mbx_m = mbx;
  endfunction
  
  task run();
    repeat(10) begin
    pkt = new();
    pkt.clk = vif.clk;
    pkt.j = vif.j;
    pkt.k = vif.k;
    
    @(posedge vif.clk) begin
      if(pkt.j == 1 && pkt.k == 0)
        pkt.q = 1'b0;
      else if(pkt.j == 0 && pkt.k == 1)
        pkt.q = 1'b1;
      else if(pkt.j == 1 && pkt.k == 1)
        pkt.q = ~pkt.q;
    end
    
    //assign pkt.qb = ~pkt.q;
    mbx_m.put(pkt);
     
    end
  endtask
  
endclass

class scoreboard;
  packet pkt;
  mailbox mbx_s;
  
  function new(mailbox mbx);
    this.mbx_s = mbx;
  endfunction
  
  task run();
    repeat(10) begin
    pkt = new();
    mbx_s.get(pkt);
    
      if(pkt.qb == 1 && pkt.q == pkt.qb)
      $display("Flip-Flop Test Passed");
    else
      $display("Test Failed");
    end
  endtask
  
endclass

module top;
  bit clk;
  
  intf inf();
  
  jk_ff dut(inf.q, inf.qb, inf.j, inf.k, inf.clk);
  
  always #5 inf.clk = ~inf.clk;
  
  mailbox mbx;
  
  packet pkt;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard scr;
  
  initial begin
    mbx = new();
    pkt = new();
    gen = new(mbx);
    drv = new(inf,mbx);
    mon = new(inf,mbx);
    scr = new(mbx);
    
    fork
      pkt.disp();
      gen.run();
      drv.run();
      mon.run();
      scr.run();
    join
  end
  
  initial
   $monitor($time,"\t clk : %0d, j : %0d, k : %0d, q : %0d, qb : %0d",inf.clk,inf.j,inf.k,inf.q,inf.qb);
  
  initial
    #100 $finish();
  
endmodule