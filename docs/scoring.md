# Deterministic scoring

Impact coordinates are millimetres relative to target centre. For a radial
distance `d`, projectile radius `b` and scoring-ring radius `r`, the current
ISSF line-breaking rule awards the higher ring when:

```text
max(0, d - b) <= r
```

The profile's published ring diameter already describes the scoring boundary;
line thickness is used for uncertainty display, not silently added to the score.
An impact within the configured positional uncertainty of any boundary is marked
for review. Misses score zero. Multiplicity repeats the confirmed value but marks
position-derived group metrics as approximate. Actual shot count is the sum of
impact multiplicities, including misses. Maximum possible score is always that
count multiplied by the maximum value defined by the stored target snapshot.

No expected-shot field participates in scoring or validation. Automatically
detected impacts do not exist: every impact is placed, moved, multiplied or
marked as a miss by the user.

For a multi-bull BR50 profile, each record bull contributes exactly one value.
When multiple shots fall on the same bull, the lowest ring value counts; at an
equal value a non-X ten is lower than an X. Empty record bulls contribute zero.
The maximum remains 250 and every record shot beyond 25 subtracts one point,
without allowing a negative total. Multiplicity is processed as repeated shots
on that bull. Sighter bulls and positions between valid record bounds are not
accepted as record impacts.

The implementation is in `packages/scoring` and includes boundary, monotonicity,
miss, X-count, multiplicity, duplicate-bull, fixed-maximum, penalty and spread
tests.
