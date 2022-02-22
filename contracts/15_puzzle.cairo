%builtins output range_check

# https://starknet.io/docs/hello_cairo/puzzle.html

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.alloc import alloc

struct Location:
    member row : felt
    member col : felt
end

func verify_valid_location(loc : Location*):
    # The scope of a temporary variable is restricted. For example, a temporary variable may be revoked due to jumps (e.g., if statements) or function calls.
    tempvar row = loc.row
    # Check that the row in the the range 0-3
    assert row * (row - 1) * (row - 2) * (row - 3) = 0

    tempvar col = loc.col
    # Check that the col in the the range 0-3
    assert col * (col - 1) * (col - 2) * (col - 3) = 0

    return ()
end

func verify_adjacent_locations(loc0 : Location*, loc1 : Location*):
    # It allocates the memory required for the local variables of the function. Usually, this should be the first statement in a function which uses local variables. If you try to use local variables without that line, the compilation will fail.
    alloc_locals
    # This function uses local variables. These are similar to temporary variables, except that the scope in which they can be accessed is much less restricted – you can access them starting from their definition up to the end of the function.
    local row_diff = loc0.row - loc1.row
    local col_diff = loc0.col - loc1.col

    # A reference is defined using a let statement. The instruction by itself will not cause any computation to be performed.
    # The scope in which a reference is defined is derived from the scope in which the aliased expression is defined.
    # let x = y * y * y

    if row_diff == 0:
        # The row coordinate is the same. Make sure the difference
        # in col is 1 or -1.
        assert (col_diff - 1) * (col_diff + 1) = 0
        return ()
    else:
        # Verify the difference in row is 1 or -1
        assert (row_diff - 1) * (row_diff + 1) = 0
        # Verify that the col coordinate it the same
        assert col_diff = 0
        return ()
    end
end

func verify_location_list(loc_list : Location*, n_steps):
    # Always verify that the location is valid, even if
    # n_steps = 0 (remember that there is always one more
    # location than steps).
    verify_valid_location(loc=loc_list)

    if n_steps == 0:
        assert loc_list.row = 3
        assert loc_list.col = 3
        return ()
    end

    verify_adjacent_locations(loc_list, loc_list + Location.SIZE)

    # Recurse
    verify_location_list(loc_list + Location.SIZE, n_steps - 1)

    return ()
end

func build_dict(loc_list : Location*, tile_list : felt*, n_steps, dict : DictAccess*) -> (
        dict : DictAccess*):
    if n_steps == 0:
        # When there are no more steps, just return the dict
        # pointer.
        return (dict=dict)
    end

    # Set the key to the current tile being moved.
    assert dict.key = [tile_list]

    # Its previous location should be where the empty tile is
    # going to be.
    let next_loc : Location* = loc_list + Location.SIZE
    assert dict.prev_value = 4 * next_loc.row + next_loc.col

    # Its next location should be where the empty tile is
    # now.
    assert dict.new_value = 4 * loc_list.row + loc_list.col

    # Call build_dict recursively.
    return build_dict(next_loc, tile_list + 1, n_steps - 1, dict + DictAccess.SIZE)
end

func verify_is_final_state(dict : DictAccess*, idx) -> (dict : DictAccess*):
    if idx == 0:
        return (dict=dict)
    end

    assert dict.key = idx
    assert dict.prev_value = idx - 1
    assert dict.new_value = idx - 1

    # Recurse
    return verify_is_final_state(dict + DictAccess.SIZE, idx - 1)
end

func output_initial_values{output_ptr : felt*}(squashed_dict : DictAccess*, n):
    if n == 0:
        return ()
    end

    serialize_word(squashed_dict.prev_value)

    # Recurse
    return output_initial_values(squashed_dict + DictAccess.SIZE, n - 1)
end

func check_solution{output_ptr : felt*, range_check_ptr}(
        loc_list : Location*, tile_list : felt*, n_steps):
    alloc_locals

    # Start by verifying that loc_list is valid.
    verify_location_list(loc_list, n_steps)

    # Allocate memory for the dict and the squashed dict.
    let (local dict_start : DictAccess*) = alloc()
    let (local squashed_dict : DictAccess*) = alloc()

    let (dict_end) = build_dict(loc_list, tile_list, n_steps, dict_start)

    let (dict_end) = verify_is_final_state(dict_end, 15)

    let (squashed_dict_end : DictAccess*) = squash_dict(dict_start, dict_end, squashed_dict)

    # Store range_check_ptr in a local variable to make it
    # accessible after the call to output_initial_values().
    local range_check_ptr = range_check_ptr

    # Verify that the squashed dict has exactly 15 entries.
    # This will guarantee that all the values in the tile list
    # are in the range 1-15.
    assert squashed_dict_end - squashed_dict = 15 * DictAccess.SIZE

    output_initial_values(squashed_dict, 15)

    # Output the initial location of the empty tile.
    serialize_word(4 * loc_list.row + loc_list.col)

    # Output the number of steps.
    serialize_word(n_steps)

    return ()
end

func main{output_ptr : felt*, range_check_ptr}():
    alloc_locals

    local loc_tuple : (Location, Location, Location, Location, Location) = (
        Location(0, 2),
        Location(1, 2),
        Location(1, 3),
        Location(2, 3),
        Location(3, 3)
        )

    local tiles : (felt, felt, felt, felt) = (3, 7, 8, 12)

    # Get the value of the frame pointer register (fp) so that
    # we can use the address of loc_tuple.
    let (__fp__, _) = get_fp_and_pc()
    # Since the tuple elements are next to each other we can use the
    # address of loc_tuple as a pointer to the 5 locations.
    # verify_location_list(loc_list=cast(&loc_tuple, Location*), n_steps=4)

    check_solution(cast(&loc_tuple, Location*), cast(&tiles, felt*), 4)

    return ()
end
