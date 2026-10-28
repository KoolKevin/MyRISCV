`timescale 1ns/1ps

module RegisterFile(
    input clk,
    input reset,
    // 32 registri
    input [4:0] addressSourceReg1, addressSourceReg2, addressDestReg,
    input writeEnable,
    input [31:0] destRegData,
    output reg [31:0] sourceReg1Data, sourceReg2Data
);

    reg [31:0] registers[31:0];
    integer i;

    // in una cpu pipelined le scritture al RF (stadio di WB) avvengono nel 
    // primo semiperiodo mentre le letture (stadio di ID) nel secondo
    //
    // più nello specifico, si ha che:
    // - all'inizio del ciclo il pipeline register MEM/WB effettua il latch dei
    //   segnali rendendoli disponibili alla logica di WB
    // - a metà del ciclo (negedge) il RF campiona i segnali prodotti in WB 
    //   effettuando la scrittura del registro in considerazione
    // - di conseguenza, solamente nella seconda metà del ciclo le letture 
    //  (combinatorie) al RF restituiscono il valore aggiornato del registro
    //
    // btw: nello schematico sul libro l'aggiornamento del RF al negedge viene
    // indicato con la bolla che rappresenta la negazione sulla porta del RF
    // associata al segnale di clk
    always @(negedge clk, posedge reset) begin
        if (reset)
            for (i = 0; i < 32; i = i+1)
                registers[i] <= i[31:0]; // imposto ogni registro al proprio indice
        else if (writeEnable)
            registers[addressDestReg] <= destRegData;
    end

    assign sourceReg1Data = (addressSourceReg1 == 0) ? 32'd0 : registers[addressSourceReg1];
    assign sourceReg2Data = (addressSourceReg2 == 0) ? 32'd0 : registers[addressSourceReg2];

endmodule

