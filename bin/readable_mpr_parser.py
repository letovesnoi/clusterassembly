import os

import time


def write_pathes_from_spades_readable_mpr(readable_mpr, outdir, min_path_size=2):
    start = time.time()
    base = os.path.basename(readable_mpr)
    name = os.path.splitext(base)[0]
    fpathes = os.path.join(outdir, name + '.tsv')
    fout = open(fpathes, 'w')
    with open(readable_mpr, 'r') as fin:
        line = fin.readline()
        while line:
            line = fin.readline()
            if line.strip():
                fields = line.strip().split()
                path = fields[4:]
                if len(path) >= min_path_size:
                    fout.write(",".join(path) + '\n')
            else:
                fin.readline().strip()
    fout.close()
    end = time.time()
    # print('Elapsed time on long reads graph construction: {}'.format((end - start) * 1.0 / 60 / 60))
    return fpathes

