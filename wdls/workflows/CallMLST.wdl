version 1.0
import "../structs/Structs.wdl"

workflow CallMLST {

    meta {
        description: "Determine MLST via mlst_check from Sanger Pathogens."
    }
    parameter_meta {
        input_asm: "Input assembly to classify."
        species: "Target genus for mlst classification"
    }

    input {
        File input_asm
        String species = 'Borrelia'
    }

    call MLST_check {
        input:
            input_asm = input_asm,
            species = species
    }

    output {
        File mlst_check_data = MLST_check.mlst_check_data
        File mlst_results_allele =  MLST_check.mlst_results_allele
        File mlst_results_genomic =  MLST_check.mlst_results_genomic
        Array[File] mlst_results_unknown =  MLST_check.mlst_results_unknown
        File mlst_concatenated_alleles_fa =  MLST_check.mlst_concatenated_alleles_fa
        File mlst_concatenated_alleles_phylip =  MLST_check.mlst_concatenated_alleles_phylip
        String mlst_st = MLST_check.mlst_st
        String mlst_st_new = MLST_check.mlst_st_new
        File version = MLST_check.version
    }
}

task MLST_check {
    input {
        File input_asm
        String species
        RuntimeAttr? runtime_attr_override
    }
    Int disk_size = 50 + 10 * ceil(size(input_asm, "GB"))
    command <<<
        NPROCS=$(cat /proc/cpuinfo | awk '/^processor/{print}' | wc -l)
        mkdir -p mlst_check_output
        get_sequence_type -v > mlst_check_version.txt
        get_sequence_type -d "$NPROCS" -s '~{species}' -o mlst_check_output -c -y ~{input_asm}
        tar -zcvf mlst_check_output.tar.gz mlst_check_output/
        tail -n +2 mlst_check_output/mlst_results.allele.csv | cut -d'\t' -f2 > MLST_ST.txt
        tail -n +2 mlst_check_output/mlst_results.allele.csv | cut -d'\t' -f3 > MLST_ST_NEW.txt
    >>>

    output {
        File mlst_check_data = "mlst_check_output.tar.gz"
        File mlst_results_allele = "mlst_check_output/mlst_results.allele.csv"
        File mlst_results_genomic = "mlst_check_output/mlst_results.genomic.csv"
        Array[File] mlst_results_unknown = glob("mlst_check_output/*unknown.fa")
        File mlst_concatenated_alleles_fa = "mlst_check_output/concatenated_alleles.fa"
        File mlst_concatenated_alleles_phylip = "mlst_check_output/concatenated_alleles.phylip"
        String mlst_st = read_string("MLST_ST.txt")
        String mlst_st_new = read_string("MLST_ST_NEW.txt")
        File version = "mlst_check_version.txt"
    }
    #########################
    RuntimeAttr default_attr = object {
        cpu_cores:          4,
        mem_gb:             16,
        disk_gb:            disk_size,
        boot_disk_gb:       25,
        preemptible_tries:  0,
        max_retries:        0,
        docker:             "sangerpathogens/mlst_check:latest"
    }
    RuntimeAttr runtime_attr = select_first([runtime_attr_override, default_attr])
    runtime {
        cpu:                    select_first([runtime_attr.cpu_cores,         default_attr.cpu_cores])
        memory:                 select_first([runtime_attr.mem_gb,            default_attr.mem_gb]) + " GiB"
        disks: "local-disk " +  select_first([runtime_attr.disk_gb,           default_attr.disk_gb]) + " HDD"
        bootDiskSizeGb:         select_first([runtime_attr.boot_disk_gb,      default_attr.boot_disk_gb])
        preemptible:            select_first([runtime_attr.preemptible_tries, default_attr.preemptible_tries])
        maxRetries:             select_first([runtime_attr.max_retries,       default_attr.max_retries])
        docker:                 select_first([runtime_attr.docker,            default_attr.docker])
    }
}