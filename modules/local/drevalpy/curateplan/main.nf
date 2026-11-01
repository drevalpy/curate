process DREVALPY_CURATEPLAN {
    tag "${meta.id}"
    label 'process_single'
    label 'process_drevalpy_whole_screen'

    container "ghcr.io/drevalpy/curate:${workflow.manifest.version}"

    input:
    tuple val(meta), path(wells)

    output:
    tuple val(meta), path("plan")                          , emit: plan
    tuple val(meta), path("plan/chunks/*.parquet")         , emit: chunks, optional: true
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/^drevalpy //'"), emit: versions_drevalpy, topic: versions
    tuple val("${task.process}"), val('curve-curator'), eval("python -c 'import importlib.metadata as m; print(m.version(\"curve-curator\"))'"), emit: versions_curvecurator, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    drevalpy curate plan \\
        ${wells} \\
        plan \\
        ${args}
    """

    stub:
    """
    mkdir -p plan/chunks
    touch plan/plan.json plan/series.parquet plan/chunks/pooled-00000.parquet
    """
}
