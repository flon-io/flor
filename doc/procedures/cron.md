
# cron

A macro-procedure, rewriting itself to `schedule cron: ...`.

```
cron '0 0 1 jan *'
  task albert 'take out garbage'
```

is automatically turned into:

```
schedule cron: '0 0 1 jan *'
  def msg
    task albert 'take out garbage'
```

## see also

[Schedule](schedule.md), and [every](every.md).


* [source](https://github.com/floraison/flor/tree/master/lib/flor/punit/cron.rb)
* [cron spec](https://github.com/floraison/flor/tree/master/spec/punit/cron_spec.rb)

