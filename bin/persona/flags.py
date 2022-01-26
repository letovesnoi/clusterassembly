from absl import flags

import community

import networkx.algorithms.community.label_propagation as label_prop
import networkx.algorithms.community.modularity_max as modularity
import networkx.algorithms.components.connected as components
from networkx.algorithms.components import weakly_connected_components


# from {0: 0, 1: 0, 2: 0, 3: 0, 4: 1, 5: 1, 6: 1 ... }
# to [[0, 1, 2, 3], [4, 5, 6], ... ]
def clusters_dict_to_list(c_dict):
    c_list = []
    for cluster in set(c_dict.values()):
        c_list.append([nodes for nodes in c_dict.keys() if c_dict[nodes] == cluster])
    return c_list

def best_partition(G, weight='weight'):
    c_dict = community.best_partition(G, weight=weight)
    c_list = clusters_dict_to_list(c_dict)
    return c_list


_CLUSTERING_FN = {
    'label_prop': label_prop.label_propagation_communities,
    'modularity': modularity.greedy_modularity_communities,
    'connected_components': components.connected_components,
    'weakly_connected_components': weakly_connected_components,
    'best_partition': best_partition,
}

flags.DEFINE_string(
    'input_graph', None,
    'The input graph path as a text file containing one edge per row, as the '
    'two node ids u v of the edge separated by a whitespace. The graph is '
    'assumed to be undirected. For example the file:\n1 2\n2 3\n represents '
    'the triangle 1 2 3')

flags.DEFINE_string(
    'output_clustering', None,
    'output path for the overallping clustering. The clustering is output as a '
    'text file where each row is a cluster, represented as the space-separated '
    'list of its node ids.')

flags.DEFINE_enum(
    'local_clustering_method', 'label_prop', _CLUSTERING_FN.keys(),
    'The method used for clustering the egonets of the graph. The options are '
    '"label_prop", "modularity" or "connected_components".')

flags.DEFINE_enum(
    'global_clustering_method', 'label_prop', _CLUSTERING_FN.keys(),
    'The method used for clustering the persona graph. The options are '
    'label_prop, modularity or connected_components.')

flags.DEFINE_integer('min_cluster_size', 5,
                     'Minimum size for an overlapping cluster to be output.')

flags.DEFINE_string(
    'output_persona_graph', None,
    'If set, it outputs the persona graph in the same format of the input graph'
    ' (text file).')
flags.DEFINE_string(
    'output_persona_graph_mapping', None,
    'If set, outputs the mapping of persona graphs ids to original graph '
    'ids as a text file where each row represents a node and it has two '
    'space-separated columns. The first column is the persona node id, while '
    'the second column is the original node id')

FLAGS = flags.FLAGS
