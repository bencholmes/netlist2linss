# netlist2linss

A MATLAB function to convert a netlist taken from LTspice (and hopefully other SPICE programmes) and converting it to a symbolic state-space model. Designed for the creation of an archive of tone-stack models.

## Requirements

For netlist2linss.m:
- MATLAB
- Symbolic Toolbox

Additionally for test_script.m:
- Control Systems Toolbox

## Usage

The netlist must consist of only linear components, but has currently only been tested for resistors, capacitors and voltage sources.

Values of components are ignored during the creation of the state-space matrices, and must be added using

```
subs(matrix,component_symbol,component_value)
```

A typical usage is shown in the script `test_script.m`.

## Theory

The technique is based from Martin Holter's paper *'Physical Modelling of a Wah-Wah Pedal as a Case Study for Application of the Nodal DK Method to Circuits with Variable Parts'* in which a method of automatically deriving state-space matrices from a Modified Nodal Analysis (MNA) format. Both the nonlinear aspects and decomposed inversion are ignored as the idea of this project is to create a tool to accurately capture tone circuits.

MNA is a long used standard of perhaps inefficient but dependable circuit analysis. For this project, Erik Cheever's MATLAB script [**SCAM**](http://uk.mathworks.com/matlabcentral/fileexchange/3443-scam-a-tool-for-symbolically-solving-circuit-equations).

The discretisation scheme used is Trapezoidal.

## To do

- Add continuous domain option
- Add ability to parse values of components from netlist
