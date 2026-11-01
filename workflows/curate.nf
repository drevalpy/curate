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
    wells  // channel: path(wells), the screen's well table
    outdir

    main:

    def ch_versions = channel.empty()

    //
    // MODULE: Split the screen into chunks of curves
    //
    DREVALPY_CURATEPLAN (
        wells
    )

    //
    // MODULE: Fit every chunk as its own task
    //
    DREVALPY_CURATEFITCHUNK (
        DREVALPY_CURATEPLAN.out.chunks.flatten()
    )

    //
    // MODULE: Assemble the fitted chunks into the curve AnnData
    //
    DREVALPY_CURATECOLLECT (
        DREVALPY_CURATEPLAN.out.plan,
        DREVALPY_CURATEFITCHUNK.out.fitted.collect().ifEmpty([])
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
    curves         = DREVALPY_CURATECOLLECT.out.curves // channel: path(h5ad)
    versions       = ch_versions                       // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
