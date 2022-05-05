import hashlib
import struct
from datetime import datetime
import math
import random
import json
import itertools
import graphviz
import sys
sys.setrecursionlimit(20000)


def StrToCover(a, limit, weights=False):
	x = []
	xc = []
	counter = 0
	for i in a:
		cost = 0
		if (weights and weights[i]):
			cost = weights[i]
		elif (weights):
			cost = len(x) #len(x) cost so high it won't affect the cover object
		string = str(int(bin(ord(i))[2:]))
		for i in range(0, 8-len(string)):
			string = "0"+string
		for i in range(0, len(string)):
			if (not counter < limit):
				return (x, xc)	
			else:
				counter += 1
			x.append(int(string[i]))
			xc.append(cost)
	return (x, xc)


useGraphviz = 0 #Optional trellis rendering via Graphviz
if (useGraphviz):
	dot = graphviz.Digraph("mainGraph", strict=True, graph_attr={"rankdir": "LR"}) #Graphviz initilization.
# subH = [[1,0,1,1,0,1,0,1,1,1,1,1,1,0,0,1],[1,1,0,0,0,1,1,1,1,0,0,1,0,0,1,1]] # chosen randomly atm but h is height and w is width.
subH = [[],[],[]] #subH is a template for the subH generated randomly below
h = len(subH) #The height of the matrx, concerns the performance of the code.
m = [0,1,1,1] #Your message to encode.
f = open("input.txt", "r")
string = f.read()
coverlength = 1024
(x, xc) = StrToCover(string, coverlength)
w = int(len(x) / len(m)) #This is the rate of the code. This is also the width of the matrix.
#Generate random subH
for i in range(0, h):
	for ii in range(0, w):
		subH[i].append(random.getrandbits(1))
assert(w == len(subH[0])) #Assertation of the above.


#UTILS
def addEdge(edges, fromNode, toNode, output, cost=3):
	edge = {"from": fromNode, "to": toNode, "output": output, "cost": cost}
	edges.append(edge)

def xor(a, b):
	result = []
	for i in range(0, len(a)):
		result.append((a[i]+b[i])%2)
	return result

def MatrixMulti(H, e):
	result = []
	for i in range(0, len(H)):
		subbit = 0
		for x in range(0, len(H[i])):
			subbit = (subbit + (H[i][x]*e[x])) % 2
		result.append(subbit)
	return result

def toNode(node):
	result = []
	def filterfun(edge):
			if edge["to"] == node["name"]:
				return True
			else:
				return False
	for i in filter(filterfun, edges):
		result.append(i)
	return result

def getNodeByName(name):
	for n in range(0, len(nodes)):
		for node in nodes[n]:
			if (node["name"] == name):
				return node

def findState(news, i):
	if (i <= len(news)-h):
		state = news[(i):(i+h)]
	else:
		state = news[(i):len(news)]
		for ii in range(0, h-len(state)):
			state.append(0)
	state.reverse()
	statestr = ""
	for ii in range(0, len(state)):
		statestr += str(state[ii])
	state = statestr
	newbit = int(state, 2)
	return newbit



def bulidH():
	height = len(m)
	width = height*w #len(x)
	H = []
	for i in range(0, height):
		Hi = []
		for ii in range(0, width):
			Hi.append(0)
		H.append(Hi)
	row = 0
	column = 0
	for i in range(0, int(len(x)/w)):
		for ii in range(0, h):
			for y in range(0, w):
				if (row+ii >= height) or (column+y >= width):
					break
				H[row+ii][column+y] = subH[ii][y]
		row = row+1
		column = column+w
	CH = []
	for i in range(0, len(H[0])):
		CH.append([])
	for i in range(0, len(H)):
		for ii in range(0, len(H[i])):
			CH[ii].append(H[i][ii])
	return (H, CH)

(H, CH) = bulidH() #Assemble the parity check matrix from subH


def genNodes(): 
	trellisHeight = 2**h # the number of nodes per column
	trellisWidth = int((w+1)*len(m)) # the number of columns +1 for prune column.
	trellisNodes = []
	trellisNodes.append(1)
	for i in range(1, trellisWidth+1):
		trellisNodes.append(trellisHeight)
	maxheight = 0
	nodes = []
	for n in range(0, len(trellisNodes)):
		if maxheight < trellisNodes[n]:
			maxheight = trellisNodes[n]
		nslice = []
		for i in range(0, trellisNodes[n]):
			node = {"name": str(n)+str(i), "cost": 0}
			nslice.append(node)
		nodes.append(nslice)
	return (nodes, maxheight)

(nodes, maxheight) = genNodes() #Generate an array of arrays for each set of nodes for each time slice

