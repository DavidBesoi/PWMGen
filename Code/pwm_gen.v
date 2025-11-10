module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input[15:0] period,
    input[7:0] functions,
    input[15:0] compare1,
    input[15:0] compare2,
    input[15:0] count_val,
    // top facing signals
    output pwm_out
);
    reg pwm_out_reg;
    assign pwm_out = pwm_out_reg;

    reg pwm_out_next;

    wire mode_nealiniat = functions[1]; // 0=Aliniat, 1=Nealiniat
    wire mode_dreapta   = functions[0]; // 0=Stanga, 1=Dreapta

    // Logica de comparare
    always @(*) begin
        // Valoarea default este 0 (inactiv)
        pwm_out_next = 1'b0;

        if (pwm_en) begin
            if (mode_nealiniat) begin
                //Intre compare1 si compare2
                if ((count_val >= compare1) && (count_val < compare2)) begin
                    pwm_out_next = 1'b1;
                end
            end else begin
                if (mode_dreapta) begin
                    // Dreapta:de la compare1 la final
                    if (count_val >= compare1) begin
                        pwm_out_next = 1'b1;
                    end
                end else begin
                    // Stanga: de la 0 pana la compare1
                    if (count_val < compare1) begin
                        pwm_out_next = 1'b1;
                    end
                end
            end
        end
        // Daca pwm_en este 0, ramane valoarea default (1'b0)
    end

    // Inregistram iesirea pe frontul de ceas
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out_reg <= 1'b0;
        end else begin
            pwm_out_reg <= pwm_out_next;
        end
    end
    
endmodule