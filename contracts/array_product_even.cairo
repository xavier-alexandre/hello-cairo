%builtins output

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word

# Product over even elements of the passed array.
# We may assume that the array has an even length
func array_product_even(arr : felt*, size) -> (sum):
    if size == 0:
        return (1)
    end

    let val = [arr]  # Derefence operator
    let (rest) = array_product_even(arr + 2, size - 2)
    return (val * rest)
end

func main{output_ptr : felt*}():
    const ARRAY_SIZE = 6

    # Allocate an array
    let (ptr) = alloc()

    # Populate some values in the array.
    assert [ptr] = 2
    assert [ptr + 1] = 9
    assert [ptr + 2] = 32
    assert [ptr + 3] = 7
    assert [ptr + 4] = 23
    assert [ptr + 5] = 5
    assert [ptr + 6] = 12

    # Call array_product_even to compute the product
    let (product) = array_product_even(ptr, ARRAY_SIZE)

    # Write the result to pogram output
    serialize_word(product)

    return ()
end
