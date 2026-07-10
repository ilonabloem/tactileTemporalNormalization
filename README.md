# tactileTemporalNormalization

Code associated with the Bloem et al. manuscript on tactile temporal normalization.

## Layout

```
Code/
  Models/            Temporal model definitions and fitting routines
  Analysis/          Main-experiment (mainExp) and localizer analysis pipelines
  Functions/         Shared helpers (data loading, predictions, plotting settings)
  createFigures/     show_figure2..9.m and supplementary-figure scripts
  Experiment/        Stimulus presentation and timing
  rootPath.m         Resolves the data directory via a (gitignored) Data/ symlink
```

`rootPath` locates the processed data through a `Data/` symlink at the repository
root (gitignored). Point it at your local copy of the data before running any
analysis or figure script, e.g. `ln -s /path/to/tactileTemporalNormalization-Data Data`.

## Two-temporal-channel (TTC) model comparison (revision)

The revision adds the Stigliani (2017) two-temporal-channel model as a third
temporal model, compared against the linear and (delayed) normalization models on
both the fMRI BOLD and iEEG broadband data. This addresses Reviewer 2 (point 1) and
is the basis for **Supplementary Figure 3**.

The TTC model has a **sustained** channel (linear) and a **transient** channel whose
output is squared point-wise. The squaring is a nonlinearity — the same one used in
Zhou (2018) and Groen (2022) — so this is not a linear model. The channel IRFs are
fixed to the Stigliani (2017) constants (sustained τ=4.94, n=9; transient κ=1.33,
n=10, ξ=1.44); only channel weight and gain are free. For fMRI the two channels are
convolved with the same HRF used by the linear/normalization models; for iEEG the
model predicts the broadband time course directly (weight, onset shift, gain free).

Model accuracy is quantified by **leave-one-condition-out cross-validated R²**, as in
the rest of the paper:

| Dataset          | Linear | Normalization / Delayed norm. | Two-channel (TTC) |
|------------------|:------:|:-----------------------------:|:-----------------:|
| fMRI  BOLD       |  0.67  |             0.91              |     **0.93**      |
| iEEG broadband   |  0.55  |             0.91              |     **0.57**      |

On fMRI, the two-channel model performs as well as (marginally better than) the
normalization model and far better than the linear model — BOLD alone cannot separate
the two nonlinear models. On iEEG, the two-channel model is no better than the linear
model and far below delayed normalization: the neural data decisively favor
normalization.

### Files

Models (interfaces mirror the paper's own model/fit functions):
- `Code/Models/TTCmodel.m`, `Code/Models/fitTTCmodel.m` — fMRI TTC (fixed HRF; free weight, gain)
- `Code/Models/TTCmodel_IEEG.m`, `Code/Models/fitTTCmodel_IEEG.m` — iEEG TTC (free weight, shift, gain)
- `Code/Models/ttcBOLDchannels.m`, `Code/Models/ttcDisplayPred.m` — helpers (precomputed channels; display predictions)

Fitting (leave-one-condition-out cross-validation via `doCross=true`):
- `Code/Analysis/mainExp/fit_TTC_fMRI.m`
- `Code/Analysis/mainExp/fit_TTC_iEEG.m`

Outputs are saved to `Data/modelOutput_fMRI/TTC/` and `Data/modelOutput_iEEG/TTC/`.

Figures (companions to the paper's `show_figure*`; write to `Figures/`):
- `Code/createFigures/show_fig3_TTC.m`, `show_fig5_TTC.m`, `show_fig6_TTC.m` — fMRI
- `Code/createFigures/show_fig7a_TTC.m`, `show_fig8b_TTC.m` — iEEG

### Reproducing Supplementary Figure 3

```matlab
recompute_allModels_CV_R2();   % writes Figures/SupplementaryTable_CVR2.txt
make_supplementaryFigure3();   % writes Figures/SupplementaryFigure3.png/.pdf
```

`recompute_allModels_CV_R2.m` reloads the held-out cross-validated predictions for
every model and recomputes R² through a single shared definition, asserting that all
models were cross-validated on identical held-out data so the values are directly
comparable. `make_supplementaryFigure3.m` regenerates the three panels (fMRI time
courses, summed BOLD responses, iEEG time courses) and assembles the labelled figure.

### Notes

- The HRF for the fMRI TTC model is fixed to the linear (HRF) model's fitted HRF and
  shared across channels, matching the fixed-IRF spirit of Zhou (2018) / Groen (2022)
  and avoiding a degenerate free-HRF solution.
- The TTC fits use `fmincon` (the paper's linear/normalization models used `bads`).
  The cross-validation folds, held-out data, and R² metric are identical across all
  models; only the within-fold optimizer differs, which is immaterial for these
  smooth, low-dimensional fits.
