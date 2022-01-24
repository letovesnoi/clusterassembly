# gfa_parser.py assembly_graph_with_scaffolds.gfa graph_pack.grseq outdir

import sys, os

import scipy as sp
import pandas as pd

import networkx as nx

from Bio.Seq import reverse_complement

import graphs


def get_one_type_gfa(gfa, type, outdir):
    one_type_gfa = os.path.join(outdir, '{}.gfa'.format(type))
    os.system('grep \'^{}\' {} > {}'.format(type, gfa, one_type_gfa))
    return one_type_gfa

# 'RecordType', 'PathName', 'SegmentNames', 'Overlaps'
def one_type_gfa_to_df(one_type_gfa):
    p_df = pd.read_csv(one_type_gfa,
                       sep="\t", header=None, usecols=[1, 2],
                       names=['PathName', 'SegmentNames'])
    return p_df

def line_to_node(line):
    fields = line.strip().split()
    name = fields[1]
    attr = {'seq': fields[2]}
    if 'KC:i:' in line:
        kmer_count = int(fields[3][5:])
        attr['KC'] = kmer_count
    return name, attr

# L       934049  -       36137   +       49M
def line_to_edge(line, conj_dict):
    fields = line.strip().split()
    u = fields[1]
    if fields[2] == '-':
        u = conj_dict[u]
    v = fields[3]
    if fields[4] == '-':
        v = conj_dict[v]
    attr = {'cigar': fields[5]}
    return u, v, attr

def gfa_to_G(gfa, conj_dict, kmer_size):
    # G = nx.DiGraph(k=kmer_size, name='gfa')
    G = nx.OrderedGraph(k=kmer_size, name='gfa')
    with open(gfa, 'r') as fin:
        for line in fin:
            record_type = line[0]
            if record_type in ['#', 'H', 'C', 'P']:
                continue
            elif record_type == 'S':
                name, attr = line_to_node(line)
                G.add_node(name,
                           seq=attr['seq'],
                           cov=attr['KC'] * 1.0 / len(attr['seq']),
                           len=len(attr['seq']),
                           A=attr['seq'].count('A') * 1.0 / len(attr['seq']),
                           C=attr['seq'].count('C') * 1.0 / len(attr['seq']),
                           G=attr['seq'].count('G') * 1.0 / len(attr['seq']),
                           T=attr['seq'].count('T') * 1.0 / len(attr['seq']))
                G.add_node(conj_dict[name],
                           seq=reverse_complement(attr['seq']),
                           cov=attr['KC'] * 1.0 / len(attr['seq']),
                           len=len(attr['seq']),
                           A=attr['seq'].count('T') * 1.0 / len(attr['seq']),
                           C=attr['seq'].count('G') * 1.0 / len(attr['seq']),
                           G=attr['seq'].count('C') * 1.0 / len(attr['seq']),
                           T=attr['seq'].count('A') * 1.0 / len(attr['seq']))
            elif record_type == 'L':
                # cov = nx.get_node_attributes(G, 'cov')

                u, v, attr = line_to_edge(line, conj_dict)
                G.add_edge(u, v, **attr)
                nx.set_edge_attributes(G, {(u, v): {'reads_and_db': 0.05 + 0.05}})

                G.add_edge(conj_dict[v], conj_dict[u], **attr)
                nx.set_edge_attributes(G, {(conj_dict[v], conj_dict[u]): {'reads_and_db': 0.05 + 0.05}})
    # graphs.write_G_statistics(G)
    return G


def main():
    # SPAdes output
    gfa = sys.argv[1]
    # SPAligner output
    grseq = sys.argv[2]
    # kmer size for graph construction
    k = int(sys.argv[3])
    outdir = sys.argv[4]

    # Get graph from gfa file
    G = gfa_to_G(outdir, gfa, grseq, k)

    # Get Adjacency matrix
    # A = graphs.get_A(G)

    # Get feature matrix
    # features_tsv = os.path.join(outdir, 'features.tsv')
    # X = graphs.get_X(G.nodes, features_tsv)


if __name__ == '__main__':
    main()
