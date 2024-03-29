# ![nf-core/clusterassembly](docs/images/nf-core-clusterassembly_logo.png)

[![GitHub Actions CI Status](https://github.com/nf-core/clusterassembly/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/clusterassembly/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/nf-core/clusterassembly/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/clusterassembly/actions?query=workflow%3A%22nf-core+linting%22)
[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/clusterassembly/results)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.04.0-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23clusterassembly-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/clusterassembly)
[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)
[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

<!-- TODO nf-core: Write a 1-2 sentence summary of what data the pipeline is for and what it does -->
**nf-core/clusterassembly** is a bioinformatics best-practice analysis pipeline for RNA-seq analysis combining different types of data by aligning them on assembly graph and using ML approaches for transcript identification and extensive quality control.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

<!-- TODO nf-core: Add full-sized test dataset and amend the paragraph below if applicable -->
On release, automated continuous integration tests run the pipeline on a full-sized dataset on the AWS cloud infrastructure. This ensures that the pipeline runs on AWS, has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources. The results obtained from the full-sized test can be viewed on the [nf-core website](https://nf-co.re/clusterassembly/results).

## Pipeline summary

<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

0. Merge FastQ files ([`cat`](http://www.linfo.org/cat.html))
1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. ASSEMBLY STEPS with [`rnaSPAdes`](https://github.com/ablab/spades)
    1. Short reads assembly
   2. Pathextend + Long-read paths
   3. Overlapping clustering algorithm based on [`Epasto et. al, 2019`](https://github.com/google-research/google-research/tree/master/graph_embedding/persona)
   4. Restart rnaSPAdes using pathextend utilizing clusters
3. QUALITY ASSESSMENT
    1. Clustering evaluation using isoform database: Jaccard similarity, recall and F1 score
   2. Assemblies evaluation
      1. rnaQUAST using reference genome and gene database ([`rnaQUAST`](https://github.com/ablab/rnaquast))
      2. Transcripts against protein database ([`Prodigal`](https://github.com/hyattpd/Prodigal), [`Diamond`](https://github.com/bbuchfink/diamond) / [`InterProScan`](https://www.ebi.ac.uk/interpro/search/sequence/))
4. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))

# ![nf-core/clusterassembly](docs/images/clusterassembly_pipeline.png)

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=21.04.0`)

2. Install [`Conda`](https://conda.io/miniconda.html); see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles).

3. Download the pipeline and test it on a minimal dataset with a single command:

    ```console
    nextflow run nf-core/clusterassembly -profile test,conda
    ```

It is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

4. Start running your own analysis!

    <!-- TODO nf-core: Update the example "typical command" below used to run the pipeline -->

    ```console
    nextflow run nf-core/clusterassembly -profile conda --input samplesheet.csv --genome GRCh37 --mgy peptide_database
    ```
   or
   ```console
    nextflow run nf-core/clusterassembly -profile conda --input samplesheet.csv --fasta GRCh37.fasta --gtf GRCh37.gtf --outdir OUTDIR --mgy peptide_database
    ```

## Documentation

The nf-core/clusterassembly pipeline comes with documentation about the pipeline [usage](https://nf-co.re/clusterassembly/usage), [parameters](https://nf-co.re/clusterassembly/parameters) and [output](https://nf-co.re/clusterassembly/output).

## Credits

nf-core/clusterassembly was originally written by letovesnoi.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#clusterassembly` channel](https://nfcore.slack.com/channels/clusterassembly) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  nf-core/clusterassembly for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->
An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
