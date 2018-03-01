
# trap

Watches the messages emitted in the execution and reacts when
a message matches certain criteria.

Once the trap is set (once the execution interprets its branch), it
will trigger for any matching message, unless the `count:` attribute
is set.

When the execution terminates, the trap is removed as well.

By default, the observation range is the execution, only messages
in the execution where the trap was set are considered.
The trap can be extended via the `range:` attribute.

"trap" triggers a function, while "on" triggers a block.

## the point: criterion

The simplest thing to trap is a 'point'. Here, the trap is set for
any message whose point is 'terminated':
```
sequence
  trap 'terminated'
    def msg \ trace "terminated(f:$(msg.from))"
  trace "here($(nid))"
    # OR
#sequence
#  trap 'terminated'
#    def msg \ trace "terminated(f:$(msg.from))"
#  trace "here($(nid))"
```

## the heap: criterion

Given a procedure like `sequence`, `concurrence` or `apply`, trigger
a piece of code each time the procedure receives the "execute" or the
"receive" message.

```
trap heap: 'sequence'
  def msg
    trace "$(msg.point)-$(msg.tree.0)-$(msg.nid)<-$(msg.from)"
sequence
  noret _
#
# will trace:
#  0:execute-sequence-0_1<-0
#  1:receive--0_1<-0_1_0
#  2:receive--0<-0_1
```

## the heat: criterion

While `heap:` filters on the actual flor procedure names, `heat:` is
looser, it catches whatever stands "at the beginning of the flor line".
It's useful to catch function calls.

```
trap heat: 'fun0'
  def msg
    trace "t-$(msg.tree.0)-$(msg.nid)"
define fun0
  trace "c-fun0-$(nid)"
sequence
  fun0 _
  fun0 # not a call

# will trace:
# 0:t-fun0-0_2_0
# 1:c-fun0-0_1_1_0_0-2
# 2:t--0_2_0
# 3:t--0_2_0
# 4:t-fun0-0_2_1
```

`heat:` accepts strings or regular expressions:

```
trap heat: [ /^fun\d+$/ 'funx' ]
  def msg \ trace "t-$(msg.tree.0)-$(msg.nid)"
```

## the tag: criterion

```
trap tag: 'x'
  def msg
    trace "$(msg.tags.-1)-$(msg.point)"
# ...
sequence tag: 'x'
  trace 'c'

# will trace "x-entered" and "c"
```

Traps one or more tags.

By default traps upon entering, by using `point:`, one can trap upon
leaving (or both).
```
#trap tag: 'x' point: [ 'entered', 'left' ]
trap tag: 'x' point: 'left'
  def msg
    trace "$(msg.tags.-1)-$(msg.point)"
```

## the signal: criterion

`signal:` traps signals directed at the execution. Signals are
directly
```
trap signal: 'S0'
  def msg
    trace "S0"
# ...
signal 'S0'
```

Note that it's OK to trap all signals, whatever their name, directed at
the execution by using `point: 'signal'`, as in:
```
trap point: 'signal'
  def msg
    trace "caught signal '$(sig)'"
```

[on](on.md) is a macro that turns
```
on 'rejected'
  trace "execution received signal $(sig)"
```
into
```
trap signal: 'rejected'
  def msg
    trace "execution received signal $(sig)"
```
Please note how "on" accepts a block while "trap" accepts a function.

## the tag: short criterion

TODO

## the bind: setting

TODO (is it worth implementing it or is range: sufficient?)

## the range: limit

* 'subnid' (default)
* 'execution'
* 'domain'
* 'subdomain'

TODO

## the count: limit

```
trap tag: 'x' count: 2
  # ...
```
will trigger when the execution enters the tag 'x', but will trigger only
twice.


## see also

[On](on.md) and [signal](signal.md).


* [source](https://github.com/floraison/flor/tree/master/lib/flor/punit/trap.rb)
* [trap spec](https://github.com/floraison/flor/tree/master/spec/punit/trap_spec.rb)
