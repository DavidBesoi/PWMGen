module regs (
    // peripheral clock signals
    input clk,
    input rst_n,
    // decoder facing signals
    input read,
    input write,
    input[5:0] addr,
    output[7:0] data_read,
    input[7:0] data_write,
    // counter programming signals
    input[15:0] counter_val,
    output[15:0] period,
    output en,
    output count_reset,
    output upnotdown,
    output[7:0] prescale,
    // PWM signal programming values
    output pwm_en,
    output[7:0] functions,
    output[15:0] compare1,
    output[15:0] compare2
);

    //Redefim in reg ca sa putem sa le folosim in always block
    reg [15:0] period;
    reg en;
    reg count_reset;
    reg upnotdown;
    reg [7:0] prescale;
    reg pwm_en;
    reg [7:0] functions;
    reg [15:0] compare1;
    reg [15:0] compare2;

    // Reg intern pentru logica de citire
    reg [7:0] data_read_reg;

    // Conectam registrul intern la iesirea modulului
    assign data_read = data_read_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period <= 16'h0000;
            en <= 1'b0;
            compare1 <= 16'h0000;
            compare2 <= 16'h0000;
            count_reset <= 1'b0;
            prescale <= 8'h00;
            upnotdown <= 1'b0; // 1 = incrementare, 0 = decrementare
            pwm_en <= 1'b0;
            functions <= 8'h00;
        end else begin
            // Auto-clear (se goleste dupa al doilea ciclu)
            if (count_reset) begin
                count_reset <= 1'b0;
            end

            if (write) begin
                case (addr)
                      6'h00: period[7:0] <= data_write; // PERIOD LSB
                    6'h01: period[15:8] <= data_write; // PERIOD MSB
                    6'h02: en <= data_write[0]; // COUNTER_EN
                    6'h03: compare1[7:0] <= data_write; // COMPARE1 LSB
                    6'h04: compare1[15:8] <= data_write; // COMPARE1 MSB
                    6'h05: compare2[7:0] <= data_write; // COMPARE2 LSB
                    6'h06: compare2[15:8] <= data_write; // COMPARE2 MSB
                    6'h07: count_reset <= data_write[0]; // COUNTER_RESET
                    // 0x08, 0x09 sunt COUNTER_VAL (Read Only)
                    6'h0A: prescale <= data_write; // PRESCALE
                    6'h0B: upnotdown <= data_write[0]; // UPNOTDOWN
                    6'h0C: pwm_en <= data_write[0]; // PWM_EN
                    6'h0D: functions <= data_write; // FUNCTIONS 
                    default: ;
                endcase
            end
        end
    end

    // Logica combinationala pentru citire
    always @(*) begin
        data_read_reg = 8'h00; // Valoarea default la read ar trebui sa fie 0
        if (read) begin
            case (addr)
                6'h00: data_read_reg = period[7:0];
                6'h01: data_read_reg = period[15:8];
                6'h02: data_read_reg = {7'b0, en};
                6'h03: data_read_reg = compare1[7:0];
                6'h04: data_read_reg = compare1[15:8];
                6'h05: data_read_reg = compare2[7:0];
                6'h06: data_read_reg = compare2[15:8];
                6'h07: data_read_reg = 8'h00; // E WRITE-ONLY deci returneaza 0
                6'h08: data_read_reg = counter_val[7:0];   // COUNTER_VAL LSB
                6'h09: data_read_reg = counter_val[15:8];  // COUNTER_VAL MSB
                6'h0A: data_read_reg = prescale;
                6'h0B: data_read_reg = {7'b0, upnotdown};
                6'h0C: data_read_reg = {7'b0, pwm_en};
                6'h0D: data_read_reg = functions;
                default: data_read_reg = 8'h00;
            endcase
        end
    end
endmodule