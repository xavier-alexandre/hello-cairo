%builtins output

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word

# Computes the sum of the memory elements at addresses:
#   arr + 0, arr + 1, ..., arr + (size - 1).
func array_sum(arr : felt*, size) -> (sum):
    if size == 0:
        return (sum=0)
    end

    # size is not zero.
    let (sum_of_rest) = array_sum(arr=arr + 1, size=size - 1)
    return (sum=[arr] + sum_of_rest)
end

func main{output_ptr : felt*}():
    # serialize_word(6 / 3)
    # serialize_word(7 / 3)
    # serialize_word(1206167596222043737899107594365023368541035738443865566657697352045290673496 * 3)

    const ARRAY_SIZE = 3

    # Allocate an array
    let (ptr) = alloc()

    # Populate some values in the array.
    assert [ptr] = 9
    assert [ptr + 1] = 16
    assert [ptr + 2] = 25

    # Call array_sum to compute the sum
    let (sum) = array_sum(ptr, ARRAY_SIZE)

    # Write the result to program output
    serialize_word(sum)

    return ()
end
