## 0.6.0

* Drop support to EOL rubies.
* Support kwargs for ruby 3.0+.

## [0.10.1](https://github.com/state-machines/state_machines/compare/state_machines/v0.10.0...state_machines/v0.10.1) (2025-06-15)


### Features

* expose test helper ([74d2f5b](https://github.com/state-machines/state_machines/commit/74d2f5bb9b4718c1acfc9d11fc4bdf9a2d713622))
* expose test helper ([170f277](https://github.com/state-machines/state_machines/commit/170f27708ab324c0622db462e76db79a181dafd4))

## [0.10.0](https://github.com/state-machines/state_machines/compare/state_machines-v0.6.0...state_machines/v0.10.0) (2025-05-28)


### Features

* Add `all.except` as an alias for `all -` ([da99aee](https://github.com/state-machines/state_machines/commit/da99aeefa4ec99dc72da188d09a14227e49e8412))
* Allow customization of default error messages ([106033f](https://github.com/state-machines/state_machines/commit/106033fea5120a98790d73a6d155c60bcd39ffb6))
* drop support ruby prior 2.7. ([#87](https://github.com/state-machines/state_machines/issues/87)) ([f9cb1e0](https://github.com/state-machines/state_machines/commit/f9cb1e0aa80a7465e1677a80265fa5ae270cb1f9))
* Drop support to ruby prior 3.0 ([#95](https://github.com/state-machines/state_machines/issues/95)) ([0ce8030](https://github.com/state-machines/state_machines/commit/0ce80309941fccd208dfbe9a88b7590d9cae8717))
* improve STDIO renderer ([4ee3edc](https://github.com/state-machines/state_machines/commit/4ee3edc58e67d313f07fc9e125373db0e12a84b2))
* introduce STDIO renderer ([#109](https://github.com/state-machines/state_machines/issues/109)) ([1bee973](https://github.com/state-machines/state_machines/commit/1bee973af26cbe969fd3e9ae094c6829e995b251))


### Bug Fixes

* enhance evaluate_method to support keyword arguments and improve block handling for Procs and Methods ([8b6ebb1](https://github.com/state-machines/state_machines/commit/8b6ebb1ece7cb4a2b7e51f6c752af9ae437b30c0))
* extract Machine class_methods to it own file to reduce file loc ([5d56ad0](https://github.com/state-machines/state_machines/commit/5d56ad036cc4a9d99650764891dca72bdc697b39))
* Implement conflict check in State#add_predicate ([316cb1a](https://github.com/state-machines/state_machines/commit/316cb1a663169127dac8e24508fed785505f483a))
* improve method argument handling to support jruby and truffleruby and add temporary evaluation for strings ([64f9cca](https://github.com/state-machines/state_machines/commit/64f9cca3d1b744e49e9caadfc21d5ff2aa930c5c))
* update documentation and improve STDIO renderer ([15bcd40](https://github.com/state-machines/state_machines/commit/15bcd403e5f0a24fde8d9b8be6b642ab0fcf851f))
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
