# **Multi-Priority Traffic Light Controller (FSM)**

A robust Verilog implementation of a 4-way intersection traffic controller. This project utilizes a Finite State Machine (FSM) to manage complex traffic scenarios, including high-priority emergency vehicle overrides, low-traffic "Night Mode" operation and Traffic rules violation.

#### 

#### **Software Requirements**

**To run and verify this project, you will need the following tools:**



###### **1. Simulation (To run the code)**

You can use any standard Verilog simulator. The most common open-source and professional options are:

1. **Icarus Verilog** – A lightweight, open-source compiler and simulator. Highly recommended for beginners.
2. **ModelSim / QuestaSim** – The industry-standard simulator from Siemens/Mentor Graphics.
3. **Vivado Design Suite** – Used if you are targeting Xilinx FPGAs.



###### **2. Waveform Viewer (To see the results)**

To visualize the traffic light changes over time, you need a tool to view the .vcd (Value Change Dump) files:

1. **GTKWave** – An open-source, fully-featured waveform viewer that works perfectly with Icarus Verilog.



###### **3. Synthesis \& Hardware (To put it on an FPGA)**

If you intend to deploy this FSM to physical hardware:

1. **Xilinx Vivado** (for Artix/Kintex FPGAs)
2. **Intel Quartus Prime** (for Cyclone/MAX FPGAs)



### **Features**

* 4-Way Sequential Control: Standard Green-Yellow-Red cycle for four roads.



* Emergency Vehicle Priority (A1-A4): Immediate asynchronous override for ambulances or emergency responders.



* Night Mode: Medium-priority mode that transitions the system into a flashing yellow/off state to conserve energy and alert drivers.



* Violation Detection: A dedicated input to flag traffic violations (violation\_force) which triggers a "VIOLATION" warning on the output bus.



* Parameterizable Timing: Easily adjustable constants for Green, Yellow, and Flashing durations.



### **Technical Specifications**

FSM State Encoding :The FSM is designed using a 4-bit state register to handle 14 unique states:



* 4'b0000 to 4'b0111: Normal Road 1 through Road 4 cycles.



* 4'b1000 to 4'b1011: Dedicated Emergency states for each road.



* 4'b1100 to 4'b1101: Night mode flashing states.



### **Signal Definitions:**

#### **Control Signals (The "Brains")**

* clk (Clock): The heartbeat of the system. Every transition (like changing from Green to Yellow) happens on the rising edge of this signal.



* reset: A safety switch. When activated (set to 1), it immediately forces the traffic light back to the starting state (Road 1 Green) and clears all timers, regardless of what else is happening.



#### **Input Sensors (The "Environment")**

* A1, A2, A3, A4 (Ambulance Sensors): These represent high-priority sensors (like infrared or sound sensors) that detect an approaching emergency vehicle. If A1 is high, the system forces Road 1 to Green immediately to clear traffic.



* night\_mode: A switch typically controlled by a timer or light sensor. When active, it stops the normal circular flow and puts the intersection into a "Caution" mode where lights flash yellow.



* violation\_force: A manual or camera-linked input. If a car breaks a rule (like running a red light), this signal goes high to trigger a warning system.



#### **Status Outputs (The "Feedback")**

* state\_out: A 4-bit code that tells an external monitor or engineer exactly which state the internal logic is in (e.g., 0000 for Road 1 Green).



* violation\_warning: A text-based output bus that carries the words "NORMAL" or "VIOLATION". This would typically connect to a display board or a logging system.



#### **Light Outputs (The "Visuals")**

* R1\_light, R2\_light, R3\_light, R4\_light: These are the actual signals sent to the physical traffic light heads for each of the four roads.



* They are 24 bits wide because they carry ASCII characters: "G" for Green, "Y" for Yellow, and "R" for Red.
* This makes the simulation waveform very easy to read for humans.



#### **Signal Priority Summary**

Priority Level	Signal	Resulting Action

1.(Highest)	A1-A4	Forces Green on the specific road for emergency passage.

2\.	night\_mode	Overrides normal cycle for flashing yellow caution.

3.(Lowest)	Normal Cycle	Cycles through Roads 1-4 using T\_GREEN and T\_YELLOW timers.

4.Independent	violation\_force	Triggers the violation warning regardless of the current light color.



