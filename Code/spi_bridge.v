module spi_bridge (
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input mosi,
    output miso,
    // internal facing 
    output byte_sync,
    output[7:0] data_in,
    input[7:0] data_out
);
    //Reg interne
    reg [2:0] bit_count;      // Numarator de biti ca sa stim cand am primit un octet
    reg [7:0] data_in_reg;    // Registru de deplasare pentru MOSI 
    reg [7:0] data_out_latch; // Latch pentru datele de trimis
    reg miso_reg;           // Iesirea MISO 
    reg byte_sync_pulse;    // Puls de 1 ciclu clk

    // Sincronizare si detectia fronturilor
    // Am facut asta ca sa nu apara un race condition intre spi si decoder
    // Chiar daca sunt exact la fel sclk si clk am vrut sa fie si tot modulul pus pe clk
    reg sclk_d1, sclk_d2;
    reg cs_n_d1, cs_n_d2;
    reg mosi_d1;

    wire sclk_rising_edge  = (sclk_d1 == 1'b1) && (sclk_d2 == 1'b0);
    wire sclk_falling_edge = (sclk_d1 == 1'b0) && (sclk_d2 == 1'b1);
    wire cs_n_falling_edge = (cs_n_d1 == 1'b0) && (cs_n_d2 == 1'b1);
    wire cs_n_active        = (cs_n_d2 == 1'b0); // cs_n este activ

    //Legaturi iesiri
    assign data_in = data_in_reg;
    assign byte_sync = byte_sync_pulse;
    assign miso = (cs_n_active) ? miso_reg : 1'bz; //Iesirea seriala MISO

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 3'b000;
            data_in_reg <= 8'h00;
            data_out_latch <= 8'h00;
            miso_reg <= 1'b0;
            byte_sync_pulse <= 1'b0;
            sclk_d1 <= 1'b0; sclk_d2 <= 1'b0;
            cs_n_d1 <= 1'b1; cs_n_d2 <= 1'b1;
            mosi_d1 <= 1'b0;
        end else begin
            
            // Sincronizam intrarile SPI cu ceasul clk
            sclk_d1 <= sclk;
            sclk_d2 <= sclk_d1;
            cs_n_d1 <= cs_n;
            cs_n_d2 <= cs_n_d1;
            mosi_d1 <= mosi;

            // Resetam byte_sync
            byte_sync_pulse <= 1'b0;

            // Inceputul tranzactiei SPI
            if (cs_n_falling_edge) begin
                bit_count <= 3'b000;
                data_out_latch <= data_out;
                miso_reg <= data_out[7]; //Pregatim primul bit MISO
                data_in_reg <= 8'h00;
            end
            
            // Logica SPI cat timp cs_n este activ
            else if (cs_n_active) begin
                
                //CPHA=0: Punem MOSI pe frontul crescator sclk
                if (sclk_rising_edge) begin
                    data_in_reg <= {data_in_reg[6:0], mosi_d1}; //Primim bit
                    bit_count <= bit_count + 1;
                    
                    if (bit_count == 3'b111) begin
                        byte_sync_pulse <= 1'b1; //Generam byte_sync
                    end
                end
                
                //CPHA=0: Schimbam MISO pe frontul descrescator sclk
                if (sclk_falling_edge) begin
                     case(bit_count)
                        3'b001: miso_reg <= data_out_latch[6]; 
                        3'b010: miso_reg <= data_out_latch[5];
                        3'b011: miso_reg <= data_out_latch[4];
                        3'b100: miso_reg <= data_out_latch[3];
                        3'b101: miso_reg <= data_out_latch[2];
                        3'b110: miso_reg <= data_out_latch[1];
                        3'b111: miso_reg <= data_out_latch[0];
                        default: miso_reg <= 1'b0;
                     endcase
                end
            end
        end
    end   
endmodule
