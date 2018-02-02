
require 'flor/pcore/iterator'


class Flor::Pro::ForEach < Flor::Pro::Iterator
  #
  # Calls a function for each element in the argument collection.
  #
  # When the "for-each" ends, `f.ret` is pointing back to the argument
  # collection.
  #
  # ```
  # set l []
  # for-each [ 0 1 2 3 4 5 6 7 ]
  #   def x
  #     pushr l (2 * x) if x % 2 == 0
  # ```
  # the var `l` will yield `[ 0, 4, 8, 12 ]` after the `for-each`
  # the field `ret` will yield `[ 0, 1, 2, 3, 4, 5, 6, 7 ]`.
  #
  # ```
  # set r []
  # for-each { a: 'A', b: 'B', c: 'C' }
  #   def k v i l  # key, val, idx, len
  #     pushr r (+ k v (+ i 1) '/' l)
  # ```
  # the var `r` will yield `[ 'aA1/3', 'bB2/3', 'cC3/3' ]` after the `for-each`
  # the field `ret` will yield `{ 'a': 'A', 'b': 'B', 'c': 'C' }`.
  #
  # ## see also
  #
  # each.

  name 'for-each'

  protected

  def pre_iterator

    # nothing to do
  end

  def receive_iteration

    # nothing to do
  end

  def iterator_result

    @node['ocol']
      # back to the original collection
  end
end

