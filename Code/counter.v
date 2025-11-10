module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output[15:0] count_val,
    input[15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input[7:0] prescale
);
    reg [15:0] count_val_reg;
    assign count_val = count_val_reg;

    reg [7:0] prescale_cnt_reg;

    // Semnal de 1 ciclu 'clk' generat de prescaler
    wire prescale_tick;
    
    // Logica Prescaler-ului (Un tick la fiecare 'prescale + 1' cicluri de clk)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_cnt_reg <= 8'h00;
        end else if (count_reset) begin
            prescale_cnt_reg <= 8'h00; // Sincronizam resetarea prescaler-ului cu resetarea contorului
        end else if (en) begin
            if (prescale_cnt_reg == prescale) begin
                prescale_cnt_reg <= 8'h00;
            end else begin
                prescale_cnt_reg <= prescale_cnt_reg + 1;
            end
        end else begin
            prescale_cnt_reg <= prescale_cnt_reg; 
        end
    end
    
    // Generam pulsul cand contorul e egal cu prescale-ul
    assign prescale_tick = (prescale_cnt_reg == prescale) && en;

    // Logica Numaratorului Principal (16 biti)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_val_reg <= 16'h0000;
        end else if (count_reset) begin
            count_val_reg <= 16'h0000; // Reset sincron cerut de regs
        end else if (en && prescale_tick) begin
            
            if (upnotdown) begin
                //Cresc
                if (count_val_reg == period) begin
                    count_val_reg <= 16'h0000;
                end else begin
                    count_val_reg <= count_val_reg + 1;
                end
            end else begin
                //Descresc
                if (count_val_reg == 16'h0000) begin
                    count_val_reg <= period;
                end else begin
                    count_val_reg <= count_val_reg - 1;
                end
            end
        end
    end  

endmodule