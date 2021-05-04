# In this file there are defined macros for often repeated actions

# Macros are extremely useful for substituting repeated code blocks with a
# single label for better readability
# These are in no means substitutes for functions
# These must be declared before it is used

# ============================================================================
#	%string - label pointing to message to print 

    .macro print(%string)
      la $a0, %string
      li $v0, 4
      syscall
    .end_macro


# ============================================================================

#	$v0 contains integer read

    .macro read_int()
      li $v0, 5
      syscall
    .end_macro


# ============================================================================
#	%buffer - address of input buffer
# 	%length assumed: 10 bytes

#	%buffer contains string read

    .macro read_string(%buffer)
      la $a0, %buffer
      li $a1, 10
      li $v0, 8
      syscall
    .end_macro
# ============================================================================
