#!/usr/bin/env python

from __future__ import print_function
import argparse, sys

__author__ = "David R. Powell"

def arguments():
    parser = argparse.ArgumentParser(description='Filter spades output file (scaffolds.fasta)')
    parser.add_argument('input', type=argparse.FileType('r'),
                        nargs='?', default='-',
                        help="Input fasta file (default stdin)")
    parser.add_argument('--cov', default=0, type=float,
                        help="Filter contigs with coverage less than this")
    parser.add_argument('--length', default=0, type=int,
                        help="Filter contigs with length less than this")
    parser.add_argument('--output', default=None, type=argparse.FileType('w'),
                        help="Output file.  Default is to just print summary")
    return parser

def process(args):
    keep=True
    l1=0
    lengths=[]
    if args.input == sys.stdin:
        print("Reading from stdin...", file=sys.stderr)
    for l in args.input:
        if l[0] == '>':
            parts = l.split('_')
            if parts[2]!='length' or parts[4]!='cov':
                raise RuntimeError("Invald syntax %s"%parts)
            keep = int(parts[3])>=args.length and float(parts[5])>=args.cov
            if keep:
                lengths.append(int(parts[3]))
        if keep and args.output:
            args.output.write(l)

    # Calculate N50
    tot = sum(lengths)
    s=0
    for l in sorted(lengths):
        s+=l
        if s>tot/2:
            n50 = l
            break

    info_out = sys.stderr if args.output else sys.stdout
    print("Num contigs : %d"%len(lengths), file=info_out)
    print("Total contig lengths : %d"%tot, file=info_out)
    print("Avg contig length : %.2f"%(1.0*tot/len(lengths)), file=info_out)
    print("N50 : %d"%n50, file=info_out)

if __name__ == '__main__':
    parser = arguments()
    args = parser.parse_args()
    process(args)
