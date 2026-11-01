process DREVALPY_CURATECOLLECT {
    tag "${meta.id}"
    label 'process_single'
    label 'process_drevalpy_whole_screen'

    container "ghcr.io/drevalpy/curate:${workflow.manifest.version}"

    input:
    tuple val(meta), path(plan), path(fitted, stageAs: 'fitted/*')

    output:
    tuple val(meta), path("${prefix}.h5ad"), emit: curves
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/^drevalpy //'"), emit: versions_drevalpy, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p fitted
    drevalpy curate collect ${plan} fitted ${prefix}.h5ad
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    """
}
