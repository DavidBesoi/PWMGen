module spi_bridge (
    input clk,
    input rst_n,
    input sclk,
    input cs_n,
    input mosi,
    output miso,
    output byte_sync,
    output[7:0] data_in,
    input[7:0] data_out
);
    reg [2:0] bit_cnt;
    reg [7:0] shift_in;
    reg [7:0] shift_out;
    reg byte_done_toggle;
    reg [7:0] shift_buffer; 

    always @(posedge sclk or posedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 3'b000;
            byte_done_toggle <= 1'b0;
            shift_in <= 8'h00;
            shift_buffer <= 8'h00;
        end else if (cs_n) begin
            bit_cnt <= 3'b000;
        end else begin
            shift_in <= {shift_in[6:0], mosi};
            bit_cnt <= bit_cnt + 1;
            
            if (bit_cnt == 3'b111) begin
                byte_done_toggle <= ~byte_done_toggle;
                shift_buffer <= {shift_in[6:0], mosi};
            end
        end
    end

    always @(negedge sclk or negedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            shift_out <= 8'h00;
        end else if (!cs_n) begin
            if (bit_cnt == 3'b000) begin
                shift_out <= data_out;
            end else begin
                shift_out <= {shift_out[6:0], 1'b0};
            end
        end
    end
    
    assign miso = (!cs_n) ? shift_out[7] : 1'bz;

    reg sync_1, sync_2, sync_3;
    reg byte_sync_pulse;
    reg [7:0] data_in_latched;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_1 <= 1'b0;
            sync_2 <= 1'b0;
            sync_3 <= 1'b0;
            byte_sync_pulse <= 1'b0;
            data_in_latched <= 8'h00;
        end else begin
            sync_1 <= byte_done_toggle;
            sync_2 <= sync_1;
            sync_3 <= sync_2; 

            if (sync_2 != sync_3) begin
                byte_sync_pulse <= 1'b1;
                data_in_latched <= shift_buffer; 
            end else begin
                byte_sync_pulse <= 1'b0;
            end
        end
    end

    assign byte_sync = byte_sync_pulse;
    assign data_in   = data_in_latched;

endmodule