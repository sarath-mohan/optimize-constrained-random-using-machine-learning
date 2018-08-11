# Abstract

Constrained random simulations play a critical role in Design Verification today. But the effort and time spent to manually update the input constraints, analyzing and prioritizing the unverified features in the design, significantly affect the time taken to converge to the coverage goal. This research work focuses on the optimization of constrained random verification using Machine Learning algorithms, in a coverage-driven simulation using a Universal Verification Methodology (UVM) framework. The optimization will greatly reduce the time a simulation takes to converge to the coverage goal. This research work targets automating the update of the constraints during runtime, abstracting the need for understanding the design to verify it, using Machine Learning. The verification environment is further optimized using techniques including Objective Function, Rewinding and Dynamic Seed Manipulation. The enhanced environment resolves the limitations of the previous efforts at employing these techniques, optimizing the scalability of the environment and enhancing its compatibility at verifying complex combinational designs and sequential designs including Finite State Machines (FSMs).

# Background

This repository is the example code presenting the implementation of the proposed method in the thesis publication "Optimization of Constrained Random Verification using Machine Learning" by Sarath Mohan Ambalakkat (ambal006@umn.edu, University of Minnesota, Twin Cities) 

# Getting Started

Use the "make help" command to enumerate the available Make targets that are available. The output will look similar to the below:

```
> make help

clean                      Cleans up work area
help                       Help Text
server                     Starts up a TCL branching server
shutdown                   Shutdown the the TCL server
status                     Status from the TCL server
synopsys                   Runs a Synopsys Build and does ...
synopsys_reload            Builds and Reloads a simulation from file
...
```

The simplest example of running is to run the following Make targets which will run a simulation locally using the algorithm.

```
> make clean
> make synopsys
```

Afterwards you can replicate the optimal solution by running.

```
> make synopsys_sim_reload
```

# Advanced Arguments

There are a number of Make parameters that can effect the simulation.

PARAMETER           | DEFAULT            | DESCRIPTION
--------------------|--------------------|------------
WIDTH               | 3                  | the bit width of the inputs A and B of the DUT
SERVER              | none               | the IP address of the TCL server to coordinate the parallel simulations. if set to "none" will run locally without the aid of a server
PORT                | 9000               | the port of the IP address of the TCL server to coordinate the parallel simulations
START_TIME          | 7                  | the start time in simulation units to start the algorithm
INTERVAL_TIME       | 10                 | the interval time in simulation unitis to start the algorithm
MAX_OBJECTIVE       | 100                | the value of the "Objective Function" that is required to satisify the simulation
COVERAGE_DUMP       | 0                  | if set to 1 will dump code coverage as well as functional coverage
SEED                | +ntb_random_seed=2 | the seed used in the simulation
PARALLEL_SIMS       | 5                  | the number of parallel simulations to run
UVM_VERBOSITY       | UVM_LOW            | the verbosity of the UVM log
MAX_RAND_SIM_COUNT  | 10                 | Maximum number of Random Simulations before updating constraints
ML_ENABLED          | 0                  | Enable for Machine Learning Algorithm to optimize Constrained Random Simulations; ML_ENABLED=1 for Linear Regression Model; ML_ENABLED=2 for Artificial Neural Networks (ANN);
FSM_OPT_ENABLE      | 0                  | Enable if Design has an FSM, to enable optimization of ENV for Sequential Designs

# Examples

```
> make synopsys WIDTH=3
```

The above will build and run a local simulation with a DUT with both inputs being 3 bits each. It will iterate on the simulation until it finds the combination of inputs that satisfy the "Objective Function". The resultant "replicate" file will allow for an efficient rerun.

```
> make synopsys ML_ENABLED=2
```

The above will run a local simulation with the optimisation algorithm implementing Artificial Neural Networks for optimizing the constrained random simulations.



# Requirements

1. TCL extension, FANN needs to be installed. "$dir_fann" must be set to the path directing to FANN extension in simulation environment, as shown in ~tcl/rclass/pkgIndex.tcl.

2. TCL library, "math" used.  

2. This code was developed and tested with VCS 2016.06 on 64 bit Linux. Patches to port to other simulators are accepted. The concepts should be implementable on current SystemVerilog simulators.


