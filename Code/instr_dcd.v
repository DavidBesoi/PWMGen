module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,
    input[7:0] data_in,
    output[7:0] data_out,
    // register access signals
    output read,
    output write,
    output[5:0] addr,
    input[7:0] data_read,
    output[7:0] data_write
);
    //Starile FSM
    localparam S_IDLE  = 1'b0; // Asteptam octetul de instructiune (Setup)
    localparam S_SETUP = 1'b1; // Asteptam octetul de date (Data)

    //Reg interni
    reg state_reg;
    reg [7:0] instr_reg;
    reg [7:0] data_out_reg;

    // Redeclaram iesirile ca reg pentru a le folosi in 'always'
    reg read;
    reg write;
    reg [5:0] addr;
    reg [7:0] data_write;

    // data_out este valoarea ultimei citiri
    assign data_out = data_out_reg;

    //Logica FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset la toate starile
            state_reg    <= S_IDLE;
            instr_reg    <= 8'h00;
            data_out_reg <= 8'h00;
            read         <= 1'b0;
            write        <= 1'b0;
            addr         <= 6'h00;
            data_write   <= 8'h00;
        end else begin

            // Pulsurile de read/write sunt active doar un ciclu
            read  <= 1'b0;
            write <= 1'b0;

            case (state_reg)
                //Idle: Asteptam instructiunea
                S_IDLE: begin
                    if (byte_sync) begin
                        instr_reg <= data_in; // Salvam octetul de instructiune
                        state_reg <= S_SETUP; // Trecem la starea de asteptare date
                    end
                end

                //Setup: Asteptam octetul de date
                S_SETUP: begin
                    if (byte_sync) begin
                        addr <= instr_reg[5:0];
                        if (instr_reg[7]) begin
                            write      <= 1'b1;
                            data_write <= data_in; // Trimitem octetul de date catre regs
                        end else begin
                            read <= 1'b1;
                        end
                        state_reg <= S_IDLE; // Ne intoarcem la starea de idle
                    end
                end
                
                default: begin
                    state_reg <= S_IDLE;
                end
            endcase

            if (read) begin
                data_out_reg <= data_read;
            end
        end
    end
endmodule