# Smart Satiety: local experimental heuristic v1

This is an unvalidated, descriptive 1–10 food-property score, **not** Holt's
measured Satiety Index, a health score, a clinical recommendation, a prediction
of hunger, or a weight-loss target. Do not maximize it or delay eating because
of it. No hours are output. No API calls, goals, rewards or pet state depend on
the score. Optional local hunger observations are described in
`HUNGER_OBSERVATIONS.md`; they do not calibrate the formula. Clinical validation
is absent.

## What the research supports (and what it does not)

- [Holt et al. 1995](https://pubmed.ncbi.nlm.nih.gov/7498104/) compared 38 foods
  in equal-energy servings, using repeated subjective ratings over two hours.
  Associations with food weight, protein, fiber and water motivate candidate
  factors; they do not supply our coefficients or personal hours of fullness.
- [Flood-Obbagy & Rolls 2009](https://pubmed.ncbi.nlm.nih.gov/19110020/) compared
  apple forms in a controlled preload experiment. Whole apple and juice were
  not equivalent even with matched energy and other features. This motivates
  asking about food structure, not inferring it from an AI name.
- [Rolls et al. 1999](https://pubmed.ncbi.nlm.nih.gov/10500012/) distinguished
  water incorporated into food from water served alongside it. Thus drinking
  water logs never increase this score. The study population and meal setting
  limit generalization.
- [Pritchard et al. 2014](https://pubmed.ncbi.nlm.nih.gov/24200201/) did not find
  differences in appetite AUC after its texture/energy-density interventions.
  This counterexample matters: there is no universal texture rule proven by
  these trials. All six numeric weights below are engineering hypotheses.

## Inputs and missingness

The diary meal button evaluates all displayed entries in that meal together.
Each entry requires person-confirmed nutrition provenance. Legacy records and
AI-only estimates cannot generate a score. Nutrition Engine validates and
scales the stored profile by edible portion mass. Sum grams, calories, protein,
fiber and food water **before** applying the formula; never sum item scores.
The formula is invariant to splitting an ingredient into multiple rows.

Known fiber requires every item to mark fiber known. Water is known only when
every item is catalogue-backed with a positive stored food-water value; label
entry does not collect water. A default/legacy zero is unknown, not a measured
zero. This conservative rule also treats a genuinely dry zero-water food as
unknown. Do not estimate water as 100 minus macros: it omits other components.
Unknown water/fiber is displayed as unknown, not as a zero measurement.

The person selects the structure of the whole meal. This temporary selection
is not saved as a verified food attribute. Supported scope: positive calorie
content, total edible mass >0 and <=3000 g, valid individual portions. Pure
water, empty meals, invalid nutrients and out-of-scope masses have no score.

## Exact formula v1

Let `u(x)=clamp(x,0,1)`, `M`=total grams, `E`=kcal, `P`=protein grams,
`F`=fiber grams, `W`=food-water grams. Compute:

```
q = .25*u(P/30) + .20*u(M/400) + .15*u((4-E/M)/3.5)
  + .15*u(F/10) + .10*u(W/M) + .15*T
g = u(E/200)
score = clamp(round(1 + 9*g*q), 1, 10)
T = solid 1.0 | soft/pureed .6 | liquid .2 | mixed .7
```

Unknown F, W or T contributes the full possible range 0..1 for that factor,
producing lower and upper scores. If rounding makes these equal, show one
integer but still list the missing factors. This interval is a sensitivity
envelope **within this unvalidated formula**, not a statistical confidence
interval or a reliable bound on personal response. Known inputs still have
measurement/transcription error, which this interval does not quantify.

The energy gate prevents tiny bites from inheriting a large score based solely
on density. 200 kcal, 400 g, 30 g protein, 10 g fiber and the density constants
are saturating model parameters, not recommended portion sizes or nutrient
targets. These parameters, all weights and ordinal texture values need future
evaluation. Mass, water and energy density are correlated; their contributions
must not be interpreted as independent causal effects. This prototype can
over/underestimate particular foods and mixed dishes. It is deliberately
separate from calorie goals, food recommendations, motivation and rewards.

## Verification boundaries

Unit tests cover missingness, invalid/legacy inputs, source persistence,
splitting invariance, tiny portions and score bounds. Widget tests cover diary
navigation, unchanged saved data, no score for unconfirmed entries and large
text. These are implementation tests, not evidence that the formula predicts
satiety. Native smoke tests use synthetic labels in a disposable emulator.

Voluntary observations now support timestamps, correction and deletion. They
are saved only on explicit action and never uploaded to the recognition server.
Do not derive personal coefficients or prediction hours from small, biased
observations. Calibration remains unimplemented.
