## Dual `_select` without GVL:

Always release GVL:

```
Warming up --------------------------------------
              KQueue    55.896k i/100ms
              Select    17.023k i/100ms
Calculating -------------------------------------
              KQueue    532.515k (± 8.0%) i/s -      2.683M in   5.071193s
              Select    177.956k (± 3.4%) i/s -    902.219k in   5.075817s

Comparison:
              KQueue:   532515.3 i/s
              Select:   177956.1 i/s - 2.99x  (± 0.00) slower
```

Only release GVL with non-zero timeout, with selector.elect(1) (so always hitting slow path):

```
Warming up --------------------------------------
              KQueue    39.628k i/100ms
              Select    18.330k i/100ms
Calculating -------------------------------------
              KQueue    381.868k (± 6.5%) i/s -      1.902M in   5.004267s
              Select    171.623k (± 3.0%) i/s -    861.510k in   5.024308s

Comparison:
              KQueue:   381867.8 i/s
              Select:   171622.5 i/s - 2.23x  (± 0.00) slower
```

Only release GVL with non-zero timeout, with selector.select(0) so always hitting fast path:

```
Warming up --------------------------------------
              KQueue    56.240k i/100ms
              Select    17.888k i/100ms
Calculating -------------------------------------
              KQueue    543.042k (± 7.8%) i/s -      2.700M in   5.003790s
              Select    171.866k (± 4.3%) i/s -    858.624k in   5.005785s

Comparison:
              KQueue:   543041.5 i/s
              Select:   171866.2 i/s - 3.16x  (± 0.00) slower
```

Only release GVL when no events are ready and non-zero timeout, with selector.select(1):

```
Warming up --------------------------------------
              KQueue    53.401k i/100ms
              Select    16.691k i/100ms
Calculating -------------------------------------
              KQueue    524.564k (± 6.1%) i/s -      2.617M in   5.006996s
              Select    179.329k (± 2.4%) i/s -    901.314k in   5.029136s

Comparison:
              KQueue:   524564.0 i/s
              Select:   179329.1 i/s - 2.93x  (± 0.00) slower
```

So this approach seems to be a net win of about 1.5x throughput.