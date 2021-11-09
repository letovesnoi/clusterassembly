#!/usr/bin/env python

# TODO nf-core: Update the script to check the samplesheet
# This script is based on the example at: https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/samplesheet/samplesheet_test_illumina_amplicon.csv

import os
import sys
import errno
import argparse

data_types = ["short_reads", "long_reads", "db_seq"]

def parse_args(args=None):
    Description = "Reformat nf-core/clusterassembly samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check samplesheet -> {}".format(error)
    if context != "" and context_str != "":
        error_str = "ERROR: Please check samplesheet -> {}\n{}: '{}'".format(
            error, context.strip(), context_str.strip()
        )
    print(error_str)
    sys.exit(1)


def check_file_ext(path, line, extensions):
    if path:
        if path.find(" ") != -1:
            print_error("Path contains spaces!", "Line", line)
        err_ext = True
        for ext in extensions:
            if path.endswith(".{}.gz".format(ext)):
                err_ext = False
                break
        if err_ext:
            print_error(
                "File does not have extension '." + ".gz' or '.".join(extensions) + ".gz'!",
                "Line",
                line,
            )

def get_sample_info(sample, type, reads_1, reads_2):
    ## Create sample mapping dictionary = { sample: [ type, single_end, reads_1, reads_2 ] }
    if sample and reads_1 and reads_2 and type == data_types[0]:  ## Paired-end short reads
        return [type, "0", reads_1, reads_2]
    elif sample and reads_1 and not reads_2:  ## Long or short single-end sequences (reads or transcripts)
        return [type, "1", reads_1]
    else:
        print_error("Invalid combination of columns provided!", "Line", line)


# TODO nf-core: Update the check_samplesheet function
def check_samplesheet(file_in, file_out):
    """
    This function checks that the samplesheet follows the following structure:

    sample,type,reads_1,reads_2
    SAMPLE_1,short_reads,SAMPLE_PE_RUN1_1.fastq.gz,SAMPLE_PE_RUN1_2.fastq.gz
    SAMPLE_1,long_reads,SAMPLE_1_ISOSEQ.fasta.gz,
    SAMPLE_1,db_seq,TRANSCRIPTS_1.fa.gz,
    SAMPLE_2,short_reads,SAMPLE_PE_RUN2_1.fastq.gz,SAMPLE_PE_RUN2_2.fastq.gz
    SAMPLE_2,long_reads,SAMPLE_2_ONT.fasta.gz,
    SAMPLE_2,long_reads,SAMPLE_2_PACBIO.fasta.gz,
    SAMPLE_2,db_seq,TRANSCRIPTS_2.fa.gz,


    For an example see:
    https://raw.githubusercontent.com/letovesnoi/test-datasets/clusterassembly/samplesheet.csv
    """

    sample_mapping_dict = {}
    with open(file_in, "r") as fin:

        ## Check header
        MIN_COLS = 3
        # TODO nf-core: Update the column names for the input samplesheet
        HEADER = ["sample", "type", "reads_1", "reads_2"]
        header = [x.strip('"') for x in fin.readline().strip().split(",")]
        if header[: len(HEADER)] != HEADER:
            print("ERROR: Please check samplesheet header -> {} != {}".format(",".join(header), ",".join(HEADER)))
            sys.exit(1)

        ## Check sample entries
        for line in fin:
            lspl = [x.strip().strip('"') for x in line.strip().split(",")]

            # Check valid number of columns per row
            if len(lspl) < len(HEADER):
                print_error(
                    "Invalid number of columns (minimum = {})!".format(len(HEADER)),
                    "Line",
                    line,
                )
            num_cols = len([x for x in lspl if x])
            if num_cols < MIN_COLS:
                print_error(
                    "Invalid number of populated columns (minimum = {})!".format(MIN_COLS),
                    "Line",
                    line,
                )

            ## Check sample name entries
            sample, type, reads_1, reads_2 = lspl[: len(HEADER)]
            sample = sample.replace(" ", "_")
            if not sample:
                print_error("Sample entry has not been specified!", "Line", line)

            ## Check reads type
            if type not in data_types:
                print_error(
                    "Invalid type of data. Please use one of the following: {}.".
                        format(", ".join(data_types)),
                    "Line",
                    line,
                )
            ## Check file extensions
            for reads in [reads_1, reads_2]:
                if type == data_types[0]:  ## "short_reads"
                    check_file_ext(reads, line, ['fastq', 'fq'])
                else:  ## "long_reads", "db_seq"
                    check_file_ext(reads, line, ['fasta', 'fa', 'fastq', 'fq'])

            ## sample_info = [ type, single_end, reads_1, reads_2 ]
            sample_info = get_sample_info(sample, type, reads_1, reads_2)
            if sample not in sample_mapping_dict:
                sample_mapping_dict[sample] = [sample_info]
            else:
                if sample_info in sample_mapping_dict[sample]:
                    print_error("Samplesheet contains duplicate rows!", "Line", line)
                else:
                    sample_mapping_dict[sample].append(sample_info)

    ## Write validated samplesheet with appropriate columns
    if len(sample_mapping_dict) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(",".join(["sample", "type", "single_end", "reads_1", "reads_2"]) + "\n")
            for sample in sorted(sample_mapping_dict.keys()):

                ## Check that multiple runs of the same sample are of the same datatype
                # if not all(x[0] == sample_mapping_dict[sample][0][0] for x in sample_mapping_dict[sample]):
                #     print_error("Multiple runs of a sample must be of the same datatype!", "Sample: {}".format(sample))

                for idx, val in enumerate(sample_mapping_dict[sample]):
                    fout.write(",".join(["{}_T{}".format(sample, idx + 1)] + val) + "\n")
    else:
        print_error("No entries to process!", "Samplesheet: {}".format(file_in))


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
