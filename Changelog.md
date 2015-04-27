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
