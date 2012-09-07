import Dijkstra
import sys

def main(args = sys.argv):
    file = open(args[1],'r')
    ref_slice = args[2]
    G = {}
    # create the graph
    for line in file:
        words = line.split()
        if words[0] not in G:
            G[words[0]] = {words[1]:float(words[2])}
        else:
            G[words[0]][words[1]] = float(words[2])
        if words[1] not in G:
            G[words[1]] = {words[0]:float(words[2])}
        else:
            G[words[1]][words[0]] = float(words[2])
    (D,P) = Dijkstra.Dijkstra(G, ref_slice)
    for key in P.keys():
        print  key + ' ' + P[key] 
#        for word in words:
#            print word
    
if __name__ == "__main__":
    main()
