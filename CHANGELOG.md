# drevalpy/curate: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.1.0dev - [unreleased]

Initial release of drevalpy/curate, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Samplesheet with one row per screen: `id`, `wells` (CSV or Parquet well table) and the optional per-screen `normalize` and `metadata` columns.
- `DREVALPY_CURATEPLAN`: splits every screen into chunks of at most `--max_chunk_size` curves with `drevalpy curate plan`.
- `DREVALPY_CURATEFITCHUNK`: fits every chunk as its own single-core task with `drevalpy curate fit-chunk`, cached by chunk content so `-resume` only refits changed chunks.
- `DREVALPY_CURATECOLLECT`: assembles the fitted chunks of a screen into `curves/<id>.h5ad` with `drevalpy curate collect`.
- Parameters `--replicate_fits`, `--min_doses`, `--fit_speed` and `--max_chunk_size`.
- Fits reproducible across x86-64 nodes with AVX2 by pinning `OPENBLAS_CORETYPE=Haswell` and single-threaded BLAS.
- Retries with more memory and time for chunk fits and whole-screen steps.
- `Dockerfile` for the `ghcr.io/drevalpy/curate` container (drevalpy only), and a GitHub Actions workflow building it against the drevalpy ref in `DREVALPY_REF`.
- `test` and `test_full` profiles and an nf-test pipeline test.

### `Fixed`

### `Dependencies`

| Dependency      | New version |
| --------------- | ----------- |
| `drevalpy`      | 2.0.0       |
| `curve-curator` | 0.6.0       |

### `Deprecated`
