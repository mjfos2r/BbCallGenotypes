version 1.0
# Michael J. Foster

import "../workflows/BbCallOspC.wdl" as OSPC
import "../workflows/BbCallPlasmids.wdl" as PC
import "../workflows/BbCallRST.wdl" as RST

workflow BbCallGenotypes {

    meta {
        author: "Michael J. Foster"
        description: "call RST, OspC, and Plasmids for a given input assembly"
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
    output {
        # Plasmid Calls
        File BbCP_renamed_contigs = BbCallPlasmids.BbCP_renamed_contigs
        File BbCP_pf32_hits = BbCallPlasmids.BbCP_pf32_hits
        File BbCP_wp_hits = BbCallPlasmids.BbCP_wp_hits
        File BbCP_best_hits_json = BbCallPlasmids.BbCP_best_hits_json
        File BbCP_best_hits_tsv = BbCallPlasmids.BbCP_best_hits_tsv
        # OspC Calls
        File ospC_all_hits_tsv = BbCallOspC.ospC_all_hits_tsv
        File ospC_best_hits_tsv = BbCallOspC.ospC_best_hits_tsv
        File ospC_contam_hits_tsv = BbCallOspC.ospC_contam_hits_tsv
        File ospC_raw_hits_xml = BbCallOspC.ospC_raw_hits_xml
        String ospC_type = BbCallOspC.ospC_type
        # RST Calls
        String RST_type = BbCallRST.RST_type
        File RST_amplicon = BbCallRST.RST_amplicon
        File RST_fragments = BbCallRST.RST_fragments
				#todo add definitions file as output
        # tool versions
        File BbCP_caller_version = BbCallPlasmids.BbCP_version
        File ospC_caller_version = BbCallOspC.ospC_version
        File RST_caller_version = BbCallRST.RST_version
    }
}
