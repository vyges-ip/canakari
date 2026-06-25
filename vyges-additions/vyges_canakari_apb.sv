// Vyges integration facade for the canakari CAN 2.0B controller (can2).
//
// Bridges the SoC-standard peripheral surface — clk_i / rst_ni + APB4 slave +
// CAN rx/tx + IRQ — to can2's native Avalon-MM register port + active-low reset.
// Keeps the soc-generator wiring generic (no Avalon/CAN-specific handling at the
// boundary). The CAN controller's debug/status outputs are left unconnected.
//
// Avalon mapping (fixed-latency-0: readdata is combinational via
// multiplexeravalon2, so APB completes in the access phase, PREADY=1):
//   address  <- PADDR[6:2] (word index, 5-bit)        cs       <- PSEL
//   writedata<- PWDATA[15:0]                           read_n   <- !(access & !PWRITE)
//   PRDATA   <- {16'b0, readdata}                      write_n  <- !(access &  PWRITE)
// reset is active-low (resetgen2: if (reset==1'b0)) -> rst_ni connects directly.
//
// SPDX-License-Identifier: Apache-2.0

module vyges_canakari_apb (
  input  wire        clk_i,
  input  wire        rst_ni,
  // APB4 slave
  input  wire [31:0] PADDR,
  input  wire        PWRITE,
  input  wire [31:0] PWDATA,
  input  wire        PSEL,
  input  wire        PENABLE,
  output wire        PREADY,
  output wire [31:0] PRDATA,
  // CAN bus
  input  wire        rx,
  output wire        tx,
  // Interrupt
  output wire        IRQ
);

  wire        access = PSEL & PENABLE;
  wire [15:0] readdata;

  can2 u_can2 (
    .clock     (clk_i),
    .reset     (rst_ni),               // active-low, direct
    .address   (PADDR[6:2]),
    .writedata (PWDATA[15:0]),
    .readdata  (readdata),
    .cs        (PSEL),
    .read_n    (~(access & ~PWRITE)),
    .write_n   (~(access &  PWRITE)),
    .irq       (IRQ),
    .irqstatus (),
    .irqsuctra (),
    .irqsucrec (),
    .rx        (rx),
    .tx        (tx),
    .statedeb  (),
    .Prescale_EN_debug (),
    .bitst     ()
  );

  assign PRDATA = {16'b0, readdata};
  assign PREADY = 1'b1;                 // Avalon fixed-latency-0

endmodule
