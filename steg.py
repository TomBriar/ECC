import hashlib
import struct
from datetime import datetime
import math
import json
import itertools
import graphviz

dot = graphviz.Digraph("mainGraph", strict=True, graph_attr={"rankdir": "LR"})
subH = [[1,0,1,1,0,1,0,1,1,1,1,1,1,0,0,1],[1,1,0,0,0,1,1,1,1,0,0,1,0,0,1,1]] # chosen randomly atm but h is height and w is width.
h = len(subH) #the number of bits handled per mini trellis or block
m = [0,1] #must  divide h
assert(len(m) == h)
x = [1,0,1,1,0,0,0,1,1,0,1,1,0,0,0,1,1,0,1,1,0,0,0,1,1,0,1,1,0,0,0,1] #cover object
w = int(len(x) / len(m)) #Keep this number an intager for simplicity 
# assert(w < len(m))
assert(w == len(subH[0])) #w is width of subH as well as the rate of the code.
b = int(len(x)/w) # number of copies of subH in H


s = []
for i in range(0, len(m)):
	s.append(0)
trellisHeight = 2**h
trellisWidth = int((w+1)*len(m))
trellisNodes = []
trellisNodes.append(1)
for i in range(1, trellisWidth+1):
	trellisNodes.append(trellisHeight)
# trellisNodes.append(1)


def bulidH():
	height = len(m)
	width = height*w #len(x)
	H = []
	for i in range(0, height):
		Hi = []
		for x in range(0, width):
			Hi.append(0)
		H.append(Hi)
	row = 0
	column = 0
	for i in range(0, b):
		for x in range(0, h):
			for y in range(0, w):
				if (row+x >= height) or (column+y >= width):
					break
				H[row+x][column+y] = subH[x][y]
		row = row+1
		column = column+w
	return H
H = bulidH()
CH = []
for i in range(0, len(H[0])):
	CH.append([])
for i in range(0, len(H)):
	for ii in range(0, len(H[i])):
		CH[ii].append(H[i][ii])
for i in range(0, len(H)):
	print(H[i])


#trellis block height 2^h width w+1
def genNodes(template):
	maxheight = 0
	nodes = []
	for n in range(0, len(template)):
		# subGraph = graphviz.Digraph("cluster"+name, strict=False, graph_attr={"label": name})
		if maxheight < template[n]:
			maxheight = template[n]
		nslice = []
		for i in range(0, template[n]):
			node = {"name": str(n)+str(i), "cost": 0}
			nslice.append(node)
			# subGraph.node(node['name'], label=node['name']+" cost: "+str(node['cost']))
		# dot.subgraph(subGraph)
		nodes.append(nslice)
	return (nodes, maxheight)

def addEdge(edges, fromNode, toNode, output, cost=3):
	edge = {"from": fromNode, "to": toNode, "output": output, "cost": cost}
	edges.append(edge)
	# dot.edge(edge['from'], edge['to'], xlabel=str(edge['output'])+" = "+str(edge['cost'])[:5], rank="same")


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



