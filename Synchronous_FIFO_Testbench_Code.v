`timescale 1ns/1ns

module tb_fifo_sync();

parameter FIFO_DEPTH = 8;
parameter DATA_WIDTH = 32;

// Testbench signals
reg clk = 0;
reg rst_n;
reg cs;
reg wr_en;
reg rd_en;
reg [DATA_WIDTH-1:0] data_in;

wire [DATA_WIDTH-1:0] data_out;
wire empty;
wire full;

integer i;


//--------------------------------------------------
// DUT INSTANTIATION
//--------------------------------------------------

fifo_sync
#(
    .FIFO_DEPTH(FIFO_DEPTH),
    .DATA_WIDTH(DATA_WIDTH)
)
dut
(
    .clk(clk),
    .rst_n(rst_n),
    .cs(cs),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .empty(empty),
    .full(full)
);


//--------------------------------------------------
// CLOCK GENERATION
//--------------------------------------------------

always #5 clk = ~clk;


//--------------------------------------------------
// WRITE TASK
//--------------------------------------------------

task write_data(input [DATA_WIDTH-1:0] d_in);
begin

    // Drive inputs away from positive edge
    @(negedge clk);

    cs      = 1;
    wr_en   = 1;
    rd_en   = 0;
    data_in = d_in;

    // DUT captures data at next positive edge
    @(posedge clk);

    if (full)
        $display("%0t : FIFO FULL - Write blocked, data = %0d",
                 $time, d_in);
    else
        $display("%0t : WRITE data_in = %0d",
                 $time, d_in);

    // Disable write
    @(negedge clk);

    wr_en = 0;
    cs    = 0;

end
endtask


//--------------------------------------------------
// READ TASK
//--------------------------------------------------

task read_data;
begin

    // Drive read control at negative edge
    @(negedge clk);

    cs    = 1;
    rd_en = 1;
    wr_en = 0;

    // DUT performs read at next positive edge
    @(posedge clk);

    // Wait for non-blocking assignment to update
    #1;

    if (empty)
        $display("%0t : FIFO EMPTY - Read blocked",
                 $time);
    else
        $display("%0t : READ data_out = %0d",
                 $time, data_out);

    // Disable read
    @(negedge clk);

    rd_en = 0;
    cs    = 0;

end
endtask


//--------------------------------------------------
// STIMULUS
//--------------------------------------------------

initial
begin

    // Initial values
    rst_n   = 0;
    cs      = 0;
    wr_en   = 0;
    rd_en   = 0;
    data_in = 0;

    // Keep reset active for a few clock cycles
    #12;

    rst_n = 1;

    //------------------------------------------------
    // SCENARIO 1
    //------------------------------------------------

    $display("\n==============================");
    $display("       SCENARIO 1");
    $display("==============================");

    write_data(1);
    write_data(10);
    write_data(100);

    read_data();
    read_data();
    read_data();


    //------------------------------------------------
    // SCENARIO 2
    //------------------------------------------------

    $display("\n==============================");
    $display("       SCENARIO 2");
    $display("==============================");

    for(i = 0; i < FIFO_DEPTH; i = i + 1)
    begin
        write_data(2**i);
        read_data();
    end


    //------------------------------------------------
    // SCENARIO 3
    //------------------------------------------------

    $display("\n==============================");
    $display("       SCENARIO 3");
    $display("==============================");

    // Fill FIFO completely
    for(i = 0; i < FIFO_DEPTH + 1; i = i + 1)
    begin
        write_data(2**i);
    end

    // Read all FIFO entries
    for(i = 0; i < FIFO_DEPTH; i = i + 1)
    begin
        read_data();
    end


    //------------------------------------------------
    // FINISH
    //------------------------------------------------

    #40;

    $finish;

end


//--------------------------------------------------
// WAVEFORM DUMP
//--------------------------------------------------

initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_fifo_sync);
end

endmodule
