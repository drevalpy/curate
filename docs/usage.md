# drevalpy/curate: Usage

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

drevalpy/curate fits the dose-response curves of one or more drug screens with [drevalpy](https://drevalpy.readthedocs.io) and [CurveCurator](https://github.com/kusterlab/curve_curator). Every screen is split into chunks of at most `--max_chunk_size` curves, each chunk is fitted as a single-core task, and the fitted chunks are collected into one AnnData file per screen (see the [output documentation](output.md)). The result is identical to `drevalpy curate run` on the same well table.

## Samplesheet input

You will need to create a samplesheet with one row per screen. Use this parameter to specify its location. It has to be a comma-separated file with a header row and the columns shown below.

```bash
--input '[path to samplesheet file]'
```

```csv title="samplesheet.csv"
id,wells,normalize,metadata
GDSC2,/path/to/wells/GDSC2.parquet,false,date;barcode
PRISM,/path/to/wells/PRISM.parquet,true,
```

| Column      | Description                                                                                                                                                                                                                                                                                                                                    |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`        | Required. Name of the screen, unique in the samplesheet, made of letters, digits, `.`, `_` and `-`. The curves are written to `curves/<id>.h5ad`.                                                                                                                                                                                              |
| `wells`     | Required. Path or URL to the well table of the screen, a CSV (`.csv`) or Parquet (`.parquet`, `.pq`) file without spaces in its path.                                                                                                                                                                                                          |
| `normalize` | Optional, `true` or `false` (default). Apply median-centric normalization to every dose-range group before fitting.                                                                                                                                                                                                                            |
| `metadata`  | Optional. `;`-separated columns of the well table to keep per dose series in the replicate-fits table (with `--replicate_fits`), for example `date;barcode`. Every column of the well table that is neither a [well table column](#well-table) nor listed here makes drevalpy fail, so list every extra column here or drop it from the table. |

An [example samplesheet](../assets/samplesheet.csv) has been provided with the pipeline.

### Well table

Each `wells` file has one row per well:

| Column          | Description                                                                                                             |
| --------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `sample`        | Required. Name of the cell line or other sample.                                                                        |
| `drug`          | Required. Name or identifier of the drug.                                                                               |
| `concentration` | Required. Drug concentration in µM.                                                                                     |
| `intensity`     | Required. Viability relative to the untreated control (1 = no effect).                                                  |
| `experiment`    | Optional. Biological replicate (e.g. the day or batch of the screen) the well belongs to.                               |
| `replicate`     | Optional. Technical replicate (e.g. the plate) within the experiment; together they identify the dose series of a well. |
| `position`      | Optional. Position of the well on its plate.                                                                            |

Any other column has to be listed in the `metadata` column of the samplesheet. For example:

```csv title="wells.csv"
sample,drug,concentration,intensity,experiment,replicate,plate_date
CL_A,DrugX,0.001,0.9999,day1,P1,2020-01-01
CL_A,DrugX,0.01,1.0034,day1,P1,2020-01-01
CL_A,DrugX,0.1,0.9206,day1,P1,2020-01-01
```

## Pipeline parameters

Besides `--input` and `--outdir`, the parameters `--replicate_fits`, `--min_doses`, `--fit_speed` and `--max_chunk_size` control how the curves are fitted, the same for every screen of a run. They are documented in the [parameter schema](../nextflow_schema.json); run `nextflow run drevalpy/curate --help` to list them. Use `--fit_speed exhaustive` (the default) for published results.

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run drevalpy/curate --input ./samplesheet.csv --outdir ./results  -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/running/run-pipelines#configuring-pipelines), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run drevalpy/curate -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: './samplesheet.csv'
outdir: './results/'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull drevalpy/curate
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [drevalpy/curate releases page](https://github.com/drevalpy/curate/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer) - see below.

> [!IMPORTANT]
> Every process runs in the `ghcr.io/drevalpy/curate:<version>` container, so use one of the container profiles. The pipeline has no Conda environments.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect `drevalpy` to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Fits two tiny screens, one with replicates, from the test data on GitHub, so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://charliecloud.io/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

In this pipeline, a fitted chunk is cached by the content of the chunk file: its curves and their fit options. When the well table of a screen changes, the screen is planned again, but only the chunks whose curves changed are fitted again. For example, after fixing one well of a large screen, one chunk is refitted and every other chunk is reused. Changing a fitting option such as `--fit_speed` or the `normalize` column of a screen refits the chunks it changes; changing `--max_chunk_size` cuts the curves into different chunks and refits all of them, even though the result does not depend on it.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#set-max-resources) and [customise process resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#customize-process-resources) section of the nf-core website.

### Custom Containers

Every process runs in the `ghcr.io/drevalpy/curate:<version>` container, built from the [`Dockerfile`](../Dockerfile) of the pipeline against the drevalpy ref pinned there as `DREVALPY_REF`. To run another drevalpy version, build the image against another drevalpy ref, given as the build argument `DREVALPY_REF` (a tag, branch or commit of daisybio/drevalpy):

```bash
docker build --build-arg DREVALPY_REF=<ref> -t my-registry/curate:dev .
```

and point the processes to it in a config file passed with `-c`:

```groovy
process.container = 'my-registry/curate:dev'
```

The fits of the same curves are only reproducible with the same drevalpy and CurveCurator versions, which `pipeline_info/curate_software_versions.yml` records.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#modifying-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running on a cluster or in the cloud

Every chunk is a single-core task with little memory, so the pipeline scales out to as many nodes as the executor gives it. Put the executor settings into a config file and pass it with `-c`, together with `-resume` so that an interrupted run continues where it stopped. On SLURM:

```groovy title="slurm.config"
process {
    executor       = 'slurm'
    queue          = 'normal'
    clusterOptions = '--account=my-account'
}
executor {
    queueSize       = 500
    submitRateLimit = '10/1s'
}
```

```bash
nextflow run drevalpy/curate -r <version> -profile singularity -c slurm.config --input samplesheet.csv --outdir results -resume
```

On AWS Batch, the work directory has to be on S3. The container holds only drevalpy, so Nextflow stages task files either with the AWS CLI of the compute environment's AMI (`aws.batch.cliPath`) or with [Fusion](https://www.nextflow.io/docs/latest/fusion.html) (`fusion.enabled = true`, `wave.enabled = true`):

```groovy title="awsbatch.config"
process {
    executor = 'awsbatch'
    queue    = 'my-batch-queue'
}
aws.region = 'eu-central-1'
workDir    = 's3://my-bucket/curate/work'
```

```bash
nextflow run drevalpy/curate -r <version> -profile docker -c awsbatch.config --input samplesheet.csv --outdir s3://my-bucket/curate/results -resume
```

A chunk fit that runs out of memory or time is retried with twice the memory and time, then three and four times; planning and collecting a screen, which hold the whole screen in memory, are retried with twice and three times. The time a chunk takes grows with `--max_chunk_size` and `--fit_speed`; lower `--max_chunk_size` for more, shorter tasks.

### Reproducibility across nodes

OpenBLAS picks its numerical kernels from the CPU it runs on, and curve fits differ between kernels by up to 0.1 pEC50, for example between Intel and AMD nodes of one cluster. The pipeline therefore sets `OPENBLAS_CORETYPE=Haswell`, a kernel every x86-64 CPU with AVX2 supports, and runs every task single-threaded (`OPENBLAS_NUM_THREADS`, `OMP_NUM_THREADS`, `MKL_NUM_THREADS` = 1). The same curves then give the same fits on any such node, so a mixed cluster, or a `-resume` on another machine, gives one answer. The nodes therefore need an x86-64 CPU with AVX2; ARM nodes are not covered.

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
