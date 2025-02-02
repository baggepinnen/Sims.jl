TLDR: ModelingToolkit is easy to adapt to use a functional approach to composing models from components.

This write-up is a summary of explorations I've done in using ModelingToolkit (MTK) for acausal modeling using a functional approach.

MTK has an approach for composing models. 
It follows the approach used by Modelica (and Modia).
Components have `Pin`s, and `connect` is used to tie them together ([example](https://mtk.sciml.ai/dev/tutorials/acausal_components/)).

[Sims](http://tshort.github.io/Sims.jl/latest/) is a (rather old) Julia package that uses a functional approach to composing models. 
I updated Sims to use MTK in [branch](https://github.com/tshort/Sims.jl/tree/7829b580a3f1f0f6ca0169d6fc2078a933a52718) / [pull request](https://github.com/tshort/Sims.jl/pull/79).
The core code in Sims is now almost nothing.
MTK does all of the work.

With the functional approach, models are functions that return a list of equations and subcomponents.
Connection points are passed as function arguments along with other model parameters.
Connection points are "nodal" variables (voltage for an electrical system or temperature for a thermal system).

The functional approach has some advantages over the hierarchical approach of Modelica.
* Fewer variables
* Cleaner model definitions and scope
* More flexible composition of models
* No `Pins`; no `Ports`; no `connect`; no inner vs. outer variables; no `LocalScope`/`ParentScope`

Here is an example of a component definition:

```
function Capacitor(n1, n2; C) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        D(v) ~ i / C
    ]
end
```

Here is an example of a model definition:
```
function Circuit()
    @variables v1(t) v2(t)
    g = 0.0  # A ground has zero volts; it's not a variable.
    [
        :vsrc => VoltageSource(v1, g, V = sin(2pi * 60 * t))
        :ss => Subsystem(v1, v2)
        :c1 => Capacitor(v2, g, C = 5.0e-3)
    ]
end
sys = system(Circuit())    
```

Each component returns a set of equations. As components are put together, a nested list of equation is built up.
The `system` method flattens the equations and returns a `ModelingToolkit.ODESystem`.

See [here](https://github.com/tshort/Sims.jl/blob/7829b580a3f1f0f6ca0169d6fc2078a933a52718/examples/circuit.jl) for a full example.

My key takeaway is that MTK is easy to adapt to different modeling approaches.
Equations, variables, and parameters all work great. 
`ModelingToolkit.structural_simplify` is awesome.
The main gotcha I had to worry about was that variables with the same name are treated the same, even if they have different metadata.
Different components may have variables with the same name, and we don't want those to be treated the same.
I got around that by substituting variables during model flattening to make sure they are unique.

The main advance in MTK I'm looking forward to is support of events and discrete modeling.
I've got an in-progress library of components patterned after the components in the Modelica Standard Library, and many of those need event support.


