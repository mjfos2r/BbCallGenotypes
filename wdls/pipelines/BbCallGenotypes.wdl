version 1.0
# Michael J. Foster

import "../workflows/BbCallOspC.wdl" as OSPC
import "../workflows/BbCallPlasmids.wdl" as PC
import "../workflows/BbCallRST.wdl" as RST
import "../workflows/BbCallMLST.wdl" as MLST


workflow BbCallGenotypes {

    meta {
        author: "Michael J. Foster"
        description: "call RST, OspC, MLST, and Plasmids for a given input assembly"
    }
    parameter_meta {
        reads: "description of input"
        reference: "reference genome to align against"
        prefix: "prefix to use in naming output file. use sample_id."
        map_preset: "[ Default: -x map-ont ] preset for minimap2"
    }

    input {
        File input_contigs
        String sample_id
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
            input_fa = BbCallPlasmids.BbCP_renamed_contigs
    }
    # using the renamed contigs, call RST
    call RST.BbCallRST {
        input:
            sample_id = sample_id,
            input_fa = BbCallPlasmids.BbCP_renamed_contigs
    }
    call MLST.BbCallMLST {
        input:
            input_asm = BbCallPlasmids.BbCP_renamed_contigs,
    }

    output {
        # Plasmid Calls
        File gt_BbCP_renamed_contigs = BbCallPlasmids.BbCP_renamed_contigs
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
        File gt_mlst_check_data = BbCallMLST.mlst_check_data
        File gt_mlst_results_allele = BbCallMLST.mlst_results_allele
        File gt_mlst_results_genomic = BbCallMLST.mlst_results_genomic
        Array[File] gt_mlst_results_unknown = BbCallMLST.mlst_results_unknown
        File gt_mlst_concatenated_alleles_fa = BbCallMLST.mlst_concatenated_alleles_fa
        File gt_mlst_concatenated_alleles_phylip = BbCallMLST.mlst_concatenated_alleles_phylip
        String gt_mlst_st = BbCallMLST.mlst_st
        String gt_mlst_st_new = BbCallMLST.mlst_st_new
        # tool versions
        File gt_BbCP_caller_version = BbCallPlasmids.BbCP_version
        File gt_ospC_caller_version = BbCallOspC.ospC_version
        File gt_RST_caller_version = BbCallRST.RST_version
        File gt_MLST_check_version = BbCallMLST.version
    }
}
