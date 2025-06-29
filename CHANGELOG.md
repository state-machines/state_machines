## 0.6.0

* Drop support to EOL rubies.
* Support kwargs for ruby 3.0+.

## [0.31.0](https://github.com/state-machines/state_machines/compare/state_machines/v0.30.0...state_machines/v0.31.0) (2025-06-29)


### Features

* modernize codebase with Ruby 3.2+ features ([#134](https://github.com/state-machines/state_machines/issues/134)) ([b3ab92d](https://github.com/state-machines/state_machines/commit/b3ab92de9c90826a521097a863a137fd2cb429c2))
* respect ignore_method_conflicts in State#add_predicate ([#139](https://github.com/state-machines/state_machines/issues/139)) ([d897c50](https://github.com/state-machines/state_machines/commit/d897c5042aa4b6160da80b73fc352da0f2aacd8e)), closes [#135](https://github.com/state-machines/state_machines/issues/135)


### Bug Fixes

* Add run_action as a hash option ([#137](https://github.com/state-machines/state_machines/issues/137)) ([d213cd0](https://github.com/state-machines/state_machines/commit/d213cd0fa1e5ba51dce81816672ed0532ee364b0))
* Passing event arguments to guards ([#132](https://github.com/state-machines/state_machines/issues/132)) ([4e21b79](https://github.com/state-machines/state_machines/commit/4e21b79a16d2ea3ef6fcb3e882fb2b6288f0c132))


### Miscellaneous Chores

* release 0.31.0 ([c75d9b8](https://github.com/state-machines/state_machines/commit/c75d9b84cf0b2cc6a2a7ec2f9262fd5bb2db5adf))

## [0.30.0](https://github.com/state-machines/state_machines/compare/state_machines/v0.20.0...state_machines/v0.30.0) (2025-06-19)


### Features

* add basic safety check for eval_helpers ([#126](https://github.com/state-machines/state_machines/issues/126)) ([604e3e6](https://github.com/state-machines/state_machines/commit/604e3e6f3958f2b4be7a9fcbac9502b4583946de))
* add more test_helper after receiving feedback ([#128](https://github.com/state-machines/state_machines/issues/128)) ([4f3ab0a](https://github.com/state-machines/state_machines/commit/4f3ab0a4733d2aabfe78b193cde426b354e96d33))
* add support to kwargs ([#130](https://github.com/state-machines/state_machines/issues/130)) ([9be0c8f](https://github.com/state-machines/state_machines/commit/9be0c8f6cd20990745878bfd0dd4ce6d6c8ff8a1))


### Bug Fixes

* extract internal into modules ([#131](https://github.com/state-machines/state_machines/issues/131)) ([9f4850d](https://github.com/state-machines/state_machines/commit/9f4850d032d374239cf261cc4abcfed09e49ea3d))
* restore jruby support and tests ([#129](https://github.com/state-machines/state_machines/issues/129)) ([2bcb42e](https://github.com/state-machines/state_machines/commit/2bcb42e80afff2eefb29c475cd667184061109ab))

## [0.20.0](https://github.com/state-machines/state_machines/compare/state_machines/v0.10.1...state_machines/v0.20.0) (2025-06-17)


### Features

* remove Hash hack that haunted me for years ([#122](https://github.com/state-machines/state_machines/issues/122)) ([8e5de38](https://github.com/state-machines/state_machines/commit/8e5de3867aed2599d4ada6f32ced2bf95c328f9f))

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
