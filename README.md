[![Neovim](https://raw.githubusercontent.com/iLLucionist/growthp/master/docs/growthp_logo.png)](https://neovim.io)

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/iLLucionist/growthp/master/LICENSE.txt)

Growth Potential is an algorithm (implemented in R) that can be used to provide recommendations to teams (and other cross sections / nestings, such as job profiles, departments, and so forth) how they may improve themselves and grow on work outcomes they value based on employee survey data:

- Use the organization as their own internal benchmark
- Compare teams against this benchmark
- See the growth potentials of teams. Where can they still improve?
- See which "knobs" (work factors) they can turn to improve work outcomes
- Get a recommended action list that shows in order which "knobs" to turn.

See the [slide deck (pdf)](https://raw.githubusercontent.com/iLLucionist/growthp/master/docs/growth_potential.pdf) for a more detailed explanation.

## Getting started

Just download the repository. You only need the file `growthp.R`, which contains all the functions you need. See `example.R` and the slide deck for how to use it.

## Example

Asessment companies tend to give just your scores, but it doesn't tell you how what you should do with these scores. Growth Potential gives actual recommendations what teams could to to function better and improvee employee well-being (depending on the work outcomes measured in the employee survey):

    Recommendation for:
      The Hot List (#10)

    Scores (Score - Benchmark - Growth):
      choice: 6.5 - 8.2 - 1.7
      obstacles: 5.1 - 4.2 - 0.8
      redtape: 8.3 - 6.0 - 2.3
      value: 7.3 - 8.9 - 1.6
      jobsat: 7.9 - 8.3 - 0.4
      engage: 7.6 - 8.3 - 0.7
      burnout: 3.5 - 2.1 - 1.4

    Recommended actions:
      value (38%)
      redtape (26%)
      choice (20%)
      obstacles (16%)

    NOTE. Ranked most to least influential on all outcomes.

- Team name up top
- You get the scores, the benchmark, and the growth potential for every measured variable for the teams
- You get a list of recommended actions, in order of the actions that have the most impact across all work outcomes. Here, value has the most impact on job satisfaction, work engagement, and burnout (38% of all recommended actions).
