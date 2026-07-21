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

`rootPath` resolves the project's code and data root directories. For known users 
(edit the `switch userName` block to add yourself), it returns a hardcoded local 
`Data` folder (e.g. `~/Documents/Experiments/tactileTemporalNormalization/Data`).
For unknown users, it defaults to a `Data/` subfolder inside the repository.

On first call, `rootPath` also adds the repo (and its toolbox dependencies) to the
MATLAB path. Toolboxes are expected as sibling directories next to the repo and include:

- [GLMdenoise](https://github.com/cvnlab/GLMdenoise)
- [jsonlab](https://github.com/NeuroJSON/jsonlab)
- [bads](https://github.com/acerbilab/bads)
- [MRI_tools](https://github.com/WinawerLab/MRI_tools)
- [ECoG_utils](https://github.com/WinawerLab/ECoG_utils)
- FreeSurfer (via `$FREESURFER_HOME`)

## Models

Three temporal models are fit to both the fMRI BOLD and iEEG broadband data: a
**linear model**, a **normalization model** (delayed normalization for iEEG), and a
**two-temporal-channel (TTC) model**. All three are compared using leave-one-condition-
out cross-validated R², computed identically across models so results are directly
comparable.

| Dataset          | Linear | Normalization / Delayed norm. | Two-channel (TTC) |
|------------------|:------:|:-----------------------------:|:-----------------:|
| fMRI  BOLD       |  0.67  |           **0.91**            |        0.93       |
| iEEG broadband   |  0.55  |           **0.91**            |        0.57       |

Across both datasets, the normalization model substantially outperforms the linear
model, showing that a nonlinear gain-control stage is needed to capture sub-additive
temporal summation. The two-channel model performs comparably to normalization on
fMRI but far worse on iEEG, indicating that the higher temporal resolution of iEEG is
needed to distinguish between these two nonlinear accounts (see
`Code/createFigures/show_supplementaryFigure3.m` for details and Supplementary
Figure 3 in the manuscript).

Model definitions and fitting routines live in `Code/Models/`. 
Model outputs are saved to `Data/modelOutput_fMRI/` and
`Data/modelOutput_iEEG/`, organized by model name.

## Figures

Scripts in `Code/createFigures/` regenerate the paper's main and supplementary
figures, writing outputs to `Figures/`. Each `show_figureN.m` corresponds to the
similarly numbered figure in the manuscript.



## Two-temporal-channel (TTC) model details

The revision adds the Stigliani (2017) two-temporal-channel model as a third
temporal model, compared against the linear and (delayed) normalization models on
both the fMRI BOLD and iEEG broadband data. This addresses Reviewer 2 (point 1) and
is the basis for **Supplementary Figure 3**. The TTC model has a **sustained** channel 
(linear) and a **transient** channel whose output is squared point-wise. 
The squaring is a nonlinearity — the same one used in Zhou (2018) and Groen (2022) 
— so this is not a linear model. The channel IRFs are fixed to the Stigliani (2017) 
constants (sustained τ=4.94, n=9; transient κ=1.33, n=10, ξ=1.44); 
only channel weight and gain are free. For fMRI the two channels are
convolved with the same HRF used by the linear/normalization models; for iEEG the
model predicts the broadband time course directly (weight, onset shift, gain free).

Files:
- `Code/Models/TTCmodel.m`, `Code/Models/fitTTCmodel.m` — fMRI TTC (fixed HRF; free weight, gain)
- `Code/Models/TTCmodel_IEEG.m`, `Code/Models/fitTTCmodel_IEEG.m` — iEEG TTC (free weight, shift, gain)
- `Code/Models/ttcBOLDchannels.m`, `Code/Models/ttcDisplayPred.m` — helpers (precomputed channels; display predictions)
- `Code/Functions/fit_TTC_fMRI.m`, `Code/Functions/fit_TTC_iEEG.m` — fitting (leave-one-condition-out cross-validation via `doCross=true`):

Notes:
- The HRF for the fMRI TTC model is fixed to the linear (HRF) model's fitted HRF and
  shared across channels, matching the fixed-IRF spirit of Zhou (2018) / Groen (2022)
  and avoiding a degenerate free-HRF solution.
- The TTC fits use `fmincon` (the paper's linear/normalization models used `bads`).
  The cross-validation folds, held-out data, and R² metric are identical across all
  models; only the within-fold optimizer differs, which is immaterial for these
  smooth, low-dimensional fits.
