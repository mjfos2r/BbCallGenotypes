version 1.0
# Michael J. Foster

import "../workflows/BbCallOspC.wdl" as OSPC
import "../workflows/BbCallPlasmids.wdl" as PC
import "../workflows/BbCallRST.wdl" as RST
import "../workflows/CallMLST.wdl" as MLST


workflow BbCallGenotypes {

    meta {
        author: "Michael J. Foster"
        description: "call RST, OspC, MLST, and Plasmids for a given input assembly"
    }
    parameter_meta {
        reads: "description of input"
        sample_id: "sample_id"
        species: "Species to use for mlst classification"
    }

    input {
        File input_contigs
        String sample_id
        String species = 'Borrelia'
    }

    # call plasmids first so we can use the renamed contigs downstream.
    call PC.BbCallPlasmids {
        input:
            sample_id = sample_id,
            input_fa = input_contigs
    }

    # using the renamed contigs, call ospC
    call OSPC.BbCallOspC {
        input:
            sample_id = sample_id,
            input_fa = input_contigs#BbCallPlasmids.BbCP_renamed_contigs
    }
    # using the renamed contigs, call RST
    call RST.BbCallRST {
        input:
            sample_id = sample_id,
            input_fa = input_contigs#BbCallPlasmids.BbCP_renamed_contigs
    }
    call MLST.CallMLST {
        input:
            input_asm = input_contigs,#BbCallPlasmids.BbCP_renamed_contigs,
            species = species
    }

    output {
        # Plasmid Calls
        #File gt_BbCP_renamed_contigs = BbCallPlasmids.BbCP_renamed_contigs
        File gt_BbCP_pf32_hits = BbCallPlasmids.BbCP_pf32_hits
        File gt_BbCP_wp_hits = BbCallPlasmids.BbCP_wp_hits
        File gt_BbCP_best_hits_json = BbCallPlasmids.BbCP_best_hits_json
        File gt_BbCP_best_hits_tsv = BbCallPlasmids.BbCP_best_hits_tsv
        # OspC Calls
        File gt_ospC_all_hits_tsv = BbCallOspC.ospC_all_hits_tsv
        File gt_ospC_best_hits_tsv = BbCallOspC.ospC_best_hits_tsv
        File gt_ospC_contam_hits_tsv = BbCallOspC.ospC_contam_hits_tsv
        File gt_ospC_raw_hits_xml = BbCallOspC.ospC_raw_hits_xml
        String gt_ospC_type = BbCallOspC.ospC_type
        # RST Calls
        String gt_RST_type = BbCallRST.RST_type
        File gt_RST_amplicon = BbCallRST.RST_amplicon
        File gt_RST_fragments = BbCallRST.RST_fragments
        # MLST Check output
        File gt_mlst_check_data = CallMLST.mlst_check_data
        File gt_mlst_results_allele = CallMLST.mlst_results_allele
        File gt_mlst_results_genomic = CallMLST.mlst_results_genomic
        Array[File] gt_mlst_results_unknown = CallMLST.mlst_results_unknown
        File gt_mlst_concatenated_alleles_fa = CallMLST.mlst_concatenated_alleles_fa
        File gt_mlst_concatenated_alleles_phylip = CallMLST.mlst_concatenated_alleles_phylip
        String gt_mlst_st = CallMLST.mlst_st
        String gt_mlst_st_new = CallMLST.mlst_st_new
        # tool versions
        File gt_BbCP_caller_version = BbCallPlasmids.BbCP_version
        File gt_ospC_caller_version = BbCallOspC.ospC_version
        File gt_RST_caller_version = BbCallRST.RST_version
        File gt_MLST_check_version = CallMLST.version
    }
}
