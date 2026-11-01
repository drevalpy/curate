process DREVALPY_CURATECOLLECT {
    label 'process_single'
    label 'process_drevalpy_whole_screen'

    container "ghcr.io/drevalpy/curate:${workflow.manifest.version}"

    input:
    path(plan)
    path(fitted, stageAs: 'fitted/*')

    output:
    path("${prefix}.h5ad"), emit: curves
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/^drevalpy //'"), emit: versions_drevalpy, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "curves"
    """
    mkdir -p fitted
    drevalpy curate collect ${plan} fitted ${prefix}.h5ad
    """

    stub:
    prefix = task.ext.prefix ?: "curves"
    """
    touch ${prefix}.h5ad
    """
}
