# drevalpy/curate

[![GitHub Actions CI Status](https://github.com/drevalpy/curate/actions/workflows/nf-test.yml/badge.svg)](https://github.com/drevalpy/curate/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/drevalpy/curate/actions/workflows/linting.yml/badge.svg)](https://github.com/drevalpy/curate/actions/workflows/linting.yml)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.4-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-4.2.1-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/4.2.1)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**drevalpy/curate** fits the dose-response curves of drug screens with [drevalpy](https://drevalpy.readthedocs.io) and [CurveCurator](https://github.com/kusterlab/curve_curator). It takes one well-level table per screen (sample, drug, concentration and viability) and writes, per screen, an [AnnData](https://anndata.readthedocs.io) file of samples × drugs holding pEC50, EC50, IC50, AUC and the fit statistics of every curve.

Each screen is split into chunks of curves that are fitted as independent single-core tasks, so a screen with hundreds of thousands of curves spreads across any Nextflow executor (local, SLURM, AWS Batch, ...). A rerun with `-resume` only refits the chunks whose curves changed. The result is identical to `drevalpy curate run` on the same table.

1. Plan the screen: validate the wells, optionally normalize them, and split the curves into chunks (`drevalpy curate plan`)
2. Fit every chunk as its own task (`drevalpy curate fit-chunk`)
3. Collect the fitted chunks into the curve AnnData of the screen (`drevalpy curate collect`)

With `--replicate_fits`, every dose series (each biological and technical replicate) is also fitted on its own, into a table of replicate fits next to the pooled fits.

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/get_started/environment_setup/overview) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/get_started/run-your-first-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with one row per screen:

`samplesheet.csv`:

```csv
id,wells,normalize,metadata
GDSC2,/path/to/wells/GDSC2.parquet,false,date;barcode
PRISM,/path/to/wells/PRISM.parquet,true,
```

Each `wells` file is a CSV or Parquet table with one row per well and the columns `sample`, `drug`, `concentration` (µM) and `intensity` (viability relative to the untreated control), and optionally `experiment`, `replicate` and `position`. See the [usage documentation](docs/usage.md) for all columns.

Now, you can run the pipeline using:

```bash
nextflow run drevalpy/curate \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

On a cluster or in the cloud, put the executor settings into a config file and pass it with `-c`. For SLURM:

```groovy title="slurm.config"
process {
    executor = 'slurm'
    queue    = 'normal'
}
executor {
    queueSize = 500
}
```

or for AWS Batch (the pipeline container includes the AWS CLI, so the compute environment needs no custom AMI):

```groovy title="awsbatch.config"
process {
    executor = 'awsbatch'
    queue    = 'my-batch-queue'
}
aws.region = 'eu-central-1'
workDir    = 's3://my-bucket/curate/work'
```

```bash
nextflow run drevalpy/curate -r <version> \
   -profile singularity \
   -c slurm.config \
   --input samplesheet.csv \
   --outdir results \
   -resume
```

`-resume` reuses every chunk that has been fitted before, also after the wells of a screen changed. The same curves give the same fits on any x86-64 node with AVX2, so a mixed Intel/AMD cluster, or resuming on another machine, does not change the results.

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/running/run-pipelines#using-parameter-files).

For more details, see the [usage documentation](docs/usage.md) and the [parameter documentation](nextflow_schema.json). The [output documentation](docs/output.md) describes the files the pipeline writes.

## Credits

drevalpy/curate was originally written by the drevalpy developers.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citations

If you use drevalpy/curate for your analysis, please cite drevalpy and CurveCurator:

> Bernett J, Iversen P, Picciani M, Wilhelm M, Baum K, List M. Critical evaluation of drug response prediction models with DrEval. _Nat Commun._ 2026;17:4238. doi: [10.1038/s41467-026-72903-w](https://doi.org/10.1038/s41467-026-72903-w).

> Bayer FP, Gander M, Kuster B, The M. CurveCurator: a recalibrated F-statistic to assess, classify, and explore significance of dose–response curves. _Nat Commun._ 2023;14:7902. doi: [10.1038/s41467-023-43696-z](https://doi.org/10.1038/s41467-023-43696-z).

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
