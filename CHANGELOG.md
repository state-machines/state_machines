## 0.6.0

* Drop support to EOL rubies.
* Support kwargs for ruby 3.0+.

## [0.6.1](https://github.com/state-machines/state_machines/compare/state_machines-v0.6.0...state_machines/v0.6.1) (2025-04-03)


### Features

* drop support ruby prior 2.7. ([#87](https://github.com/state-machines/state_machines/issues/87)) ([f9cb1e0](https://github.com/state-machines/state_machines/commit/f9cb1e0aa80a7465e1677a80265fa5ae270cb1f9))
* Drop support to ruby prior 3.0 ([#95](https://github.com/state-machines/state_machines/issues/95)) ([0ce8030](https://github.com/state-machines/state_machines/commit/0ce80309941fccd208dfbe9a88b7590d9cae8717))
* introduce STDIO renderer ([#109](https://github.com/state-machines/state_machines/issues/109)) ([1bee973](https://github.com/state-machines/state_machines/commit/1bee973af26cbe969fd3e9ae094c6829e995b251))


### Bug Fixes

* enhance evaluate_method to support keyword arguments and improve block handling for Procs and Methods ([8b6ebb1](https://github.com/state-machines/state_machines/commit/8b6ebb1ece7cb4a2b7e51f6c752af9ae437b30c0))
* improve method argument handling to support jruby and truffleruby and add temporary evaluation for strings ([64f9cca](https://github.com/state-machines/state_machines/commit/64f9cca3d1b744e49e9caadfc21d5ff2aa930c5c))
* use symbol syntax for instance variable checks ([75a832c](https://github.com/state-machines/state_machines/commit/75a832c39cf2d8a6c29be5b13d7e454cd179c834))
* use symbol syntax for instance variable checks ([0f01465](https://github.com/state-machines/state_machines/commit/0f014651b4709e707d658517e3f85e366f45bac5))

## 0.5.0

*   Fix states being evaluated with wrong `owner_class` context

*   Fixed state machine false duplication

*   Fixed inconsistent use of :use_transactions

*   Namespaced integrations are not registered by default anymore

*   Pass `static: false` in case you don't want initial states to be forced. e.g.

    ```ruby
    # will set the initial machine state
    @machines.initialize_states(@object)

    # optionally you can pass the attributes to have that as the initial state
    @machines.initialize_states(@object, {}, { state: 'finished' })

    # or pass set `static` to false if you want to keep the `object.state` current value
    @machines.initialize_states(@object, { static: false })
    ```
