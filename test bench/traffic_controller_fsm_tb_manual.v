`timescale 1ns / 1ps

module traffic_controller_fsm_tb_manual;

    // --- 1. Signal Declarations ---
    reg clk;
    reg reset;
    // Inputs for manual control
    reg A1, A2, A3, A4;        // Ambulance Inputs
    reg night_mode;            // Night Mode Input
    reg violation_force;       // New Violation Input

    wire [3:0] state_out;      // Current state output (4 bits)
    wire [71:0] violation_warning; // New Violation Output
    wire [23:0] R1_light;
    wire [23:0] R2_light;
    wire [23:0] R3_light;
    wire [23:0] R4_light;

    // Time parameters (Scaled for faster simulation)
    parameter T_CLK         = 10;          
    parameter T_DELAY       = 20;          
    parameter T_G_COUNT     = 100;         
    parameter T_Y_COUNT     = 20;          
    parameter T_F_COUNT     = 5;           

    // --- 2. Instantiate the Unit Under Test (UUT) ---
    traffic_controller_fsm #(
        .T_GREEN    (T_G_COUNT), 
        .T_YELLOW   (T_Y_COUNT), 
        .T_FLASH    (T_F_COUNT)
    ) UUT (
        .clk(clk),
        .reset(reset),
        .A1(A1), .A2(A2), .A3(A3), .A4(A4),
        .night_mode(night_mode),
        .violation_force(violation_force), // New connection
        .state_out(state_out),
        .R1_light(R1_light),
        .R2_light(R2_light),
        .R3_light(R3_light),
        .R4_light(R4_light),
        .violation_warning(violation_warning) // New connection
    );

    // --- 3. Clock Generation ---
    initial begin
        clk = 0;
        forever #(T_CLK/2) clk = ~clk;
    end

    // --- 4. Helper Task: Advances the simulation clock by a precise number of cycles ---
    task advance_time;
        input [31:0] cycles;
        begin
            repeat (cycles) @(posedge clk);
        end
    endtask

    // --- 5. Initialization and Main Test Sequence ---
    initial begin
        // Initialize ALL inputs to LOW (crucial for manual control)
        reset = 1;
        A1 = 0; A2 = 0; A3 = 0; A4 = 0;
        night_mode = 0;
        violation_force = 0; // Initialize new input

        $display("-------------------------------------------------------");
        $display("Starting Traffic Controller FSM (MANUAL CONTROL)");
        $display("-------------------------------------------------------");

        // Release Reset
        #(T_DELAY) reset = 0;
        $display("@%0t: Reset released. Normal cycle starts at R1 Green.", $time);

        // --- Execute Manual Test Framework ---
        task_manual_test_framework;
    end

    // --- 6. Manual Test Framework (Runs cycles and prompts user) ---
    task task_manual_test_framework;
        begin
            
            // Loop 1: R1 Green
            $display("\n@%0t: State S0_R1_G (R1 G). Inputs: A2/A3/A4, or night_mode will cause override.", $time);
            $display("Assert 'violation_force = 1' to trigger the VIOLATION warning.", $time);
            advance_time(T_G_COUNT);
            $display("@%0t: R1 Yellow (S1_R1_Y).", $time);
            advance_time(T_Y_COUNT);
            
            // Loop 2: R2 Green
            $display("\n@%0t: State S2_R2_G (R2 G). Inputs: A1/A3/A4, or night_mode will cause override.", $time);
            advance_time(T_G_COUNT);
            $display("@%0t: R2 Yellow (S3_R2_Y).", $time);
            advance_time(T_Y_COUNT);
            
            // Loop 3: R3 Green
            $display("\n@%0t: State S4_R3_G (R3 G). Inputs: A1/A2/A4, or night_mode will cause override.", $time);
            advance_time(T_G_COUNT);
            $display("@%0t: R3 Yellow (S5_R3_Y).", $time);
            advance_time(T_Y_COUNT);

            // Loop 4: R4 Green
            $display("\n@%0t: State S6_R4_G (R4 G). Inputs: A1/A2/A3, or night_mode will cause override.", $time);
            advance_time(T_G_COUNT);
            $display("@%0t: R4 Yellow (S7_R4_Y).", $time);
            advance_time(T_Y_COUNT);

            // Run the framework loop indefinitely 
            task_manual_test_framework; 
        end
    endtask

    // --- 7. Monitoring and Debugging ---
    initial begin
        $monitor("Time: %0t | State: %h | R1: %s R2: %s R3: %s R4: %s | Amb: %b%b%b%b | Night: %b | Violation: %s", 
                 $time, state_out, R1_light, R2_light, R3_light, R4_light,
                 A1, A2, A3, A4, night_mode, violation_warning);
    end

endmodule