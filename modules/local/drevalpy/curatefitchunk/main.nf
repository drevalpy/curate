process DREVALPY_CURATEFITCHUNK {
    tag "${meta.id}:${chunk.baseName}"
    label 'process_single'
    label 'process_drevalpy_chunk'
    // A chunk file holds its curves and fit options and nothing else, so hashing its content
    // (rather than its path) lets -resume reuse every chunk a new plan did not change.
    cache 'deep'

    container "ghcr.io/drevalpy/curate:${workflow.manifest.version}"

    input:
    tuple val(meta), path(chunk)

    output:
    tuple val(meta), path("fitted/${chunk.name}"), emit: fitted
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/^drevalpy //'"), emit: versions_drevalpy, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir -p fitted
    drevalpy curate fit-chunk ${chunk} fitted/${chunk.name}
    """

    stub:
    """
    mkdir -p fitted
    touch fitted/${chunk.name}
    """
}