def genEdges(nodes):
	#Initialize varibles
	originNode = "" 
	edges = [] #edges of trellis
	s = [] #empty syndrom of len(m)
	for i in range(0, len(m)):
		s.append(0)
	startNodes = [(0,0,s)] #At each iter these are the nodes to start from

	for i in range(0, len(m)): #run once per bit of message
		for ii in range(0, w): #run w where w = len(x)/w = len(m)
			index = (i*w)+ii
			coverbit = x[index] #The bit of the cover object we are currently using
			cost0 = coverbit #The cost 0 or 1 that we get if we don't add the (i*w)+ii column of H to the syndrom
			cost1 = 1 #The oposite of above
			if (coverbit):
				cost1 = 0
			newNodes = []
			for iii in range(0, len(startNodes)): #Loop through each of the starting nodes

				node = (startNodes[iii][0]+1,startNodes[iii][1], startNodes[iii][2])
				if (not node in newNodes):
					newNodes.append(node)
				addEdge(edges, str(startNodes[iii][0])+str(startNodes[iii][1]), str(startNodes[iii][0]+1)+str(startNodes[iii][1]), 0, cost0) #Add the edge equivlent of not adding the ith column of H to the syndrom

				news = xor(startNodes[iii][2], CH[index]) #Compute the current syndrom + the index column of H
				newbit = findState(news, i) #Find the corisponding trellis state of the new syndrom
				node = (startNodes[iii][0]+1, newbit, news)
				if (not node in newNodes): #Confirm this is not a duplicate path
					add = 1
					for iiii in range(0, len(newNodes)):
						if (findState(newNodes[iiii][2], i) == newbit): #A more indepth check for duplicates
							add = 0
					if (add):
						newNodes.append(node)
				addEdge(edges, str(startNodes[iii][0])+str(startNodes[iii][1]), str(startNodes[iii][0]+1)+str(newbit), 1, cost1) #Add the edge equvilent to adding the ith column of H to the syndrom

			startNodes = newNodes
		newStartNodes = []
		for ii in range(0, len(startNodes)):
			if (startNodes[ii][2][i] == m[i]): #Prune our current list of starting nodes before the next run by matching the message bit that will be unchangable after this point
				news = startNodes[ii][2] #Get the syndrom assoisated with this node
				newbit = findState(news, i+1) #Find the new state based on the next index.
				node = (startNodes[ii][0]+1, newbit, news)
				if (not node in newStartNodes): #Don't append a duplicate start node caused by not changing the syndrom even after adding a column of H
					newStartNodes.append(node)
				addEdge(edges, str(startNodes[ii][0])+str(startNodes[ii][1]), str(startNodes[ii][0]+1)+str(newbit), 2, 0) #Add edges for the prune nodes that shift the state based on new important bits
		startNodes = newStartNodes
	originNode = getNodeByName(str(newStartNodes[0][0])+str(newStartNodes[0][1])) #Get the furthest node from the start
	return (edges, originNode)

(edges, originNode) = genEdges(nodes) #Generate the edges between the nodes.

def forwardPass():
	for n in range(1, len(nodes)):
		Nnodes = nodes[n]
		for i in range(0, len(Nnodes)):
			node = Nnodes[i]
			print(node)
			paths = toNode(node)
			costs = []
			for path in paths:
				sourceNode = getNodeByName(path["from"])
				totalPathCost = sourceNode["cost"] + path['cost']
				costs.append(totalPathCost)
			if (len(costs) > 0):
				mincost = costs[0]
				for cost in costs:
					if cost < mincost:
						mincost = cost
				node['cost'] = mincost

forwardPass()

def minPath(originNode, output):
	paths = toNode(originNode)
	nodepaths = []
	for path in paths:
		nodepaths.append([getNodeByName(path['from']),path])
	minNode = nodepaths[0]
	for node in nodepaths:
		if node[0]['cost']+node[1]['cost'] < minNode[0]['cost']+minNode[1]['cost']:
			minNode = node 
	if (useGraphviz):
		dot.edge(minNode[0]['name'], originNode['name'], color='red')
	if (toNode(minNode[0])):
		print(minNode[0])
		return minPath(minNode[0], output+str(minNode[1]['output']))
	else: 
		minimumPath = list(filter(lambda x : x != '2' , (output+str(minNode[1]['output']))[::-1])) 
		result = []
		for i in range(0, len(minimumPath)):
			result.append(int(minimumPath[i]))
		return (result, minimumPath)
(result, strresult) = minPath(originNode, "") # Backwards pass of the vertui algorithim

def render():
	subGraph = graphviz.Digraph("cluster0", strict=False, graph_attr={"label": "0"})
	subGraph.node(nodes[0][0]['name'], label=(nodes[0][0]['name']+" cost: "+str(nodes[0][0]['cost'])))
	dot.subgraph(subGraph)
	prune = 0
	for n in range(1, len(nodes)):
		if (n%(w+1) == 0):
			prune += 1
			name = "prunenode "+str(int(n/(w+1)))
		else:
			name = str(n-prune)
		subGraph = graphviz.Digraph("cluster"+name, strict=False, graph_attr={"label": name})
		Nnodes = nodes[n]
		for i in range(0, len(Nnodes)):
			node = Nnodes[i]
			subGraph.node(node['name'], label=node['name']+" cost: "+str(node['cost']))
		dot.subgraph(subGraph)
	for edge in edges:
		dot.edge(edge['from'], edge['to'], xlabel=str(edge['output'])+" = "+str(edge['cost'])[:5], rank="same")
	dot.render('doctest-output/trellis.gv').replace('\\', '/')
	dot.render('doctest-output/trellis.gv', view=True) 

assert(MatrixMulti(H, result) == m)

def bits2a(b):
	result = ""
	for i in range(0,int(len(b)/8)):
		byte = ''.join(b[i*8:(i+1)*8])
		result += chr(int(byte, 2))
	return result

print(bits2a(strresult))
print(string[:int(coverlength/8)])
# strx = ""
# for i in range(0, len(x)):
# 	strx += str(x[i])
# print(strx)
# print(''.join(strresult))



if (useGraphviz):
	render() #Optional grahpviz rendering




