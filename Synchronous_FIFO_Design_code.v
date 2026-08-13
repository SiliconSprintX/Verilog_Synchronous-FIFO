module fifo_sync
#(
    parameter FIFO_DEPTH = 8,
    parameter DATA_WIDTH = 32
)

(
    input clk,
    input rst_n,
    input cs,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output empty,
    output full
);

localparam FIFO_DEPTH_LOG = $clog2(FIFO_DEPTH);

// FIFO memory
reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];

// Write and read pointers
// Extra MSB is used for full detection
reg [FIFO_DEPTH_LOG:0] write_pointer;
reg [FIFO_DEPTH_LOG:0] read_pointer;


//--------------------------------------------------
// WRITE OPERATION
//--------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        write_pointer <= 0;
    end
    else if (cs && wr_en && !full)
    begin
        fifo[write_pointer[FIFO_DEPTH_LOG-1:0]] <= data_in;
        write_pointer <= write_pointer + 1'b1;
    end
end


//--------------------------------------------------
// READ OPERATION
//--------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        read_pointer <= 0;
        data_out <= 0;
    end
    else if (cs && rd_en && !empty)
    begin
        data_out <= fifo[read_pointer[FIFO_DEPTH_LOG-1:0]];
        read_pointer <= read_pointer + 1'b1;
    end
end


//--------------------------------------------------
// EMPTY CONDITION
//--------------------------------------------------

assign empty = (read_pointer == write_pointer);


//--------------------------------------------------
// FULL CONDITION
//--------------------------------------------------

assign full = (read_pointer ==
              {~write_pointer[FIFO_DEPTH_LOG],
               write_pointer[FIFO_DEPTH_LOG-1:0]});

endmodule
