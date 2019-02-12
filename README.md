# Truck Platooning
A truck platoon consists of group of trucks moving together. One of the major motivations for truck platooning is that a truck moving behind another one, faces much reduced aerodynamic drag. This can account for significant fuel savings (typically in range of 15-20 percent). In this example, a group of trucks on the same lane of the highway having their respective destinations, dynamically try to form a platoon with their respective leading trucks. A truck forms a platoon with the truck ahead only if it anticipates the platooning to be fuel saving.

**Factors in favor of platooning** – A trucks saves fuel while it moves as part of platoon. So, if a truck is having a large overlapping journey patch with the truck ahead, it would save more fuel. 

**Factors against platooning** - Extra fuel consumption for accelerating/decelerating (for coming closer or matching speed) to form a platoon with the truck ahead.

Decision to form a platoon or otherwise is largely dependent on one of the above factors outweighing the other. 
Truck platooning strategy allows a smart truck (an independent agent), to form platoon with the truck ahead (if it is fuel efficient) by taking decisions based on the belief/knowledge it has about its environment.

This demo showcases the architecture which allows creating smart-trucks having intelligence of forming a platoon with their respective preceding trucks. Configuration parameters can be set for individual trucks to observe the variations in their behavior. The plan algorithm in the smart actor supports platooning on a straight highway lane as a proof of concept.

# Prerequisites
This model has been tested with MATLAB R2018b. 

To run this model, you need: MATLAB, Automated Driving System Toolbox (ADST), Model Predictive Control Toolbox, Simulink, Simulink Coder, and Stateflow.

# Running the model
Run the Simulink model **mTruckPlatoon.slx** and see the visualization.

# Further documentation
See the file [Truck-Platooning.pdf](https://github.com/mathworks/Truck-Platooning/blob/master/Truck-Platooning.pdf) for detailed documentation covering - Scenario description, Simulink model description, configuration and scenario visualization.
