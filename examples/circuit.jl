using Sims, ModelingToolkit
using OrdinaryDiffEq
# using Plots

Current(x = 0.0; name = :i) = Unknown(x, name = name)
Voltage(x = 0.0; name = :v) = Unknown(x, name = name)

function VoltageSource(n1, n2; V) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        v ~ V
    ]
end

function Resistor(n1, n2; R) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        v ~ R * i
    ]
end

function Capacitor(n1, n2; C) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        D(v) ~ i / C
    ]
end

function Subsystem(n1, n2)
    @variables vs(t)
    g = 0.0  # A ground has zero volts; it's not a variable.
    [
        :r1 => Resistor(n1, vs, R = 10.0)
        :c1 => Capacitor(vs, n2, C = 5.0e-3)
        :r2 => Resistor(n2, g, R = 5.0)
    ]
end

function Circuit(v1, v2)
    g = 0.0  # A ground has zero volts; it's not a variable.
    [
        :vsrc => VoltageSource(v1, g, V = sin(2pi * 60 * t))
        :ss => Subsystem(v1, v2)
        :c1 => Capacitor(v2, g, C = 5.0e-3)
    ]
end

function runCircuit()
    @variables v1(t) v2(t)
    ckt = Circuit(v1, v2)

    sys = system(ckt)
    prob = ODAEProblem(sys, [k => 0.0 for k in states(sys)], (0, 0.1))
    sol = solve(prob, Tsit5())
    # plot(sol)
    # plot(sol, vars = [v1, v2])
end
function tstCircuit()
    @variables v1(t) v2(t)
    ckt = Circuit(v1, v2)
    ctx = Sims.flatten(ckt)
    sys = system(ckt)
end
