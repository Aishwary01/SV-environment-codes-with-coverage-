////////////////////////////////////////////////Assetion Codes//////////////////////////////////
Immediate Assertion in always Block

module immediate_assertion_example;
  reg clk, reset, enable;
  reg [3:0] data;
initial begin
    clk = 0;
    reset = 1;
    enable = 0;
    data = 4'd0;
    #5 reset = 0;
    #10 enable = 1;
    #20 data = 4'd8;
  end
// Toggle clock every 5-time units
  always #5 clk = ~clk;
// Immediate assertion to check if 'data' is non-zero when 'enable' is active
  always @(posedge clk) begin
    if (enable) begin
      assert (data != 4'd0) else $error("Assertion failed: data should not be zero when enable is high");
    end
  end
endmodule


Immediate Assertion in initial Block

module immediate_assertion_initial_example;
  reg [7:0] counter;

  initial begin
    counter = 8'd100;

    // Immediate assertion to check if 'counter' starts within a valid range
    assert (counter >= 0 && counter <= 200)
      else $fatal("Assertion failed: counter is out of valid range at initialization");
  end
endmodule



//////////////////////////////////////////////Concurent Assertion example///////////////////////////////////////////////////

////////////////Design CODE/////////////////
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

////////////////Assertion.SV File ///////////
module assertion_design(input q,t,rst,clk);
  
  property p1;
    @(posedge clk) disable iff(!rst)
    (t == q);
  endproperty
  
  assertp1 : assert property(p1);
    
endmodule

/////////////Testbench Code///////////////////
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

//////////////////////////////////////////////////////////Assertion with Clock Resolution//////////////////////////////////

module clocked_assertion_with_delay_example;
  reg clk, enable;
  reg [3:0] data;

  initial begin
    clk = 0;
    enable = 0;
    data = 4'd0;
    #5 enable = 1;
    #20 data = 4'd8;  // data becomes non-zero after 2 clock cycles
  end

  // Generate a clock with a period of 10-time units
  always #5 clk = ~clk;

  // Define a property with a delay of 2 cycles using ##
  property data_non_zero_within_two_cycles;
    @(posedge clk) enable |-> ##2 (data != 4'd0);
  endproperty

  // Assert the property
  assert property (data_non_zero_within_two_cycles) else $error("Assertion failed: data did not become non-zero within 2 clock cycles after enable was asserted");
initial
   $finish();
endmodule




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////Assertion with Implication Operator//////////////////////////////////


module implication_assertion_example;
  reg clk, enable;
  reg [3:0] data;

  initial begin
    clk = 0;
    enable = 0;
    data = 4'd0;
    #5 enable = 1;
    #10 data = 4'd8;  // data becomes non-zero
  end

  // Generate a clock with a period of 10-time units
  always #5 clk = ~clk;

  // Define a property with immediate implication
  property data_non_zero_when_enable;
    @(posedge clk) enable |-> (data != 4'd0);
  endproperty

  // Assert the property
  assert property (data_non_zero_when_enable) else $error("Assertion failed: data is zero when enable is high");
 initial
      $finish();
endmodule


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////Assertion with overlapped Operator//////////////////////////////////////////


module overlapped_implication_example;
  reg clk, start, ready;

  initial begin
    clk = 0;
    start = 0;
    ready = 0;
    #5 start = 1;        // start goes high at 5-time units
    #15 ready = 1;       // ready goes high within 2 cycles after start
  end

  // Generate a clock with a period of 10-time units
  always #5 clk = ~clk;

  // Define a property with overlapped implication
  property ready_within_two_cycles_of_start;
    @(posedge clk) start |=> ##[0:2] ready;
  endproperty

  // Assert the property
  assert property (ready_within_two_cycles_of_start) else $error("Assertion failed: ready did not go high within 2 cycles of start");
 initial
      $finish();
endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////Assertion with Repetition Operator//////////////////////////////////////////


module assertion_with_range_repetition;
  reg clk, start, busy;

  initial begin
    clk = 0;
    start = 0;
    busy = 0;
    #5 start = 1;
    #10 busy = 1;      // busy goes high after start
    #40 busy = 0;      // busy goes low after 4 cycles
  end

  // Generate a clock with a period of 10-time units
  always #5 clk = ~clk;

  // Define a property with range repetition
  property busy_high_for_2_to_5_cycles;
    @(posedge clk) start |-> (busy [*2:5]);
  endproperty

  // Assert the property
  assert property (busy_high_for_2_to_5_cycles) else $error("Assertion failed: busy did not stay high for 2 to 5 cycles after start");
 initial
      $finish();
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////Assertion with Go to repetition operator///////////////////////////////////

module assertion_with_goto_repetition;
  reg clk, enable, busy;

  initial begin
    clk = 0;
    enable = 0;
    busy = 0;
    #5 enable = 1;
    #10 busy = 1;      // busy goes high after enable
    #40 busy = 0;      // busy goes low after at least 3 cycles
  end

  // Generate a clock with a period of 10-time units
  always #5 clk = ~clk;

  // Define a property with Go To repetition
  property busy_high_for_at_least_3_cycles;
    @(posedge clk) enable |-> (busy [*->3]);  //The syntax for 'goto repetition' has been changed from '[*->' to '[->'.
  endproperty

  // Assert the property
  assert property (busy_high_for_at_least_3_cycles) else $error("Assertion failed: busy did not stay high for at least 3 cycles after enable");
 initial
      $finish();
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////Assertion with Non-consecutive repetition ///////////////////////////////////////


module assertion_with_non_consecutive_repetition;
  reg clk, start, ready;

  initial begin
    clk = 0;
    start = 0;
    ready = 0;
    #5 start = 1;
    #10 ready = 1; #10 ready = 0; // 1st occurrence of ready high
    #20 ready = 1; #10 ready = 0; // 2nd occurrence of ready high
    #20 ready = 1; #10 ready = 0; // 3rd occurrence of ready high
  end
  // Generate a clock with a period of 10-time units
  always #5 clk = ~clk;

  // Define a property with non-consecutive repetition
  property ready_high_at_least_3_times;
    @(posedge clk) start |-> (ready [*=3]);  //The syntax for 'non-consecutive repetition' has been changed from '[*=' to '[='.
  endproperty

  // Assert the property
  assert property (ready_high_at_least_3_times) else $error("Assertion failed: ready did not go high at least 3 times after start");
 initial
      $finish();
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////Assertion with The “and" ,“or" constructs/////////////////////////////////////////


module assertion_with_sequence_and_or;
  reg clk, start, enable, ready;

  initial begin
    clk = 0; start = 0; enable = 0; ready = 0;
    #5 start = 1;  //start goes high at time 5
    #10 enable = 1; // enable goes high within 2 cycles after start
    #15 ready = 1;  // ready goes high within 3 cycles after start
  end

  // Generate a clock with a period of 10-time units
  always #5 clk = ~clk;

  // Define Sequence 1: start followed by enable high within 2 cycles
  sequence seq1;
    start ##[1:2] enable;
  endsequence
// Define Sequence 2: start followed by ready high within 3 cycles
  sequence seq2;
    start ##[1:3] ready;
  endsequence

  // Define a property using `and` to combine seq1 and seq2
  property start_implies_seq1_and_seq2;
    @(posedge clk) (seq1 and seq2);
  endproperty

  // Define a property using `or` to combine seq1 and seq2
  property start_implies_seq1_or_seq2;
    @(posedge clk) (seq1 or seq2);
  endproperty

  // Assert the properties
  assert property (start_implies_seq1_and_seq2) else $error("Assertion failed: Both seq1 and seq2 did not hold true after start");
  assert property (start_implies_seq1_or_seq2) else $error("Assertion failed: Neither seq1 nor seq2 held true after start");
 initial
      $finish();
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////Assertion with Intersection construct//////////////////////////////////////////


module assertion_with_intersection;
  reg clk, start, busy, ready;

  initial begin
    clk = 0;
    start = 0;
    busy = 0;
    ready = 0;
    #5 start = 1;              // start goes high at time 5
    #10 busy = 1;              // busy goes high within 2 cycles after start
    #15 ready = 1;             // ready goes high within 3 cycles after start
    #20 busy = 0; ready = 0;   // both go low after some overlap
  end

  // Generate a clock with a period of 10-time units
  always #5 clk = ~clk;

  // Define Sequence 1: start followed by busy within 2 cycles
  sequence seq1;
start ##[1:2] busy;
  endsequence

  // Define Sequence 2: start followed by ready within 3 cycles
  sequence seq2;
    start ##[1:3] ready;
  endsequence

  // Define a property using the intersection operator
  property start_implies_busy_and_ready_overlap;
    @(posedge clk) (seq1 intersect seq2);
  endproperty

  // Assert the property
  assert property (start_implies_busy_and_ready_overlap) else $error("Assertion failed: busy and ready did not overlap within the required cycles after start");
 initial
      $finish();
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
