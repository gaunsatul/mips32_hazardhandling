# mips32_hazardhandling
The MIPS 32-bit CPU, known for its efficiency faces hazards in its pipeline, slowing down the processor. Our task is to find and fix these hazards using a forwarding unit in the Verilog code. The goal is to make the MIPS CPU work better by eliminating the hazards and thereby improving performance. 

Xilinx Vivado tool simulator has been used for this project for program execution and simulation. 
Hardware description language (HDL) used: Verilog

Reference to the user:

-> MIPS_hazard_handling.srcs/sources_1/new
Has the Link for both with Forwarding and Without Forwarding Unit.

-> MIPS_hazard_handling.srcs/sources_1/new/mips_without_fwd.v
Is the code which faces errors.

-> MIPS_hazard_handling.srcs/sim_1/new
Location has all the test bench codes.

-> MIPS_hazard_handling.srcs/sim_1/new/tb1_mips_Nfwd.v
Is the Testbench code for Without Forwarding Unit

-> MIPS_hazard_handling.srcs/sources_1/new/mips_with_fwd.v
Is the code in which we introduce a forwarding unit removing the errors.

-> MIPS_hazard_handling.srcs/sim_1/new/tb2_mips_fwd.v
Location of the First Testbench With forwarding unit

-> MIPS_hazard_handling.srcs/sim_1/new/tb3_mips_fwd.v
Location of the Second Testbench With forwarding unit

-> MIPS_hazard_handling.srcs/sim_1/new/tb4_mips_fwd.v
Location of the Third Testbench With forwarding unit
