This is an example with a basic architecture for RISCV 32 bit base integer Orthogonal ISA.

Load/store architecture; 32 general-purpose regiters; 

Thou, comprises of R-Type: add, sub, and, or; I-Type: addi, ori, lw, jalr; B-Type: beq, bne; J-Type: jal; S-Type: sw 

To calculate the execution time:

We have 16 instructions below, Assumptions: CPI = 1, T_c is the longest critical path; T_c=tpcq(program counter)+2tmemory+tRFread+talu+tmux+tRFsetup= 10+2*100+50+50+10+10=330ps

T(execution)=instructions * CPI(cycle/instruction) * Tc(sec/cycle)
=16*1*330= 5.28ns....

```
main: 

    addi x2, x0, 5          # Load immediate value 5 into register x2

    addi x3, x0, 12         # Load immediate value 12 into register x3

    addi x7, x3, -9         # Subtract 9 from x3 (12) and store the result (3) in x7

    or x4, x7, x2           # Perform bitwise OR between x7 (3) and x2 (5), result in x4 (7)

    and x5, x3, x4          # Perform bitwise AND between x3 (12) and x4 (7), result in x5 (4)

    add x5, x5, x4          # Add x5 (4) and x4 (7), store the result (11) in x5

    beq x5, x7, end         # Branch to 'end' if x5 (11) is equal to x7 (3) - not taken

    beq x4, x0, around      # Branch to 'around' if x4 (7) is equal to x0 (0) - not taken

    addi x5, x0, 0          # Set x5 to 0 (x5 = 0)

around: 
    add x7, x4, x5          # Add x4 (7) and x5 (0), store result (7) in x7

    sub x7, x7, x2          # Subtract x2 (5) from x7 (7), store result (2) in x7

    sw x7, 84(x3)           # Store the value in x7 (2) at the memory address (x3 + 84) = 96

    lw x2, 96(x0)           # Load word from memory address 96 into x2

    add x9, x2, x5          # Add x2 (value loaded from memory) and x5 (0), store result in x9

    jal x3, end             # Jump and link to 'end', save return address in x3

    addi x2, x0, 1          # Set x2 to 1 (x2 = 1)

end: 
    add x2, x2, x9          # Add x2 (1) and x9 (value from memory), store result in x2

    sw x2, 0x20(x3)         # Store the value of x2 at memory address (x3 + 32) = 44

done: 
    beq x2, x2, done        # Infinite loop - branch to 'done' if x2 is equal to x2 (always true)

```

The picture to understand the instructions path with data and instruction control
![image](https://github.com/user-attachments/assets/5a6718f0-b343-480a-ad96-feca7542e708)
