module traffic_controller_fsm (
    input clk,               // Clock signal
    input reset,             // Asynchronous reset (Active High)
    // Ambulance Inputs (Highest Priority - Immediate Override)
    input A1, A2, A3, A4,    
    // Night Mode Input (Medium Priority - Flashing Override)
    input night_mode,        
    // Violation Input (Independent Output Trigger)
    input violation_force,   // New input: 1 to flag a violation

    output [3:0] state_out,     // Current state output (reduced to 4 bits)
    output [71:0] violation_warning, // New output: "VIOLATION" or "NORMAL"
    output [23:0] R1_light,    
    output [23:0] R2_light,    
    output [23:0] R3_light,    
    output [23:0] R4_light     
);

    // --- Timing Parameters ---
    parameter T_GREEN     = 32'd40000000;
    parameter T_YELLOW    = 32'd3000000;
    parameter T_FLASH     = 32'd500000; 

    // --- Encoding Constants ---
    localparam G = "G";
    localparam Y = "Y";
    localparam R = "R";
    localparam VIOLATION = "VIOLATION";
    localparam NORMAL    = "NORMAL";

    // --- State Encoding (Simplified to 4 bits) ---
    localparam S0_R1_G     = 4'b0000; 
    localparam S1_R1_Y     = 4'b0001; 
    localparam S2_R2_G     = 4'b0010; 
    localparam S3_R2_Y     = 4'b0011; 
    localparam S4_R3_G     = 4'b0100; 
    localparam S5_R3_Y     = 4'b0101; 
    localparam S6_R4_G     = 4'b0110; 
    localparam S7_R4_Y     = 4'b0111; 
    
    // Dedicated Emergency States (for output consistency)
    localparam S_EMERGENCY_R1    = 4'b1000; 
    localparam S_EMERGENCY_R2    = 4'b1001; 
    localparam S_EMERGENCY_R3    = 4'b1010;
    localparam S_EMERGENCY_R4    = 4'b1011;
    
    // Night Mode States
    localparam S_FLASH_RY_R = 4'b1100; 
    localparam S_FLASH_OFF  = 4'b1101; 

    // --- State and Timer Registers ---
    reg [3:0] current_state, next_state; 
    reg [31:0] timer_count;
    reg [2:0] emergency_road_reg; 

    // --- Output Registers ---
    reg [23:0] R1_light_reg, R2_light_reg, R3_light_reg, R4_light_reg;
    reg [71:0] violation_warning_reg;

    // Assign internal registers to the output ports
    assign R1_light  = R1_light_reg; 
    assign R2_light  = R2_light_reg;
    assign R3_light  = R3_light_reg;
    assign R4_light  = R4_light_reg;
    assign state_out = current_state;
    assign violation_warning = violation_warning_reg;

    // --- Combinational Logic for Priority Encoder and Violation Output ---
    always @(*) begin
        // Ambulance Priority Encoder
        if (A1) emergency_road_reg = 3'd1;
        else if (A2) emergency_road_reg = 3'd2;
        else if (A3) emergency_road_reg = 3'd3;
        else if (A4) emergency_road_reg = 3'd4;
        else emergency_road_reg = 3'd0;
        
        // Violation Output Logic
        if (violation_force) begin
            violation_warning_reg = VIOLATION;
        end else begin
            violation_warning_reg = NORMAL;
        end
    end

    // --- 1. State and Timer Update Logic (Synchronous) ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S0_R1_G; 
            timer_count <= 0;
        end else begin
            current_state <= next_state;

            if (current_state == next_state) begin
                timer_count <= timer_count + 1;
            end else begin
                timer_count <= 0;
            end
        end
    end

    // --- 2. Next State Logic (Combinational FSM Transition) ---
    always @(*) begin
        next_state = current_state; 

        // --- A. AMBULANCE PRIORITY (IMMEDIATE JUMP) ---
        if (emergency_road_reg != 3'd0) begin
            case (emergency_road_reg)
                3'd1: next_state = S_EMERGENCY_R1;
                3'd2: next_state = S_EMERGENCY_R2;
                3'd3: next_state = S_EMERGENCY_R3;
                3'd4: next_state = S_EMERGENCY_R4;
            endcase
        end 
        
        // --- B. NIGHT MODE PRIORITY (OVERRIDE) ---
        else if (night_mode) begin
            if (current_state != S_FLASH_RY_R && current_state != S_FLASH_OFF) begin
                next_state = S_FLASH_RY_R;
            end 
            else begin
                if (current_state == S_FLASH_RY_R && timer_count >= T_FLASH) next_state = S_FLASH_OFF;
                if (current_state == S_FLASH_OFF && timer_count >= T_FLASH) next_state = S_FLASH_RY_R;
            end
        end

        // --- C. NORMAL CYCLE / RETURN FROM EMERGENCY/NIGHT ---
        else begin 
            // Transition out of Emergency/Night Mode (when A1/night_mode go LOW)
            if (current_state >= S_EMERGENCY_R1 && current_state <= S_EMERGENCY_R4) begin
                next_state = S0_R1_G; 
            end
            if (current_state == S_FLASH_RY_R || current_state == S_FLASH_OFF) begin
                next_state = S0_R1_G; 
            end
            
            // Normal Transitions
            else begin
                case (current_state)
                    S0_R1_G: if (timer_count >= T_GREEN) next_state = S1_R1_Y;
                    S1_R1_Y: if (timer_count >= T_YELLOW) next_state = S2_R2_G;
                    
                    S2_R2_G: if (timer_count >= T_GREEN) next_state = S3_R2_Y;
                    S3_R2_Y: if (timer_count >= T_YELLOW) next_state = S4_R3_G;
                    
                    S4_R3_G: if (timer_count >= T_GREEN) next_state = S5_R3_Y;
                    S5_R3_Y: if (timer_count >= T_YELLOW) next_state = S6_R4_G;
                    
                    S6_R4_G: if (timer_count >= T_GREEN) next_state = S7_R4_Y;
                    S7_R4_Y: if (timer_count >= T_YELLOW) next_state = S0_R1_G; 

                    default: next_state = S0_R1_G;
                endcase
            end
        end
    end

    // --- 3. Output Logic (Light Control - Combinational) ---
    always @(*) begin
        // Default: All lights are RED ("R")
        R1_light_reg = R; R2_light_reg = R;
        R3_light_reg = R; R4_light_reg = R;

        // --- Output Override based on Current State ---
        case (current_state)
            // Emergency Priority 
            S_EMERGENCY_R1: R1_light_reg = G;
            S_EMERGENCY_R2: R2_light_reg = G;
            S_EMERGENCY_R3: R3_light_reg = G;
            S_EMERGENCY_R4: R4_light_reg = G;

            // Night Mode Flashing
            S_FLASH_RY_R: begin
                R1_light_reg = Y; R3_light_reg = Y; 
                R2_light_reg = Y; R4_light_reg = Y; 
            end
            S_FLASH_OFF: begin
                R1_light_reg = 24'h0; R2_light_reg = 24'h0; 
                R3_light_reg = 24'h0; R4_light_reg = 24'h0;
            end 
            
            // Normal Vehicle Sequence
            S0_R1_G: R1_light_reg = G;
            S1_R1_Y: R1_light_reg = Y;
            S2_R2_G: R2_light_reg = G;
            S3_R2_Y: R2_light_reg = Y;
            S4_R3_G: R3_light_reg = G;
            S5_R3_Y: R3_light_reg = Y;
            S6_R4_G: R4_light_reg = G;
            S7_R4_Y: R4_light_reg = Y;
        endcase
    end

endmodule