def genEdges(nodes):
	originNode = ""
	edges = []
	# for i in range(0, len(nodes)-1):
		# edges.append([])
	startNodes = [(0,0,s)]
	for i in range(0, len(m)): #run once per bit of message
		#Column 
		for ii in range(0, w): #run w where w = len(x)/w = len(m)
			cost0 = x[(i*w)+ii] #IMPORTANT i * w = ii = range(0, w)
			cost1 = 1 
			if (x[(i*w)+ii]): #IMPORTANT i * w = ii = range(0, w)
				cost1 = 0
			newNodes = []
			for iii in range(0, len(startNodes)):
				#dont add
				node = (startNodes[iii][0]+1,startNodes[iii][1], startNodes[iii][2])
				# print("don't add: "+str(node))
				if (not node in newNodes):
					newNodes.append(node)
				# print("don't add: "+str(startNodes[iii][0])+str(startNodes[iii][1])+" to "+str(startNodes[iii][0]+1)+str(startNodes[iii][1])+", cost: "+str(cost0))
				# print(str(startNodes[iii][0]+1)+str(startNodes[iii][1]))
				addEdge(edges, str(startNodes[iii][0])+str(startNodes[iii][1]), str(startNodes[iii][0]+1)+str(startNodes[iii][1]), 0, cost0)
				#add 
				news = xor(startNodes[iii][2], CH[(i*w)+ii]) #IMPORTANT i * w = ii = range(0, w)
				newbit = findState(news, i)
				node = (startNodes[iii][0]+1, newbit, news)
				# print("add: "+str(node))
				if (not node in newNodes):
					add = 1
					for iiii in range(0, len(newNodes)):
						if (findState(newNodes[iiii][2], i) == newbit):
							add = 0
					if (add):
						newNodes.append(node)
				# if (str(startNodes[iii][0]+1)+str(startNodes[iii][1]) == "161"):
					# print(cost1)
				addEdge(edges, str(startNodes[iii][0])+str(startNodes[iii][1]), str(startNodes[iii][0]+1)+str(newbit), 1, cost1)
				# print("add: "+str(startNodes[iii][0])+str(startNodes[iii][1])+" to "+str(startNodes[iii][0]+1)+str(newbit)+", cost: "+str(cost1))
			startNodes = newNodes
		newStartNodes = []
		# print(startNodes)
		print("--")
		for ii in range(0, len(startNodes)): # prune run to account for the +1 of w+1
			# print(startNodes[ii][2][i])
			print(m[i])
			print(startNodes[ii][2][i])
			print(startNodes[ii][2][i] == m[i])
			if (startNodes[ii][2][i] == m[i]):
				print(startNodes[ii])
				newStartNodes.append(startNodes[ii])
		startNodes = newStartNodes
		newStartNodes = []
		for ii in range(0, len(startNodes)):
			news = startNodes[ii][2]
			newbit = findState(news, i+1)
			node = (startNodes[ii][0]+1, newbit, news)
			if (not node in newStartNodes):
				newStartNodes.append(node)
			addEdge(edges, str(startNodes[ii][0])+str(startNodes[ii][1]), str(startNodes[ii][0]+1)+str(newbit), 2, 0)
		startNodes = newStartNodes
	originNode = getNodeByName(str(newStartNodes[0][0])+str(newStartNodes[0][1]))
	return (edges, originNode)

# def addEdge(edges, fromNode, toNode, output, cost=0):
	# edge = {"from": fromNode, "to": toNode, "output": output, "cost": cost}
	# edges[int(fromNode[:1])].append(edge)
	# dot.edge(edge['from'], edge['to'], xlabel=str(edge['output'])+" = "+str(edge['cost'])[:5], rank="same")

# y = [0.2, 0.2, 1, 0, 0.2, 0.2, 0.2]
(nodes, maxheight) = genNodes(trellisNodes)
subGraph = graphviz.Digraph("cluster0", strict=False, graph_attr={"label": "0"})
subGraph.node(nodes[0][0]['name'], label=(nodes[0][0]['name']+" cost: "+str(nodes[0][0]['cost'])))
dot.subgraph(subGraph)
(edges, originNode) = genEdges(nodes)
# print(edges)

def forwardPass():
	for n in range(1, len(nodes)):
		Nnodes = nodes[n]
		for i in range(0, len(Nnodes)):
			node = Nnodes[i]
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

def minPath(originNode, output):
	# print("-----------------------")
	paths = toNode(originNode)
	nodepaths = []
	for path in paths:
		nodepaths.append([getNodeByName(path['from']),path])
	minNode = nodepaths[0]
	for node in nodepaths:
		# print(node[0])
		# print(minNode)

		if node[0]['cost']+node[1]['cost'] < minNode[0]['cost']+minNode[1]['cost']:
			minNode = node 
	dot.edge(minNode[0]['name'], originNode['name'], color='red')
	# print(minNode)
	# print(minNode[1]['output'])
	if (toNode(minNode[0])):
		return minPath(minNode[0], output+str(minNode[1]['output']))
	else: 
		return (output+str(minNode[1]['output']))[::-1]

def render():
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
forwardPass()
render()
minimumPath = minPath(originNode, "")
minimumPath = list(filter(lambda x : x != '2' , minimumPath))
result = []
for i in range(0, len(minimumPath)):
	result.append(int(minimumPath[i]))
# assert(MatrixMulti(H, result) == m)
print(m)
print(MatrixMulti(H, result))
print(x)
print(result)



dot.render('doctest-output/round-table.gv').replace('\\', '/')
'doctest-output/round-table.gv.pdf'
dot.render('doctest-output/round-table.gv', view=True) 
'doctest-output/round-table.gv.pdf'
