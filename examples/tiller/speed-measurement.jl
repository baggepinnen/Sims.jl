
using Sims, Sims.Lib

export SecondOrderSystem, SecondOrderSystemUsingSimsLib, SampleAndHold, IntervalMeasure, PulseCounting

"""
# Examples of speed measurement

These examples show several ways of measuring speed on a rotational
system. They are based on Michael's section on [Speed
Measurement](http://book.xogeny.com/behavior/discrete/measuring/). These
examples include use of Discrete variables and Events.

The system is based on the following plant:

![diagram](http://book.xogeny.com/_images/PlantWithPulseCounter.svg)

"""
@comment 


"""
Rotational example

http://book.xogeny.com/behavior/equations/mechanical/

"""
function SecondOrderSystem(; phi1 = Unknown("Angle of inertia 1"),
                             phi2 = Unknown("Angle of inertia 2", 1.0),
                             omega1 = Unknown("Velocity of inertia 1"),
                             omega2 = Unknown("Velocity of inertia 2"),
                             J1 = 0.4, J2 = 1.0, k1 = 11.0, k2 = 5.0, d1 = 0.2, d2 = 1.0)
    phidiff = Unknown(default_value(phi2) - default_value(phi1))  # Used because der(phi2 - phi1) isn't supported
    [
        ## Equations for inertia 1
        phidiff ~ phi2 - phi1
        der(phi1) ~ omega1
        J1*der(omega1) - d1*der(phidiff) ~ k1*(phi2-phi1)
        ## Equations for inertia 2
        der(phi2) ~ omega2
        J2*der(omega2) + d1*der(phidiff) + d2*der(phi2) ~ k1*(phi1-phi2) - k2*phi2
    ]
end



"""
Rotational example based on components in Sims.Lib

http://book.xogeny.com/behavior/equations/mechanical/

![diagram](http://book.xogeny.com/_images/PlantWithPulseCounter.svg)

"""
function SecondOrderSystemUsingSimsLib(; phi1 = Angle(label = "Angle of inertia 1", value = 0.0, fixed = true),
                                         phi2 = Angle(label = "Angle of inertia 2", value = 1.0, fixed = true),
                                         omega1 = Unknown(label = "Velocity of inertia 1", value = 0.0, fixed = true),
                                         omega2 = Unknown(label = "Velocity of inertia 2", value = 0.0, fixed = true),
                                         J1 = 0.4, J2 = 1.0, k1 = 11.0, k2 = 5.0, d1 = 0.2, d2 = 1.0)
    [
        der(phi1) ~ omega1
        der(phi2) ~ omega2
        Inertia(phi1, J1)
        Inertia(phi2, J2)
        SpringDamper(phi1, phi2, k1, d1)
        SpringDamper(phi2, 0.0, k2, d2)
    ]
end



"""
Rotational example with sample-and-hold measurement

http://book.xogeny.com/behavior/discrete/measuring/#sample-and-hold

"""
function SampleAndHold()
    sample_time = 0.125
    omega1 = Unknown("omega1")
    omega1_measured = Discrete(0.0)
    omega1_measured_u = Unknown("omega1 measured")
    [
        Event(sin(t / sample_time * 2pi ),
              [reinit(omega1_measured, omega1)])
        SecondOrderSystem(omega1 = omega1)
        omega1_measured_u ~ omega1_measured
    ]
end

"""
Rotational example with interval measurements

http://book.xogeny.com/behavior/discrete/measuring/#interval-measurement

"""
function IntervalMeasure()
    teeth = 200
    tooth_angle = 2pi / teeth
    @named phi1 = Unknown()
    @named omega1_measured_u = Unknown()
    omega1_measured = Discrete(0.0)
    next_phi = Discrete(default_value(phi1) + tooth_angle)
    prev_phi = Discrete(default_value(phi1) - tooth_angle)
    last_time = Discrete(0.0)
    [
        Event(ifelse(phi1 > next_phi, phi1 - next_phi, prev_phi - phi1),
              [
                       reinit(omega1_measured, tooth_angle / (t - last_time))
                       reinit(next_phi, phi1 + tooth_angle)
                       reinit(prev_phi, phi1 - tooth_angle)
                       reinit(last_time, t)
                       ])
        SecondOrderSystem(phi1 = phi1)
        omega1_measured_u ~ omega1_measured
    ]
end

"""
Rotational example with pulse counting

http://book.xogeny.com/behavior/discrete/measuring/#pulse-counting

"""
function PulseCounting()
    sample_time = 0.125
    teeth = 200
    tooth_angle = 2pi / teeth
    phi1 = Unknown("phi1")
    omega1_measured_u = Unknown("omega1 measured")
    omega1_measured = Discrete(0.0)
    next_phi = Discrete(default_value(phi1) + tooth_angle)
    prev_phi = Discrete(default_value(phi1) - tooth_angle)
    count = Discrete(0)
    [
        Event(ifelse(phi1 > next_phi, phi1 - next_phi, prev_phi - phi1),
              [
                       reinit(next_phi, phi1 + tooth_angle)
                       reinit(prev_phi, phi1 - tooth_angle)
                       reinit(count, count + 1)
                       ])
        Event(sin(t / sample_time * 2pi),
              [
                       reinit(omega1_measured, count * tooth_angle / sample_time)
                       reinit(count, 0)
                       ])
        SecondOrderSystem(phi1 = phi1)
        omega1_measured_u ~ omega1_measured
    ]
end
