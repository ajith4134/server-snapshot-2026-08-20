# Transcript — Video by datasciencefoundry

Channel: datasciencefoundry  |  Duration: 00:00
Source: https://www.instagram.com/reel/DZ2eqaZInfk/
Transcript source: whisper:small

**[00:00]** Gradient descent is the optimization algorithm that powers nearly all of modern machine learning. Its goal is to find the best parameter values for a model, the ones that minimize prediction error and make the model as accurate as possible. To picture how it works, imagine the model's error as a landscape of hills and valleys. Your position on this landscape is one set of parameter values and the elevation is how much error those values produce. The goal is to descend until you reach

**[00:30]** the lowest point, where the error is smallest. That error is measured by a loss function, the scorekeeper that tells the model how far its predictions are from the truth. It's what decides whether a change in the parameters is moving us in the right direction. But how does gradient descent actually work? Gradient descent starts from an initial random guess and then asks which way is downhill. It finds out by computing the slope of the loss, the gradient, using derivatives. The gradient is like a compass. It points in the direction where

**[01:04]** the error rises most steeply, uphill, so the algorithm turns around and steps the opposite way, downhill, in the direction where the error drops most steeply. The size of each step is set by the learning rate. Too small and the model crawls along, taking forever to learn. Too large and it overshoots the minimum, bouncing around it or flying off entirely. With a well-tuned rate, it makes steady progress down toward a minimum. In simple problems that's the global minimum,

**[01:35]** the best possible solution. But complex models have many local minima. Values that look like the bottom yet aren't. Tricks like training on small random batches of data or adapting the step size as it learns help escape them. But the core idea never changes. Measure the slope, take a step downhill and repeat until the error is as low as it can go.