/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { DREVALPY_CURATEPLAN     } from '../modules/local/drevalpy/curateplan'
include { DREVALPY_CURATEFITCHUNK } from '../modules/local/drevalpy/curatefitchunk'
include { DREVALPY_CURATECOLLECT  } from '../modules/local/drevalpy/curatecollect'
include { softwareVersionsToYAML  } from '../subworkflows/nf-core/utils_nfcore_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CURATE {

    take:
    ch_samplesheet // channel: [ val(meta), path(wells) ], one per screen
    outdir

    main:

    def ch_versions = channel.empty()

    //
    // MODULE: Split each screen into chunks of curves
    //
    DREVALPY_CURATEPLAN (
        ch_samplesheet
    )

    def ch_chunks = DREVALPY_CURATEPLAN.out.chunks
        .map { meta, chunks -> [ meta, chunks instanceof List ? chunks : [ chunks ] ] }

    //
    // MODULE: Fit every chunk as its own task. Only the screen id goes with the chunk, so a
    // changed per-screen option that leaves a chunk's content alone does not refit it.
    //
    DREVALPY_CURATEFITCHUNK (
        ch_chunks.flatMap { meta, chunks -> chunks.collect { chunk -> [ [ id: meta.id ], chunk ] } }
    )

    def ch_n_chunks = ch_chunks.map { meta, chunks -> [ meta.id, chunks.size() ] }
    def ch_fitted = DREVALPY_CURATEFITCHUNK.out.fitted
        .map { meta, fitted -> [ meta.id, fitted ] }
        .combine(ch_n_chunks, by: 0)
        .map { id, fitted, n_chunks -> [ groupKey(id, n_chunks), fitted ] }
        .groupTuple()
        .map { key, fitted -> [ key.getGroupTarget(), fitted ] }

    //
    // MODULE: Assemble the fitted chunks of each screen into its curve AnnData
    //
    def ch_collect = DREVALPY_CURATEPLAN.out.plan
        .map { meta, plan -> [ meta.id, meta, plan ] }
        .join(ch_fitted, remainder: true)
        .map { id, meta, plan, fitted -> [ meta, plan, fitted ?: [] ] }

    DREVALPY_CURATECOLLECT (
        ch_collect
    )

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:  'curate_software_versions.yml',
            sort: true,
            newLine: true
        )
    emit:
    curves         = DREVALPY_CURATECOLLECT.out.curves // channel: [ val(meta), path(h5ad) ]
    versions       = ch_versions                       // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
