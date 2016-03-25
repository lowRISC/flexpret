// See LICENSE for license details.

module NASTILiteUART
  #(
    NASTI_ID_WIDTH = 1,
    NASTI_ADDR_WIDTH = 8,
    NASTI_DATA_WIDTH = 8,
    NASTI_USER_WIDTH = 1,
    ClockFreq =	27000000,
	Baud = 115200,
	Parity = 0,
	StopBits = 1
    )
   (
    input clk, rstn,
    nasti_aw aw,
    nasti_w w,
    nasti_b b,
    nasti_ar ar,
    nasti_r r.
    input rxd,
    output txd
    );

   logic [NASTI_DATA_WIDTH-1:0] data_in, data_out;
   logic                        data_in_valid, data_in_ready, data_out_valid, data_out_ready;
   logic                        write_fire, read_fire;

   UART #(
          .ClockFreq ( ClockFreq        ),
          .Baud      ( Baud             ),
          .Width     ( NASTI_DATA_WIDTH ),
          .Parity    ( Parity           ),
          .StopBits  ( StopBits         )
          )
   (
    .Clock        ( clk            ),
    .Reset        ( !rstn          ),
    .DataIn       ( data_in        ),
    .DataInValid  ( data_in_valid  ),
    .DataInReady  ( data_in_ready  ),
    .DataOut      ( data_out       ),
    .DataOutValid ( data_out_valid ),
    .DataOutReady ( data_out_ready ),
    .SIn          ( rxd            ),
    .Sout         ( txd            )
    );
      
   assign write_fire = aw.valid && w.valid && data_in_ready && aw.addr[NASTI_ADDR_WIDTH-1:0] == 0;
   assign read_fire = ar.valid && data_out_valid && ar.addr[NASTI_ADDR_WIDTH-1:0] == 0;
   
   always_ff @(posedge clk) begin
      if(write_fire) b.id <= aw.id;
      if(read_fire)  r.id <= ar.id;
   end

   always_ff @(posedge clk iff rstn or negedge rstn)
     if(!rstn) begin
        b.valid <= 1'b0;
        r.valid <= 1'b0;
     end else begin
        if(write_fire) b.valid <= w.strb[0]; // in case strb is not enabled
        else if(b.ready) b.valid <= 1'b0;

        if(read_fire) begin
           r.valid <= 1'b1;
           r.data <= data_out;
        end else if(r.ready) r.valid <= 1'b0;
     end

   assign data_in = w.data;
   assign data_in_valid = write_fire;
   assign data_out_ready = read_fire;

   assign aw.ready = write_fire;
   assign w.ready = write_fire;
   assign b.resp = 0;
   assign b.user = 0;
   assign ar.ready = read_fire;
   assign r.resp = 0;
   assign r.user = 0;
   assign r.last = 1;
   
endmodule // AXILiteUART
