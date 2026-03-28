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

    SUBS X3, XZR, X2
    ANDS X2, X2, X3    
    
    // 3. Turn the isolated bit into a string of 1s (e.g., 00001000 becomes 00000111)
    SUB X2, X2, #1          

    // 4. Count the 1s (Branchless Popcount algorithm) recursive doublinh
    LSR X3, X2, #1
    MOVZ X4, #0x55
    ANDS X3, X3, X4
    SUBS X2, X2, X3

    LSR X3, X2, #2
    MOVZ X4, #0x33
    ANDS X2, X2, X4
    ANDS X3, X3, X4
    ADDS X2, X2, X3

    LSR X3, X2, #4
    ADDS X2, X2, X3
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
    // Input parameter a is passed in X0; input parameter utf8 is passed in X2
    // There are no output values
    // --- STEP 1: SAFE MEMORY PREP ---
    // Load the original 8 bytes at the pointer (X1) to preserve the top 4 bytes
    LDUR X9, [X1, #0]
    LSR X9, X9, #32
    LSL X9, X9, #32         // X9 now has its bottom 32 bits completely zeroed out!

    // --- STEP 2: CHECK CHARACTER LENGTH ---
    // Check if Invalid (greater than 0x10FFFF)
    MOVZ X2, #0xFFFF
    MOVK X2, #0x0010, LSL #16
    CMP X0, X2
    B.HI .L_enc_invalid

    // Check if 4-byte (greater than 0xFFFF)
    MOVZ X2, #0xFFFF
    CMP X0, X2
    B.HI .L_enc_four

    // Check if 3-byte (greater than 0x07FF)
    MOVZ X2, #0x07FF
    CMP X0, X2
    B.HI .L_enc_three

    // Check if 2-byte (greater than 0x007F)
    MOVZ X2, #0x007F
    CMP X0, X2
    B.HI .L_enc_two


    // --- STEP 3: MASK, SHIFT, AND BUILD ---
    
.L_enc_one:
    // 1-byte: It's just normal ASCII.
    ORR X3, XZR, X0         
    B .L_enc_store

.L_enc_two:
    // 2-byte
    // Byte 0: top 5 bits -> (a >> 6) | 0xC0
    LSR X3, X0, #6
    MOVZ X4, #0xC0
    ORR X3, X3, X4
    
    // Byte 1: bottom 6 bits -> (a & 0x3F) | 0x80
    MOVZ X4, #0x3F
    ANDS X5, X0, X4
    MOVZ X6, #0x80
    ORR X5, X5, X6
    LSL X5, X5, #8          // Shift into Byte 1 position
    
    ORR X3, X3, X5          // Smash them together
    B .L_enc_store

.L_enc_three:
    // 3-byte
    // Byte 0: top 4 bits -> (a >> 12) | 0xE0
    LSR X3, X0, #12
    MOVZ X4, #0xE0
    ORR X3, X3, X4

    // Byte 1: middle 6 bits -> ((a >> 6) & 0x3F) | 0x80
    LSR X5, X0, #6
    MOVZ X4, #0x3F
    ANDS X5, X5, X4
    MOVZ X6, #0x80
    ORR X5, X5, X6
    LSL X5, X5, #8          // Shift into Byte 1 position
    ORR X3, X3, X5

    // Byte 2: bottom 6 bits -> (a & 0x3F) | 0x80
    ANDS X7, X0, X4
    ORR X7, X7, X6
    LSL X7, X7, #16         // Shift into Byte 2 position
    ORR X3, X3, X7
    B .L_enc_store

.L_enc_four:
    // 4-byte
    // Byte 0: top 3 bits -> (a >> 18) | 0xF0
    LSR X3, X0, #18
    MOVZ X4, #0xF0
    ORR X3, X3, X4

    // Byte 1: bits 12-17
    LSR X5, X0, #12
    MOVZ X4, #0x3F
    ANDS X5, X5, X4
    MOVZ X6, #0x80
    ORR X5, X5, X6
    LSL X5, X5, #8
    ORR X3, X3, X5

    // Byte 2: bits 6-11
    LSR X7, X0, #6
    ANDS X7, X7, X4
    ORR X7, X7, X6
    LSL X7, X7, #16
    ORR X3, X3, X7

    // Byte 3: bits 0-5
    ANDS X8, X0, X4
    ORR X8, X8, X6
    LSL X8, X8, #24
    ORR X3, X3, X8
    B .L_enc_store

.L_enc_invalid:
    // If it's too big for Unicode, the manual says fill all 4 bytes with 0xFF.
    MOVZ X3, #0xFFFF
    MOVK X3, #0xFFFF, LSL #16


    // --- STEP 4: STORE BACK TO MEMORY ---
.L_enc_store:
    ORR X9, X9, X3          // Drop our new 32-bit chunk into the safe 64-bit string
    STUR X9, [X1, #0]       // Save it back to memory
    RET

    ret
	.size	unicode_to_UTF8, .-unicode_to_UTF8
	// ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
    .align  2
    .p2align 3,,7
    .global compare
    .type   compare, %function
compare:
    // Input parameter a is passed in X0; input parameter b is passed in X1.
    // Output value is returned in X0.
    compare:
    // X0 = Pointer to Ticket A
    // X1 = Pointer to Ticket B

    // --- Field 1: unique_id (8 bytes, Offset 0) ---
    LDUR X2, [X0, #0]
    LDUR X3, [X1, #0]
    CMP X2, X3
    B.NE .L_compare_diff    // If IDs don't match, return 1

    // --- Field 2: seat_code (3 bytes, Offset 8) ---
    LDUR X2, [X0, #8]
    LDUR X3, [X1, #8]
    // Mask out the 5 bytes of garbage padding (Keep bottom 24 bits)
    MOVZ X4, #0xFFFF
    MOVK X4, #0x00FF, LSL #16
    ANDS X2, X2, X4
    ANDS X3, X3, X4
    CMP X2, X3
    B.NE .L_compare_diff

    // --- Field 3: price (8 bytes, Offset 16) ---
    LDUR X2, [X0, #16]
    LDUR X3, [X1, #16]
    CMP X2, X3
    B.NE .L_compare_diff

    // --- Field 4: special_admission (1 byte, Offset 24) ---
    LDUR X2, [X0, #24]
    LDUR X3, [X1, #24]
    // Mask out the 7 bytes of garbage (Keep bottom 8 bits)
    MOVZ X4, #0xFF
    ANDS X2, X2, X4
    ANDS X3, X3, X4
    CMP X2, X3
    B.NE .L_compare_diff

    // --- Field 5: recommendations pointer (8 bytes, Offset 32) ---
    LDUR X2, [X0, #32]
    LDUR X3, [X1, #32]
    CMP X2, X3
    B.NE .L_compare_diff

    // --- Field 6: refundable (1 byte, Offset 40) ---
    LDUR X2, [X0, #40]
    LDUR X3, [X1, #40]
    // Mask out the 7 bytes of garbage (Keep bottom 8 bits)
    MOVZ X4, #0xFF
    ANDS X2, X2, X4
    ANDS X3, X3, X4
    CMP X2, X3
    B.NE .L_compare_diff

    // --- SUCCESS: All fields matched! ---
    MOVZ X0, #0
    RET
    // --- FAILURE: Difference found ---
.L_compare_diff:
    MOVZ X0, #1
    RET
    .size   compare, .-compare
    // ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
	.align	2
	.global	tree_depth
	.type	tree_depth, %function
tree_depth:
    // Input parameter root is passed in X0.
    // Output value is returned in X0.

    // Base case: if root == NULL, return 0
    CMP  X0, XZR
    B.EQ .L_td_null

    // Prologue: allocate 32-byte frame, save LR + callee-saved regs
    SUB  SP,  SP, #32
    STUR X30, [SP, #0]      // save LR
    STUR X19, [SP, #8]      // save X19 (root)
    STUR X20, [SP, #16]     // save X20 (left_depth)

    ORR  X19, XZR, X0       // X19 = root (survives BL)

    // tree_depth(root->left)  — left ptr at offset 0
    LDUR X0, [X19, #0]
    BL   tree_depth
    ORR  X20, XZR, X0       // X20 = left_depth

    // tree_depth(root->right) — right ptr at offset 8
    LDUR X0, [X19, #8]
    BL   tree_depth         // X0  = right_depth

    // result = max(left_depth, right_depth) + 1
    CMP  X20, X0
    B.GT .L_td_left_wins

    // right_depth >= left_depth
    ADD  X0, X0, #1
    B    .L_td_epilogue

.L_td_left_wins:
    ADD  X0, X20, #1

.L_td_epilogue:
    LDUR X30, [SP, #0]
    LDUR X19, [SP, #8]
    LDUR X20, [SP, #16]
    ADD  SP,  SP, #32
    RET

.L_td_null:
    MOVZ X0, #0
    RET
	.size	tree_depth, .-tree_depth
	// ... and ends with the .size above this line.

	// Every function starts from the .align below this line ...
	.align	2
	.global	insert_at_head
	.type	insert_at_head, %function
insert_at_head:
    // Input parameter head is passed in X0
    // Input parameter data is passed in X1
    // Input parameter tail is passed in X2

    // Prologue: 48-byte frame (5 regs × 8 = 40, rounded to 48 for alignment)
    SUB  SP,  SP, #48
    STUR X30, [SP, #0]      // save LR
    STUR X19, [SP, #8]      // X19 = head  (linked_node_t**)
    STUR X20, [SP, #16]     // X20 = data
    STUR X21, [SP, #24]     // X21 = tail  (linked_node_t**)
    STUR X22, [SP, #32]     // X22 = old_head ptr

    ORR  X19, XZR, X0       // save head ptr-ptr
    ORR  X20, XZR, X1       // save data
    ORR  X21, XZR, X2       // save tail ptr-ptr

    // malloc(16) — sizeof(linked_node_t) = 16
    MOVZ X0, #16
    BL   malloc             // X0 = new_node

    // new_node->data = data
    STUR X20, [X0, #0]

    // old_head = *head
    LDUR X22, [X19, #0]     // X22 = old_head

    // new_node->npx = NULL ^ old_head = old_head
    STUR X22, [X0, #8]

    // if old_head != NULL: patch old_head->npx ^= new_node
    // (old_head's prev was NULL, so npx was NULL^next = next; now prev=new_node)
    CMP  X22, XZR
    B.EQ .L_iah_was_empty

    LDUR X3, [X22, #8]      // X3 = old_head->npx
    EOR  X3, X3, X0         // XOR in new_node address
    STUR X3, [X22, #8]
    B    .L_iah_set_head

.L_iah_was_empty:
    // list was empty → new node is also the tail
    STUR X0, [X21, #0]

.L_iah_set_head:
    // *head = new_node
    STUR X0, [X19, #0]

    // Epilogue
    LDUR X30, [SP, #0]
    LDUR X19, [SP, #8]
    LDUR X20, [SP, #16]
    LDUR X21, [SP, #24]
    LDUR X22, [SP, #32]
    ADD  SP,  SP, #48
    RET
	.size	insert_at_head, .-insert_at_head
	// ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
    .align  2
    .p2align 3,,7
    .global del_at_head
    .type   del_at_head, %function
del_at_head:
    // Input parameter head is passed in X0
    // Input parameter tail is passed in X1

    // Prologue: 32-byte frame
    SUB  SP,  SP, #32
    STUR X30, [SP, #0]      // save LR
    STUR X19, [SP, #8]      // X19 = head ptr-ptr
    STUR X20, [SP, #16]     // X20 = tail ptr-ptr
    STUR X21, [SP, #24]     // X21 = old_head

    ORR  X19, XZR, X0
    ORR  X20, XZR, X1

    // old_head = *head
    LDUR X21, [X19, #0]

    // if *head == NULL, nothing to do
    CMP  X21, XZR
    B.EQ .L_dah_done

    // next = old_head->npx ^ NULL = old_head->npx
    LDUR X2, [X21, #8]      // X2 = next

    CMP  X2, XZR
    B.EQ .L_dah_one_node

    // Patch next->npx: XOR out old_head (removes old_head from next's prev)
    LDUR X3, [X2, #8]
    EOR  X3, X3, X21
    STUR X3, [X2, #8]
    // *head = next
    STUR X2, [X19, #0]
    B    .L_dah_free

.L_dah_one_node:
    // List becomes empty
    STUR XZR, [X19, #0]
    STUR XZR, [X20, #0]

.L_dah_free:
    ORR  X0, XZR, X21       // free(old_head)
    BL   free

.L_dah_done:
    LDUR X30, [SP, #0]
    LDUR X19, [SP, #8]
    LDUR X20, [SP, #16]
    LDUR X21, [SP, #24]
    ADD  SP,  SP, #32
    RET
    .size   del_at_head, .-del_at_head
    // ... and ends with the .size above this line.

// Every function starts from the .align below this line ...
    .align  2
    .p2align 3,,7
    .global sum_up
    .type   sum_up, %function
sum_up:
    // Input parameter starting_node is passed in X0
    // Output value is returned in X0.

    // cur  = *starting_node
    LDUR X1, [X0, #0]       // X1 = cur
    MOVZ X2, #0             // X2 = prev = NULL
    MOVZ X0, #0             // X0 = sum  = 0

.L_su_loop:
    CMP  X1, XZR
    B.EQ .L_su_done

    LDUR X3, [X1, #0]       // X3 = cur->data
    ADD  X0, X0, X3         // sum += cur->data

    LDUR X4, [X1, #8]       // X4 = cur->npx
    EOR  X4, X4, X2         // next = cur->npx ^ prev

    ORR  X2, XZR, X1        // prev = cur
    ORR  X1, XZR, X4        // cur  = next
    B    .L_su_loop

.L_su_done:
    RET
    .size   sum_up, .-sum_up
    // ... and ends with the .size above this line.
