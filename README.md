[![Neovim](https://raw.githubusercontent.com/iLLucionist/growthp/master/docs/growthp_logo.png)](https://github.com/iLLucionist/growthp)

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/iLLucionist/growthp/master/LICENSE.txt)

Growth Potential is an HR analytics algorithm implemented in R that can be used to recommend teams concrete actions that may help them improve and grown on work outcomes they value based on employee research data.

- Industry benchmarks have substantial issues (see slidedeck below). Therefore, growth potential leverages the unique value of your organization by calculating an internal benchmark that is tailored specifically to your organization and its unique characteristics.
- Teams are compared against this internal benchmark. This internal benchmark is realistic and attainable.
- You can see the growth potential of teams. What is going well and where can teams still improve?
- See which "knobs" teams may turn to improve important work outcomes.
- Get a recommended action list for every team that shows which "knobs" (work factors) to turn.
- Uses multivariate regression to see what works in your organization.

Important: this requires employee survey data, which for every row an employee and columns for independent variables, dependent variables, and nesting data (e.g., teams).

See the [slide deck (pdf)](https://raw.githubusercontent.com/iLLucionist/growthp/master/docs/growth_potential.pdf) for a more detailed explanation.

## Getting started

Just download the repository. You only need the file `growthp.R`, which contains all the functions you need. See `example.R` and the slide deck for how to use it.

## Example

Assessment companies tend to give just your scores, but it doesn't tell you how what you should do with these scores. Growth Potential gives actual recommendations what teams could to to function better and improve employee well-being (depending on the work outcomes measured in the employee survey):

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
