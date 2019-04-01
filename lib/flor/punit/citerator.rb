
# Parent class for "c-for-each" and "c-map"
#
class Flor::Pro::ConcurrentIterator < Flor::Procedure

  def pre_execute

    @node['args'] = []
    @node['col'] = nil

    unatt_unkeyed_children
  end

  def receive_non_att

    if @node['col']
      receive_ret
    else
      @node['args'] << payload['ret']
      super
    end
  end

  def receive_last

    if @node['col']
      super
    else
      receive_last_argument
    end
  end

  def add

    col = @node['col']
    elts = message['elements']

    fail Flor::FlorError.new(
      "cannot add branches to #{heap}", self
    ) unless elts

    tcol = Flor.type(col)

    x =
      if tcol == :object
        elts.inject(nil) { |r, e|
          next r if r
          t = Flor.type(e)
          t != :object ? t : r }
      else
        nil
      end
    fail Flor::FlorError.new("cannot add #{x} to object", self) \
      if x

    if tcol == :array
      col.concat(elts)
    else # tcol == :object
      elts.each { |e| col.merge!(e) }
    end

    cnt = @node['cnt']
    @node['cnt'] += elts.size

    pl = message['payload'] || node_payload.current

    elts
      .collect
      .with_index { |e, i|
        apply(
          @node['fun'], determine_iteration_args(col, cnt + i), tree[2],
          payload: Flor.dup(pl)) }
      .flatten(1)
  end

  protected

  def receive_last_argument

    t = tree

    col = nil
    fun = nil
    refs = []
    @node['args'].each_with_index do |a, i|
      if ( ! fun) && Flor.is_func_tree?(a)
        fun = a
      elsif ( ! col) && Flor.is_collection?(a)
        col = a
      elsif tt = t[1][i]
        refs << Flor.ref_to_path(tt) if Flor.is_ref_tree?(tt)
      end
    end
    col ||= node_payload_ret

    fail Flor::FlorError.new("collection not given to #{heap.inspect}", self) \
      unless Flor.is_collection?(col)
    return wrap('ret' => col) \
      unless Flor.is_func_tree?(fun)

    @node['col'] = col
    @node['cnt'] = col.size
    @node['fun'] = fun

    col
      .collect
      .with_index { |e, i|
        apply(fun, determine_iteration_args(refs, col, i), tree[2]) }
      .flatten(1)
  end

  def determine_iteration_args(refs, col, idx)

    refs = Flor.dup(refs)

    args =
      if col.is_a?(Array)
        [ [ refs.shift || 'elt', col[idx] ] ]
      else
        e = col.to_a[idx]
        [ [ refs.shift || 'key', e[0] ], [ refs.shift || 'val', e[1] ] ]
      end
    args << [ refs.shift || 'idx', idx ]
    args << [ refs.shift || 'len', col.length ]

    args
  end
end

