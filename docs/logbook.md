# Project Logbook – FPGA Distortion Pedal
-----

## Entry 1 — Project Start  
**Date:** Nov 21, 2025  
**Time:** 8:00 PM  

### Summary  
Started planning a real-time digital distortion pedal implemented on the Altera DE2-115 FPGA.  
Initial goal is to build audio passthrough using the WM8731 audio codec, then implement a simple distortion stage, and later add multiple presets.

### Work Completed
- Created github repo and folder structure ('src', 'test','docs').
- Added first readme
- Defined primary goal: digital distortion pedal running on fpga
- Created "high_level_design" to map-out current plans and goals for the project
- Using Lucidchart created a high level block diagram "block_diagram_fpga_distortion_pedal"

-----

## Entry 2 — Research  
**Date:** Nov 24, 2025  
**Time:** 11:58 AM 

### Summary  
Started researching and learning about Verilog via Youtube and my EE232 Digital Electronics class.

### Notes
- Modules are the basic building blocks of Verilog, code looks similar to functions/methods:
module and_gate(input a, input b, output c);
    assign c = a & b;
endmodule
- Data types: Net (wire), Reg (value stored over time), Integer (32 bit signed), Real (stores floating point numbers)
- Opperators seem same as standard language, *Note << and >> are shift operators, they also have bitwise logic gates:
& is and gate
| is or
^ is xor
^~ is xnor
~ is nor
- Seems very similar to EE232 digital electronics class just in code. Also reminds me of using the Quartus softwares circuit desgin but in code.
- We can use #(N) in ns to make a delay of 10ns eg: and#(10) (out, in1, in2)
- array eg: reg [7:0] my_array[0:15]; array of 16 elements each 8 bits

### Thoughts
- I need to order a 1/4" TS to 3.5mm TRS adapter.

-----