#------------------------------------------------------------------------------
# Jason Wilden 2025
#------------------------------------------------------------------------------
# PicoRV32 startup code, this must be loaded at adress 0x00000000 with the
# firmware binary following it.  See linker.lds for sections and layout.
# This project does not use any interrupts. 
#------------------------------------------------------------------------------
.section .text.start
.global _start
.type _start, @function

_start:    
    lui sp, %hi(__stack_top)                # Load immediate hibyte stack pointer (from linker.lds)
    addi sp, sp, %lo(__stack_top)           # Add immediate lobyte

                                            # Clear uninitialised data (bss)
    la t0, __bss_start                      # t0 - start word pointer (linker.lds)
    la t1, __bss_end                        # t1 - end pointer (linker.lds)
bss_clear:                                  
    beq t0, t1, bss_done                    # All done? 
    sw zero, 0(t0)                          # set word to zero
    addi t0, t0, 4                          # increment word pointer
    j bss_clear                             # loop to next word
bss_done:                                   # done

    call main                               # Call the C entry point, this should not return.
    
loop_forever:                               # We shouldn't get here, but loop forever if we do.
    j loop_forever

.size _start, .-_start
