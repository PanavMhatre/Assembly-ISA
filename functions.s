/**************************************************************************
 * C S 429 Assembly Coding Lab
 *
 * functions.s - Template for all functions to be implemented.
 *
 * Copyright (c) 2022, 2023, 2024, 2025, 2026
 * Authors: Kavya Rathod, Prithvi Jamadagni, Anoop Rachakonda, Zeeshan Ahmad, Hugo Mireles
 * All rights reserved.
 * May not be used, modified, or copied without permission.
 **************************************************************************/

 /*
 ** Panav Mhatre pym245**
 */
    
    .arch armv8-a
	.file	"functions.c"
	.text


// Every function starts from the .align below this line ...
    .align  2
    .p2align 3,,7
    .global lru
    .type   lru, %function
lru:
    // Input parameter access is passed in X0
    // Input parameter cache_matrix is passed in X1
    // Output value is returned in X0
    LDUR X2, [X1, #0]


    // the mask logic for col
    MOVZ X3, #0x0101
    MOVK X3, #0x0101, LSL #16
    MOVK X3, #0x0101, LSL #32
    MOVK X3, #0x0101, LSL #48
    LSL X3, X3, X0                  
    ORR X2, X2, X3

    //row zero out logic
    LSL X4, X0, #3 //2 ^ 3
    MOVZ X5, #0xFF
    LSL X5, X5, X4
    MVN X5, X5
    ANDS X2, X2, X5
    STUR X2, [X1, #0]

    //get the lru
    // We shift and OR it in half 3 times.
    LSR X3, X2, #32
    ORR X2, X2, X3
    LSR X3, X2, #16
    ORR X2, X2, X3
    LSR X3, X2, #8
    ORR X2, X2, X3

    // 2. Isolate the zero
    // Flip the bits so our target 0 becomes a 1, then mask off the garbage bits
    MVN X2, X2              
    MOVZ X4, #0xFF          
    ANDS X2, X2, X4     

    SUB X3, XZR, X2
    ANDS X2, X2, X3    
    
    // 3. Turn the isolated bit into a string of 1s (e.g., 00001000 becomes 00000111)
    SUB X2, X2, #1          

    // 4. Count the 1s (Branchless Popcount algorithm) recursive doublinh
    LSR X3, X2, #1
    MOVZ X4, #0x55
    ANDS X3, X3, X4
    SUB X2, X2, X3

    LSR X3, X2, #2
    MOVZ X4, #0x33
    ANDS X2, X2, X4
    ANDS X3, X3, X4
    ADD X2, X2, X3

    LSR X3, X2, #4
    ADD X2, X2, X3
    MOVZ X4, #0x0F

    // 5. STORE THE FINAL COUNT DIRECTLY INTO X0!
    ANDS X0, X2, X4

    ret
    .size   lru, .-lru
    // ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
	.align	2
	.global	UTF8_to_unicode
	.type	UTF8_to_unicode, %function

UTF8_to_unicode:
    // Input parameter utf8 is passed in X0
    // Output value is returned in X0

    // --- STEP 1: LOAD AND CHOP THE BYTES ---
    // X0 holds the pointer. Load 64 bits starting at that address.
    LDUR X1, [X0, #0]       

    // Create a 0xFF mask to isolate individual bytes
    MOVZ X2, #0xFF          

    // Byte 0 (Bottom 8 bits)
    ANDS X10, X1, X2        

    // Byte 1 (Shift right 8 bits, then mask)
    LSR X11, X1, #8
    ANDS X11, X11, X2       

    // Byte 2 (Shift right 16 bits, then mask)
    LSR X12, X1, #16
    ANDS X12, X12, X2       

    // Byte 3 (Shift right 24 bits, then mask)
    LSR X13, X1, #24
    ANDS X13, X13, X2       

    // Create a 0x3F mask for continuation bytes (used heavily later)
    MOVZ X9, #0x3F          


    // --- STEP 2: CHECK CHARACTER LENGTH ---
    
    // Check if 1-byte (Top bit is 0)
    MOVZ X3, #0x80
    ANDS XZR, X10, X3       // AND with 0x80. If result is 0, the zero flag is set.
    B.EQ .L_one             // Branch to 1-byte logic if equal to 0

    // Check if 2-byte (Starts with 110)
    MOVZ X3, #0xE0
    ANDS X4, X10, X3        // Mask the top 3 bits
    MOVZ X5, #0xC0
    CMP X4, X5              // Check if they equal 110... (0xC0)
    B.EQ .L_two

    // Check if 3-byte (Starts with 1110)
    MOVZ X3, #0xF0
    ANDS X4, X10, X3        // Mask the top 4 bits
    MOVZ X5, #0xE0
    CMP X4, X5              // Check if they equal 1110... (0xE0)
    B.EQ .L_three


    // --- STEP 3: MASK, SHIFT, AND COMBINE ---

    // If it didn't branch above, it MUST be a 4-byte character!
.L_four:
    MOVZ X3, #0x07          // 4-byte header mask
    ANDS X4, X10, X3        
    LSL X4, X4, #18         // Shift Byte 0 left by 18
    
    ANDS X5, X11, X9        
    LSL X5, X5, #12         // Shift Byte 1 left by 12
    
    ANDS X6, X12, X9        
    LSL X6, X6, #6          // Shift Byte 2 left by 6
    
    ANDS X7, X13, X9        // Byte 3 stays in place
    
    // Smash them together into X0!
    ORR X0, X4, X5          
    ORR X0, X0, X6
    ORR X0, X0, X7
    RET                     

.L_three:
    MOVZ X3, #0x0F          // 3-byte header mask
    ANDS X4, X10, X3        
    LSL X4, X4, #12         // Shift Byte 0 left by 12
    
    ANDS X5, X11, X9        
    LSL X5, X5, #6          // Shift Byte 1 left by 6
    
    ANDS X6, X12, X9        // Byte 2 stays in place
    
    // Smash them together into X0!
    ORR X0, X4, X5          
    ORR X0, X0, X6
    RET                     

.L_two:
    MOVZ X3, #0x1F          // 2-byte header mask
    ANDS X4, X10, X3        
    LSL X4, X4, #6          // Shift Byte 0 left by 6
    
    ANDS X5, X11, X9        // Byte 1 stays in place
    
    // Smash them together into X0!
    ORR X0, X4, X5          
    RET                     

.L_one:
    ORR X0, XZR, X10        // 1-byte: Just copy Byte 0 into X0!
    RET
	.size	UTF8_to_unicode, .-UTF8_to_unicode
	// ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
	.align	2
	.global	unicode_to_UTF8
	.type	unicode_to_UTF8, %function
unicode_to_UTF8:
    // (STUDENT TODO) Code for unicode_to_UTF8 goes here.
    // Input parameter a is passed in X0; input parameter utf8 is passed in X2
    // There are no output values

    ret
	.size	unicode_to_UTF8, .-unicode_to_UTF8
	// ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
    .align  2
    .p2align 3,,7
    .global compare
    .type   compare, %function
compare:
    // (STUDENT TODO) Code for compare goes here.
    // Input parameter a is passed in X0; input parameter b is passed in X1.
    // Output value is returned in X0.

    ret
    .size   compare, .-compare
    // ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
	.align	2
	.global	tree_depth
	.type	tree_depth, %function
tree_depth:
    // (STUDENT TODO) Code for tree_depth goes here.
    // Input parameter root is passed in X0.
    // Output value is returned in X0.

    ret
	.size	tree_depth, .-tree_depth
	// ... and ends with the .size above this line.

	// Every function starts from the .align below this line ...
	.align	2
	.global	insert_at_head
	.type	insert_at_head, %function
insert_at_head:
    // (STUDENT TODO) Code for insert_at_head goes here.
    // Input parameter head is passed in X0; input parameter data is passed in X1; input parameter tail is passed in X2
    // There is no output value. Parameter head will be mutated, and possibly tail

ret

	.size	insert_at_head, .-insert_at_head
	// ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
    .align  2
    .p2align 3,,7
    .global del_at_head
    .type   del_at_head, %function
del_at_head:
    // (STUDENT TODO) Code for del_at_head goes here.
    // Input parameter head is passed in X0; Input parameter tail is passed in X1
    // There is no output value. Parameter head and tail will be possibly mutated

    ret
    .size   del_at_head, .-del_at_head
    // ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
    .align  2
    .p2align 3,,7
    .global sum_up
    .type   sum_up, %function
sum_up:
    // (STUDENT TODO) Code for sum_up goes here.
    // Input parameter starting_node is passed in X0
    // Output value is returned in X0.

    .size   sum_up, .-sum_up
    // ... and ends with the .size above this line.
    