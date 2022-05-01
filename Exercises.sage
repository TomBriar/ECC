import hashlib
import struct
from datetime import datetime
import math
import json
import itertools
import graphviz

# h = 2
# w = 2
# x = [1,1,1,1,0,0,0,0]
# m = [1,0,0,1]
# wght = [0]
# indx = 0
# indm = 0
# b = len(m)
# for i in range(1, b):
# 	for j in range(1, w):
# 		for k in range(0, 2^h-1):
# 			w0 = wght[k] + x[indx]*rho[index]


dot = graphviz.Digraph("mainGraph", strict=True, graph_attr={"rankdir": "LR"})
h = 2 #the number of bits handled per mini trellis or block
m = [0,1,1,1,1,1] #must be a power of 2 and equal to 2**h
s = []
for i in range(0, len(m)):
	s.append(0)
x = [1,0,1,1,0,0,0,1,0,1,0,1] #cover object see below
w = int(len(x) / len(m)) #Keep this number an intager for simplicity
subH = [[1,0],[1, 1]] # chosen randomly atm but h is height and w is width as described above.
b = int(len(x)/w) # number of copies of subH in H
#Height of matrix = trellisHeight = 2**h
#Width of matrix = trellisHeight*w = (2**h)*w
trellisHeight = len(m)
trellisWidth = int((w+1)*len(m))
trellisNodes = []
trellisNodes.append(1)
for i in range(1, trellisWidth+1):
	trellisNodes.append(trellisHeight)
# trellisNodes.append(1)


def bulidH():
	height = trellisHeight #len(m)
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
		row = row+h-1
		column = column+w
	return H
H = bulidH()
CH = []
for i in range(0, len(H[0])):
	CH.append([])
for i in range(0, len(H)):
	for ii in range(0, len(H[i])):
		CH[ii].append(H[i][ii])
print(H)


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

def addEdge(edges, fromNode, toNode, output, cost=0):
	edge = {"from": fromNode, "to": toNode, "output": output, "cost": cost}
	edges[int(fromNode[:1])].append(edge)
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
	for n in range(0, len(edges)):
		def filterfun(edge):
				if edge["to"] == node["name"]:
					return True
				else:
					return False
		for i in filter(filterfun, edges[n]):
			result.append(i)
	return result

def getNodeByName(name):
	for n in range(0, len(nodes)):
		for node in nodes[n]:
			if (node["name"] == name):
				return node

def findState(news, i):
	if (i < len(news)-h):
		state = news[(i):(i+h)]
	else:
		state = news[(i):len(news)]
		for i in range(0, h-len(state)):
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
	for i in range(0, len(nodes)-1):
		edges.append([])
	startNodes = [(0,0,s)]
	for i in range(0, len(m)): #run once per bit of message
		#Column 
		for ii in range(0, w): #run w where w = len(x)/w = len(m)
			cost0 = x[(i*2)+ii]
			cost1 = 1 
			print((i*2)+ii)
			if (x[(i*2)+ii]):
				cost1 = 0
			newNodes = []
			for iii in range(0, len(startNodes)):
				#dont add
				newNodes.append((startNodes[iii][0]+1,startNodes[iii][1], startNodes[iii][2]))
				addEdge(edges, str(startNodes[iii][0])+str(startNodes[iii][1]), str(startNodes[iii][0]+1)+str(startNodes[iii][1]), 0, cost0)
				#add 
				news = xor(startNodes[iii][2], CH[(i*2)+ii])
				newbit = findState(news, i)
				newNodes.append((startNodes[iii][0]+1, newbit, news))
				addEdge(edges, str(startNodes[iii][0])+str(startNodes[iii][1]), str(startNodes[iii][0]+1)+str(newbit), 1, cost1)
			startNodes = newNodes
		newStartNodes = []
		for ii in range(0, len(startNodes)): # prune run to account for the +1 of w+1
			if (startNodes[ii][2][i] == m[i]):
				newStartNodes.append(startNodes[ii])
		startNodes = newStartNodes
		newStartNodes = []
		for ii in range(0, len(startNodes)):
			news = startNodes[ii][2]
			newbit = findState(news, i+1)
			newStartNodes.append((startNodes[ii][0]+1, newbit, news))
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
	paths = toNode(originNode)
	nodepaths = []
	for path in paths:
		nodepaths.append([getNodeByName(path['from']),path])
	minNode = nodepaths[0]
	for node in nodepaths:
		if node[0]['cost']+node[1]['cost'] < minNode[0]['cost']+minNode[1]['cost']:
			minNode = node 
	dot.edge(minNode[0]['name'], originNode['name'], color='red')
	if (toNode(minNode[0])):
		return minPath(minNode[0], output+str(minNode[1]['output']))
	else: 
		return (output+str(minNode[1]['output']))[::-1]

def render():
	for n in range(1, len(nodes)):
		if (n%3 == 0):
			name = "prunenode "+str(int(n/3))
		else:
			name = str(n)
		subGraph = graphviz.Digraph("cluster"+name, strict=False, graph_attr={"label": name})
		Nnodes = nodes[n]
		for i in range(0, len(Nnodes)):
			node = Nnodes[i]
			subGraph.node(node['name'], label=node['name']+" cost: "+str(node['cost']))
		dot.subgraph(subGraph)
	for n in range(0, len(edges)):
		for edge in edges[n]:
			dot.edge(edge['from'], edge['to'], xlabel=str(edge['output'])+" = "+str(edge['cost'])[:5], rank="same")
forwardPass()
render()
minimumPath = minPath(originNode, "")
minimumPath = list(filter(lambda x : x != '2' , minimumPath))
result = []
for i in range(0, len(minimumPath)):
	result.append(int(minimumPath[i]))
assert(MatrixMulti(H, result) == m)
print(x)
print(result)



dot.render('doctest-output/round-table.gv').replace('\\', '/')
'doctest-output/round-table.gv.pdf'
dot.render('doctest-output/round-table.gv', view=True) 
'doctest-output/round-table.gv.pdf'






# R.<X> = PolynomialRing(GF(2), 'X')
# Prime = 2^6
# F = GF(Prime, 'a')
# R.<a> = F
# B = a^3


# B^n = 1


# g = minimumPoly(B^2) * minimumPoly(B^3) * minimumPoly(B^5)

# print(g)

# (64, (21))


# R.<X> = PolynomialRing(GF(2), 'X')
# Prime = 2^4
# F = GF(Prime, 'a')
# R.<a> = F
# # B = a^3
# # t = 5

# def minimumPoly(B):
# 	top = X^Prime + X
# 	factors = factor(top)
# 	for i in factors:
# 		fact = i[0]
# 		if (fact(B) == 0):
# 			return fact
# print(minimumPoly(B))

# g = minimumPoly(B^0)

# for i in range(1, t):
# 	g = g * minimumPoly(B^(-i)) * minimumPoly(B^i)



# print(g)
# print(g(B^(t+1)))
# print(g(B^(-(t+1))))

# power = 0
# for i in F:
# 	print(i)
# 	print(a^power)
# 	power += 1


# B.multplicative_order()


# for i in F:
# 	order = 1
# 	x = i^order
# 	if (i == 0):
# 		x = 1
# 	while x != 1:
# 		x = i^order
# 		print("Start----")
# 		print(order)
# 		print(x)
# 		print(i)
# 		order += 1
# 	print("entrie")
# 	print(i)
# 	print(x)
# 	print(order)
# 	print(x^order)
# 	if (order == 33):
# 		print("FOUND")


# Ax = [1, 0]
# Px = {1: 0.5, 0: 0.5}
# Hx = 0
# for i in Ax:
# 	Hx += Px[i] * math.log((1/Px[i]),2)

# Hy = Hx
# print(Hx)


# Ax = [1, 0]
# Px = {1: 0.5, 0: 0.5}
# Az = [1, 0]
# Pz = {1: 0.5, 0: 0.5}
# Hxy = 0

# Axy = [10, 01, 00, 11]
# Pxy = {10: 0.25, 01: 0.25, 00: 0.25, 11: 0.25}
# Qxy = {10: 0.2, 01: 0.3, 00: 0.25, 11: 0.25}
# Hxy = 0
#f = noise
#Y P(y = 1) = 0.5
# Px = {0: 0.9, 1: 0.1}
# ZPy = {0: Px[0]+(Px[1]*(f)),1: }
# BSPy = {11: 1-f, 10: f, 01: 0, 00: 1-f}
# print(Py)

# def H2(x):
# 	if x == 0 or x == 1:
# 		return 0
# 	return (x * (math.log((1/x), 2)))+((1-x) * math.log(1/(1-x), 2))

# y1 = [0.2, 0.2, 0.9, 0.2, 0.2, 0.2, 0.2]
# T = ["0000000",
# "0001011",
# "0010111",
# "0011100",
# "0100110",
# "0101101",
# "0110001",
# "0111010",
# "1000101",
# "1001110",
# "1010010",
# "1011001",
# "1100011",
# "1101000",
# "1110100",
# "1111111"]

# py = 0.00545000000000000
# pt = 0.0625
# sumable = 0
# sumable2 = 0
# sumable3 = 0
# for i in range(0, len(T)):
# 	t = T[i]
# 	pyt = 1
# 	for x in range(0,7):
# 		tx = int(t[x])
# 		if (tx):
# 			pyt = pyt * y1[x]
# 		else:
# 			pyt = pyt * (1 - y1[x])
# 	sumable += pyt * pt
# 	sumable2 += ((pyt * pt) / py)
# 	if (t[1] == '1'):
# 		sumable3 += ((pyt * pt) / py)
# 	print(((pyt * pt) / py))
# print(sumable)
# print(sumable2)
# print(1 - sumable3)


# def genNodes(template):
# 	maxheight = 0
# 	nodes = []
# 	for n in range(0, len(template)):
# 		if maxheight < template[n]:
# 			maxheight = template[n]
# 		nslice = []
# 		for i in range(0, template[n]):
# 			nslice.append({"name": str(n)+str(i), "cost": 0})
# 		nodes.append(nslice)
# 	return (nodes, maxheight)

# def genEdges(nodes):
# 	edges = []
# 	for i in range(0, len(nodes)-1):
# 		edges.append([])
# 	return edges

# def addEdge(edges, fromNode, toNode, output):
# 	edges[int(fromNode[:1])].append({"from": fromNode, "to": toNode, "output": output})


# y = [0.2, 0.2, 1, 0.2, 0.2, 0.2, 0.2]
# (nodes, maxheight) = genNodes([1,2,4,8,8,4,2,1])
# edges = genEdges(nodes)
# dot = graphviz.Digraph("mainGraph", strict=True, graph_attr={"rankdir": "LR"})
# subGraph = graphviz.Digraph("cluster0", strict=False, graph_attr={"label": "0"})
# subGraph.node(nodes[0][0]['name'], label=(nodes[0][0]['name']+" cost: "+str(nodes[0][0]['cost'])))
# dot.subgraph(subGraph)


# addEdge(edges, "00", "10", 0)
# addEdge(edges, "00", "11", 1)

# addEdge(edges, "10", "20", 0)
# addEdge(edges, "10", "22", 1)
# addEdge(edges, "11", "21", 1)
# addEdge(edges, "11", "23", 0)

# addEdge(edges, "20", "30", 0)
# addEdge(edges, "20", "34", 1)
# addEdge(edges, "21", "31", 0)
# addEdge(edges, "21", "35", 1)
# addEdge(edges, "22", "32", 0)
# addEdge(edges, "22", "36", 1)
# addEdge(edges, "23", "33", 0)
# addEdge(edges, "23", "37", 1)

# addEdge(edges, "30", "40", 0)
# addEdge(edges, "30", "41", 1)
# addEdge(edges, "31", "41", 0)
# addEdge(edges, "31", "40", 1)
# addEdge(edges, "32", "42", 0)
# addEdge(edges, "32", "43", 1)
# addEdge(edges, "33", "43", 0)
# addEdge(edges, "33", "42", 1)
# addEdge(edges, "34", "44", 1)
# addEdge(edges, "34", "45", 0)
# addEdge(edges, "35", "45", 1)
# addEdge(edges, "35", "44", 0)
# addEdge(edges, "36", "46", 1)
# addEdge(edges, "36", "47", 0)
# addEdge(edges, "37", "47", 1)
# addEdge(edges, "37", "46", 0)

# addEdge(edges, "40", "50", 0)
# addEdge(edges, "41", "51", 0)
# addEdge(edges, "42", "52", 1)
# addEdge(edges, "43", "53", 1)
# addEdge(edges, "44", "50", 1)
# addEdge(edges, "45", "51", 1)
# addEdge(edges, "46", "52", 0)
# addEdge(edges, "47", "53", 0)

# addEdge(edges, "50", "60", 0)
# addEdge(edges, "51", "61", 1)
# addEdge(edges, "52", "60", 1)
# addEdge(edges, "53", "61", 0)

# addEdge(edges, "60", "70", 0)
# addEdge(edges, "61", "70", 1)


# # nodes = [[{"name": "aa", "cost": 0}],[{"name": "ba"},{"name": "bb"}],[{"name": "ca"},{"name": "cb"},{"name": "cc"},{"name":"cd"}],[{"name": "da"},{"name": "db"},{"name": "dc"},{"name":"dd"},{"name": "de"},{"name": "df"},{"name": "dg"},{"name":"dh"}],[{"name": "ea"},{"name": "eb"},{"name": "ec"},{"name":"ed"},{"name": "ee"},{"name": "ef"},{"name": "eg"},{"name":"eh"}],[{"name": "fa"},{"name": "fb"},{"name": "fc"},{"name":"fd"}],[{"name": "ga"},{"name": "gb"}],[{"name": "ha"}]]
# # edges = [[{"from": "aa", "to": "ba", "output": 0},{"from": "aa", "to": "bb", "output": 1}],[{"from": "ba", "to": "ca", "output": 0},{"from": "ba", "to": "cc", "output": 1},{"from": "bb", "to": "cb", "output": 1},{"from": "bb", "to": "cd", "output": 0}],[{"from": "ca", "to": "da", "output": 0},{"from": "ca", "to": "de", "output": 1},{"from": "cb", "to": "db", "output": 0},{"from": "cb", "to": "df", "output": 1},{"from": "cc", "to": "dc", "output": 0},{"from": "cc", "to": "dg", "output": 1},{"from": "cd", "to": "dd", "output": 0},{"from": "cd", "to": "dh", "output": 1}],[{"from": "da", "to": "ea", "output": 0},{"from": "da", "to": "eb", "output": 1},{"from": "db", "to": "ea", "output": 1},{"from": "db", "to": "eb", "output": 0},{"from": "dc", "to": "ec", "output": 0},{"from": "dc", "to": "ed", "output": 1},{"from": "dd", "to": "ed", "output": 0},{"from": "dd", "to": "ec", "output": 1},{"from": "de", "to": "ee", "output": 1},{"from": "de", "to": "ef", "output": 0},{"from": "df", "to": "ee", "output": 0},{"from": "df", "to": "ef", "output": 1},{"from": "dg", "to": "eg", "output": 1},{"from": "dg", "to": "eh", "output": 0},{"from": "dh", "to": "eh", "output": 1},{"from": "dh", "to": "eg", "output": 0}],[{"from": "ea", "to": "fa", "output": 0},{"from": "eb", "to": "fb", "output": 0},{"from": "ec", "to": "fc", "output": 1},{"from": "ed", "to": "fd", "output": 1},{"from": "ee", "to": "fa", "output": 1},{"from": "ef", "to": "fb", "output": 1},{"from": "eg", "to": "fc", "output": 0},{"from": "eh", "to": "fd", "output": 0}],[{"from": "fa", "to": "ga", "output": 0},{"from": "fb", "to": "gb", "output": 1},{"from": "fc", "to": "ga", "output": 1},{"from": "fd", "to": "gb", "output": 0}],[{"from": "ga", "to": "ha", "output": 0},{"from": "gb", "to": "ha", "output": 1}]]

# def addCost():
# 	for n in range(0,len(edges)):
# 		cost1 = -math.log(y[n], 2)
# 		if (y[n] == 1):
# 			cost0 = 1000
# 		else:
# 			cost0 = -math.log(1-y[n], 2)
		
# 		for i in range(0,len(edges[n])):
# 			if (edges[n][i]["output"]):
# 				edges[n][i]["cost"] = cost1
# 			else:
# 				edges[n][i]["cost"] = cost0
# addCost()


# def toNode(node):
# 	result = []
# 	for n in range(0, len(edges)):
# 		def filterfun(edge):
# 				if edge["to"] == node["name"]:
# 					return True
# 				else:
# 					return False
# 		for i in filter(filterfun, edges[n]):
# 			result.append(i)
# 	return result

# def getNodeByName(name):
# 	for n in range(0, len(nodes)):
# 		for node in nodes[n]:
# 			if (node["name"] == name):
# 				return node

# def forwardPass():
# 	for n in range(1, len(nodes)):
# 		subGraph = graphviz.Digraph("cluster"+str(n), strict=False, graph_attr={"label": str(n)})
# 		Nnodes = nodes[n]
# 		for i in range(0, len(Nnodes)):
# 			node = Nnodes[i]
# 			paths = toNode(node)
# 			costs = []
# 			for path in paths:
# 				sourceNode = getNodeByName(path["from"])
# 				totalPathCost = sourceNode["cost"] + path['cost']
# 				costs.append(totalPathCost)
# 			mincost = costs[0]
# 			for cost in costs:
# 				if cost < mincost:
# 					mincost = cost
# 			node['cost'] = mincost
# 			subGraph.node(node['name'], label=node['name']+" cost: "+str(node['cost']))
# 		dot.subgraph(subGraph)

# 	for n in range(0, len(edges)):
# 		for edge in edges[n]:
# 			dot.edge(edge['from'], edge['to'], xlabel=str(edge['output'])+" = "+str(edge['cost'])[:5], rank="same")

# def minPath(originNode, output):
# 	paths = toNode(originNode)
# 	nodepaths = []
# 	for path in paths:
# 		nodepaths.append([getNodeByName(path['from']),path])
# 	minNode = nodepaths[0]
# 	for node in nodepaths:
# 		if node[0]['cost']+node[1]['cost'] < minNode[0]['cost']+minNode[1]['cost']:
# 			minNode = node 
# 	dot.edge(minNode[0]['name'], originNode['name'], color='red')
# 	if (toNode(minNode[0])):
# 		return minPath(minNode[0], output+str(minNode[1]['output']))
# 	else: 
# 		return (output+str(minNode[1]['output']))[::-1]
# forwardPass()
# print(minPath(nodes[len(nodes)-1][0], ""))

# dot.render('doctest-output/round-table.gv').replace('\\', '/')
# 'doctest-output/round-table.gv.pdf'
# dot.render('doctest-output/round-table.gv', view=True) 
# 'doctest-output/round-table.gv.pdf'











# sumable2 = 0
# for i in range(0, len(T)):
# 	t = T[i]
# 	if (i != 1-1):
# 		sumable = 1
# 		for x in range(0,7):
# 			tx = int(t[x])
# 			if (tx):
# 				sumable = sumable * y1[x]
# 			else:
# 				sumable = sumable * (1 - y1[x])
# 		sumable2 += ((sumable * 0.0625) / py)
# print(sumable2)




# print(H2(1))



#CHANNEL DEFFINITON
# f = 0.15
# BECPyx = {11: 1-f, 10: f, 01: 0, 00: 1}

# def IZ(Px):
# 	ZPyx = {11: 1-f, 10: f, 01: 0, 00: 1}
# 	return H2(Px[1]*(1-f)) - ((Px[0]*H2(ZPyx[01]))+(Px[1]*H2(ZPyx[10])))

# def IZ(Px):
# 	ZPyx = {11: 1-f, 10: f, 01: 0, 00: 1}
# 	return H2(Px[1]*(1-f)) - ((Px[0]*H2(ZPyx[01]))+(Px[1]*H2(ZPyx[10])))
	#H(Y) - H(Y|X)
	#H2(P(Y)) - H2(P(Y|X))
	#H2(P(y=1)) - H2(P(Y|X))
	#H2(P(Px[1]*(1-f))) - H2(Px[1]*P(y=1|x=1)+Px[1]*P(y=0|x=1)+Px[0]*P(y=1|x=0)+Px[0]*P(y=0|x=0))
	#H2(P(Px[1]*(1-f))) - H2(Px[1]*P(1-f)+Px[1]*(f)+Px[0]*(0)+Px[0]*(1))
	#H2(P(Px[1]*(1-f))) - H2(Px[1]*P(1-f)+Px[1]*(f)+Px[0]*(1))
	#H2(P(Px[1]*(1-f))) - H2(Px[1]*1-f)

# print(IZ({1: 0.5, 0: 0.5}))

# print(I(0.1))


# for x in range(1,10):
# 	f = 0.1*x
# 	px = {0: 0, 1: 0}
# 	ipx = 0
# 	def IBSC(Px):
# 		BSCPyx = {11: 1-f, 10: f, 01: f, 00: 1-f}
# 		return H2((Px[1]*BSCPyx[11])+(Px[0]*BSCPyx[01])) - H2(f)

# 	for i in range(1,999):
# 		px1 = 0.001*i
# 		Px = {0: 1-px1, 1: px1}
		
# 		iPx = IBSC(Px)
# 		if (iPx > ipx):
# 			ipx = iPx
# 			px = Px
# 	print(px)
# 	print(ipx)

# f = 0.15

# 11 = P(11)*(1-f)
# 10 = P(10)*(1-f)
# 01 = P(01)*(1-f)
# 00 = P(00)*(1-f)
# 1? = (P(1)*(1-f))*f
# ?1 = f*(P(1)*(1-f))
# 0? = (P(0)*(1-f))*f
# ?0 = f*(P(0)*(1-f))
# ?? = f*f


# 11 = 11, 1?, ?1, ??
# 10 = 10, 1?, ?0, ??
# 01 = 01, 0?, ?1, ??
# 00 = 00, 0?, ?0, ??

# ?? = x
# 1? = 11, 10
# 0? = 01, 00
# ?0 = 10, 00
# ?1 = 01, 11





# for x in range(1,10):
# 	f = 0.1*x

# # for x in range(1,2):
# # 	f = 0.15
# 	px = {0: 0, 1: 0}
# 	ipx = 0
# 	def IBEC(Px):
# 		#I(X,Y) = H(X) - H(X|Y)
# 		#I(X,Y) = H2(P(X)) - H2(sum_yi P(X|yi))
# 		#I(X,Y) = H2(P(x=1)) - Px[1]*(H2(P(x=1|y=0)) + H2(P(x=1|y=1)) + H2(P(x=1|y=?)))
# 		#I(X,Y) = H2(Px[1]) - Px[1]*(H2(0) + H2(1) + H2(f)))
# 		#I(X,Y) = H2(Px[1]) - Px[1]*(H2(f))
# 		#I(X,Y) = H2(Px[1]) - Px[1]*(H2(f))
# 		return H2(Px[1]) - f*(H2(Px[1]))

# 	for i in range(1,999):
# 		px1 = 0.001*i
# 		Px = {0: 1-px1, 1: px1}
# 		# ZPy = {0: Px[0]+(Px[1]*(f)),1: Px[1]*(1-f)}
# 		#px probability that x = 1
		
# 		# print('\n'+str(px1))
# 		# print(I(Px))
# 		iPx = IBEC(Px)
# 		if (iPx > ipx):
# 			ipx = iPx
# 			px = Px
# 	print('\n'+str(f))
# 	print(px)
# 	print(ipx)



# for i in Axy:
# 	Hxy += Pxy[i] * math.log((1/Pxy[i]),2)
# print(Hxy)
# Hxy = 0
# for i in Axy:
# 	Hxy += Qxy[i] * math.log((1/Qxy[i]),2)
# print(Hxy)

# Dkl = 0
# print("start")
# for x in Axy:
# 	print(Qxy[x] * math.log(Qxy[x]/Pxy[x], 2))
# # print(Dkl)

# print(math.log(Pxy[10]/Pxy[10], 2))


# 0 1 2 ... 5

# t+1 = 2^(2^2)
# print("HELLO")
# N = 5 
# B = 2 
# K = 10

# sumation = 0
# for i in range(1, N+1):
# 	sumation += i*1
# print(sumation)


# print(6416000)


# def roots(x):
# 	roots = []
# 	for i in range(0, Prime-1):
# 		if (x(a^i) == 0):
# 			roots.append((a^i, i))
# 	return roots


# R.<X> = PolynomialRing(GF(2), 'X', order='lex')
# Prime = 2^4
# n = Prime-1
# # F = GF(Prime, 'a', X^5+X^2+1)
# F = GF(Prime, 'a')
# R.<a> = F
# B = a


# g = a^6+(a^9*X)+(a^6*X^2)+(a^4*X^3)+(a^14*X^4)+(a^10*X^5)+X^6
# h = X^9 + (a^2 + a + 1)*X^8 + (a^3 + a^2 + a + 1)*X^7 + a*X^6 + (a^2 + 1)*X^5 + (a + 1)*X^4 + (a + 1)*X^3 + (a^3 + a + 1)*X^2 + (a^3 + a^2 + a + 1)*X + a^3 + a
# h = (X^n+1)/g
# print(roots(h))
# print(roots(g))
# g2 = X^9*h(X^(-1))
# # print(roots(g2))
# print(g2)


# def fieldInfo():
# 	index = 0
# 	while index < order(F):
# 		print("a^"+str(index)+" = "+str(a^index)+"; order = "+str((a^index).multiplicative_order()))
# 		index += 1


# g = X^6 + (a^10*X^5) + (a^9*X^4) + (a^24*X^3) + (a^16*X^2) + (a^24*X) + a^21
# r = (X^21*a^3) + (X^7*a^5)
# re = X^18 + X^3

# # r = (X^20*a^6) + (X^12*a^21) + a^2


# # g = a^6+(a^9*X)+(a^6*X^2)+(a^4*X^3)+(a^14*X^4)+(a^10*X^5)+X^6
# v = g.degree()
# t = v/2
# r = (X^12*a^4) + (X^9*a)
# re = X^6 + X^3
# t = 3
# r = (a^4*X^12) + (a^3*X^6) + (a^7*X^3)
# r = (X^13*a^3) + (X^8*a^9) + (X^3*a^4)
# r = (a^11*X^10) + (a^7*X^3)
# g = X^8 + X^4 + X^2 + X + 1
# r = X^7 + X^30


# print(((sigmader(a^(-3)) / -Z0(a^(-3)))*X^3) + r)
# print((((sigmader(a^(-3)) / -Z0(a^(-3)))*X^3) + r) % g)


# ax = 1+(a^5*X)+(a*X^4)+(a^7*X^8)
# u = ax * X^6
# b = g2 % u
# print(b + u)
# # print()
# B = a^14
# print((X - B^1) * (X - B^2) * (X - B^3) * (X - B^4))

# r = (X^15+1)%g
# print((X^15+1)/g)

# n-k = 6
# 6 + 9 = 15 = n


# fieldInfo()



# (a^3 + a + 1)*X^14 + a*X^10 + (a^2 + a)*X^7 + X^6

# def padbin(x):
# 	if (len(x) >= 6):
# 		return x
# 	else:
# 		return padbin(x + '0')


# def BrootsInv(x):
# 	roots = []
# 	for i in range(0, Prime-1):
# 		if (x(B^(-i)) == 0):
# 			roots.append((B^(-i), -i))
# 	return roots


# def BrootsInv(x):
# 	roots = []
# 	for i in range(0, Prime-1):
# 		if (x(B^(-i)) == 0):
# 			roots.append((B^(-i), -i))
# 	return roots


# def Broots(x):
# 	roots = []
# 	for i in range(0, Prime-1):
# 		if (x(B^i) == 0):
# 			roots.append((B^i, i))
# 	return roots

# def Groots(g):
# 	roots = []
# 	oneroot = 0
# 	for i in range(0, Prime-1):
# 		if (g(B^i) == 0):
# 			roots.append((B^i, i))
# 			oneroot = 1
# 		elif (oneroot):
# 			return roots
# 	return roots

# def berlecamp(S):
	
# 	#Setup step 1
# 	Cd = X-X + 1
# 	Bd = X-X + 1
# 	x = 1
# 	L = 0
# 	b = F(1)
# 	d = F(0)
# 	N = 0
# 	n = len(S)



# 	def step2(Cd, Bd, x, L, b, d, N, n):
# 		# print("step2")
# 		if (n == N):
# 			return Cd, Bd, x, L, b, d, N, n
# 		sumation = S[N]
# 		cis = Cd.coefficients()
# 		for i in range(1, L+1):
# 			ci = cis[i]
# 			sumation = sumation + (ci * S[N-i])
# 		d = sumation
# 		if (d == 0):
# 			return step3(Cd, Bd, x, L, b, d, N, n)
# 		elif (d != 0 and 2*L > N):
# 			# print("")
# 			return step4(Cd, Bd, x, L, b, d, N, n)
# 		elif (d != 0 and 2*L <= N):
# 			return step5(Cd, Bd, x, L, b, d, N, n)
# 		# print("never get here")

# 	def step3(Cd, Bd, x, L, b, d, N, n):
# 		# print("step3")
# 		x += 1
# 		return step6(Cd, Bd, x, L, b, d, N, n)

# 	def step4(Cd, Bd, x, L, b, d, N, n):
# 		# print("step4")
# 		Cd = Cd - d * b^(-1) * X^x * Bd
# 		x += 1
# 		return step6(Cd, Bd, x, L, b, d, N, n)

# 	def step5(Cd, Bd, x, L, b, d, N, n):
# 		# print("step5")
# 		Td = Cd
# 		Cd = Cd - d * b^(-1) * X^x * Bd
# 		L = N + 1 - L
# 		assert(L == Cd.degree())
# 		Bd = Td
# 		b = d
# 		x = 1 
# 		return step6(Cd, Bd, x, L, b, d, N, n)

# 	def step6(Cd, Bd, x, L, b, d, N, n):
# 		# print("step6")
# 		N += 1
# 		return step2(Cd, Bd, x, L, b, d, N, n)

# 	(Cd, Bd, x, L, b, d, N, n) = step2(Cd, Bd, x, L, b, d, N, n)

# 	return Cd
	
# def Euclidean(a, b, S, e):
# 	i = 2
# 	ri = [a, b]
# 	qi = [X-X, X-X]
# 	fi = [X-X+1, X-X]
# 	gi = [X-X, X-X+1]

# 	def recurse(i, ri, qi, fi ,gi):
# 		ri.append(ri[i-2]%ri[i-1])
# 		qi.append((ri[i-2]-ri[i]) // ri[i-1])
# 		fi.append(fi[i-2] - (qi[i]*fi[i-1]))
# 		gi.append(gi[i-2] - (qi[i]*gi[i-1]))
# 		if not e:
# 			if (ri[i].degree() < gi[i].degree() < len(S)):
# 				return (gi[i], ri[i])
# 		else:
# 			if (e%2):
# 				if (ri[i].degree() < t+((e-1)/2)):
# 					return (gi[i], ri[i])
# 			else:
# 				if (ri[i].degree() < t+((e)/2)):
# 					return (gi[i], ri[i])
# 		i += 1
# 		return recurse(i, ri, qi, fi ,gi)
# 	return(recurse(i, ri, qi, fi ,gi))

# def fourierTrans(v):
# 	R = X-X
# 	for i in range(0, n):
# 		R += v(a^i)*X^i
# 	return R

# def fourierTransInv(v):
# 	degree = v.degree()+1
# 	print(degree)
# 	V = X^degree*v(X^(-1))
# 	print(v)
# 	print(V)
# 	R = X-X
# 	for i in range(0, n):
# 		R += V(a^i)*X^i
# 	return R

# def decodeBCH(r, g):
# 	root = Groots(g)
# 	print(root)
# 	S = []
# 	for i in range(0, len(root)):
# 		S.append(r(root[i][0]))
# 	print("S"+str(S))
# 	locaterPoly = berlecamp(S)
# 	print("locate"+str(locaterPoly))
# 	locaterPolyVec = []
# 	for x in locaterPoly:
# 		locaterPolyVec.append(x)
# 	print(locaterPoly.derivative())
# 	derLP = locaterPoly.derivative()
# 	invRoots = BrootsInv(locaterPoly)
# 	print("invRoots"+str(invRoots))
# 	Z0 = X-X
# 	for i in range(0, locaterPoly.degree()):
# 		sumation = 0
# 		for x in range(0, i):
# 			sumation += locaterPolyVec[i-(x)]*S[x]
# 		Z0 += (S[i] + sumation)*X^i
# 	E = X-X
# 	for i in invRoots:
# 		if i == 1:
# 			print("1 ERRROR")
# 		else:
# 			E += -Z0(a^(i[1])) / derLP(a^(i[1]))*X^(abs(i[1]))
# 	print("r"+str(r))
# 	print("E"+str(E))
# 	print("result"+str(r-E))
# 	return r-E

# def decodeBCHE(r, g):
# 	root = Groots(g)
# 	print(root)
# 	S = []
# 	for i in range(0, len(root)):
# 		S.append(r(root[i][0]))
# 	print("S"+str(S))
# 	Sx = X-X
# 	for i in range(0, len(S)):
# 		Sx += S[i]*X^(i)
# 	print("Sx"+str(Sx))
# 	(locaterPoly, Z0) = Euclidean(X^(len(S)), Sx, S)
# 	print("locate"+str(locaterPoly))
# 	locaterPolyVec = []
# 	for x in locaterPoly:
# 		locaterPolyVec.append(x)
# 	derLP = locaterPoly.derivative()
# 	print("determinate of locaterPoly"+str(derLP))
# 	invRoots = BrootsInv(locaterPoly)
# 	print("invRoots"+str(invRoots))
# 	print("Z0"+str(Z0))
# 	E = X-X
# 	for i in invRoots:
# 		if i == 1:
# 			print("1 ERRROR")
# 		else:
# 			E += -Z0(a^(i[1])) / derLP(a^(i[1]))*X^(abs(i[1]))
# 	print("result"+str(r-E))

# def decodeBCHF(r, g):
# 	R = fourierTrans(r)
# 	print(R)
# 	coeffsVec = []
# 	for x in R:
# 		coeffsVec.append(x)
# 	coeffsVec = coeffsVec[1:]
# 	print(coeffsVec)
# 	S = []
# 	for i in range(0, g.degree()):
# 		S.append(coeffsVec[i])
# 	print(S)
# 	Sx = X-X
# 	for i in range(0, len(S)):
# 		Sx += S[i]*X^(i)
# 	E = [0]
# 	E += Sx
# 	print(E)
# 	print(len(E))
# 	locaterPoly = berlecamp(S)
# 	locaterPolyVec = []
# 	for x in locaterPoly:
# 		locaterPolyVec.append(x)
# 	print(len(locaterPolyVec))
# 	for i in range(len(S)-2, n-3):
# 		sumation = 0
# 		print("sum")
# 		for x in range(1, len(locaterPolyVec)):
# 			# print(i)
# 			# print(len(locaterPolyVec)-1)
# 			# print(x)
# 			# print(i+(len(locaterPolyVec)-1)-x)
# 			print("+= "+str(locaterPolyVec[x]*E[i+(len(locaterPolyVec)-1)-x]))
# 			print("="+str((locaterPolyVec[x], E[i+(len(locaterPolyVec)-1)-x])))
# 			sumation += locaterPolyVec[x]*E[i+(len(locaterPolyVec)-1)-x]
# 		print("sum"+str(i)+" =="+str(sumation))
# 		E.append(sumation)
# 		print(i)
# 	sumation = E[len(locaterPolyVec)-1]
# 	print(sumation)
# 	for x in range(1, len(locaterPolyVec)-1):
# 		print(E[(len(locaterPolyVec)-1)-x] * locaterPolyVec[x])
# 		sumation += E[(len(locaterPolyVec)-1)-x] * locaterPolyVec[x]
# 	E[0] = sumation
# 	Ex = X-X
# 	for i in range(0, len(E)):
# 		Ex += E[i]*X^i
# 	e = fourierTransInv(Ex)
# 	print("result"+str(r-e))

# def decodeBCHEE(r, re, g):
# 	print(re)
# 	index = 0
# 	e = 0
# 	B = 1
# 	for i in re:
# 		print(i, index)
# 		if i:
# 			e += 1
# 			print((1+a^index*X))
# 			B = B * (1+a^index*X)
# 		index += 1
# 	print(B)

# 	root = Groots(g)
# 	print(root)
# 	S = []
# 	for i in range(0, len(root)):
# 		S.append(r(root[i][0]))
# 	print("S"+str(S))
# 	Sx = X-X
# 	for i in range(0, len(S)):
# 		Sx += S[i]*X^(i)
# 	print("Sx"+str(Sx))
# 	T = (Sx*B) % X^(v)
# 	print("T"+str(T))
# 	(locaterPoly, Z0) = Euclidean(X^(len(S)), T, S, e)
# 	print("locate"+str(locaterPoly))
# 	Y = locaterPoly*B
# 	print("Y"+str(Y))
# 	derY = Y.derivative()
# 	print("derY"+str(derY))
# 	invRoots = BrootsInv(Y)
# 	print("invRoots"+str(invRoots))
# 	print("Z0"+str(Z0))
# 	E = X-X
# 	for i in invRoots:
# 		if i == 1:
# 			print("1 ERRROR")
# 		else:
# 			E += -Z0(a^(i[1])) / derY(a^(i[1]))*X^(abs(i[1]))
# 	print("E"+str(E))
# 	print("result"+str(r-E))


	# print(locaterPoly * Sx)




	# root = Groots(g)
	# print(root)
	# S = []
	# for i in range(0, len(root)):
	# 	S.append(r(root[i][0]))
	# print("S"+str(S))
	# Sx = X-X
	# for i in range(0, len(S)):
	# 	Sx += S[i]*X^(i)
	# print("Sx"+str(Sx))
	# (locaterPoly, Z0) = Euclidean(X^(len(S)), Sx, S)
	# print("locate"+str(locaterPoly))
	# locaterPolyVec = []
	# for x in locaterPoly:
	# 	locaterPolyVec.append(x)
	# derLP = locaterPoly.derivative()
	# print("determinate of locaterPoly"+str(derLP))
	# invRoots = BrootsInv(locaterPoly)
	# print("invRoots"+str(invRoots))
	# print("Z0"+str(Z0))
	# E = X-X
	# for i in invRoots:
	# 	if i == 1:
	# 		print("1 ERRROR")
	# 	else:
	# 		E += -Z0(a^(i[1])) / derLP(a^(i[1]))*X^(abs(i[1]))
	# print("result"+str(r-E))

# decodeBCHEE(r, re, g)
# decodeBCHE(r, g)
# decodeBCH(r, g)


# R.<X> = PolynomialRing(GF(2), 'X')
# Prime = 2^8
# F = GF(Prime, 'a')
# R.<a> = F

# # power = 0

# def minimumPoly(B):
# 	top = X^Prime + X
# 	factors = factor(top)
# 	for i in factors:
# 		fact = i[0]
# 		if (fact(B) == 0):
# 			return fact



# for i in F:
# 	if i != 0:
# 		order = i.multiplicative_order()
# 		for x in range(4, 100):
# 			if order == 2^x+1:
# 				print(i)
# 				print(x)
# 				print(order)

# m = 4
# B = a^6 + a^4 + a^3 + 1
# B2 = B^2
# B3 = B^3
# B4 = B^4
# print(B.multiplicative_order())
# print(B2.multiplicative_order())
# print(B3.multiplicative_order())
# print(B4.multiplicative_order())
# print(minimumPoly(B))
# print(minimumPoly(B2))
# print(minimumPoly(B3))
# print(minimumPoly(B4))

# print(minimumPoly(B)*minimumPoly(B3))


# H1 = (1, a^1, a^2, a^3, a^4, a^5, a^6, a^7, a^8, a^9, a^10, a^11, a^12, a^13, a^14)
# H2 = (1, (a^3)^1, (a^3)^2, (a^3)^3, (a^3)^4, (a^3)^5, (a^3)^6, (a^3)^7, (a^3)^8, (a^3)^9, (a^3)^10, (a^3)^11, (a^3)^12, (a^3)^13, (a^3)^14)

# H = (H1, H2)

# r = X^7 + X^30
# index = 0
# for i in r:
# 	x = i[1]
# 	S = X-X
# 	for h in H[index]:
# 		S += x*h
# 	print(S)
# 	index += 1
# 														X^8
# 														---------
# a^6 + a^9X + a^6X^2 + a^4X^3 + a^14X^4 + a^10X^5 + X^6 | a^7*X^14 + a*X^10 + a^5*X^7 + X^6
# 														 X^14 + X^13 + X^12 + X^11 + X^10 + X^9






# R.<X> = F
# power = 0

# for i in F:
# 	if (i != 0 and i != 1):
# 		power = power + 1
# 	for x in range(1, 2^6):
# 		binary = padbin(str(bin(x)[2:])[::-1])
# 		poly = Y-Y
# 		if (binary[0]):
# 			poly = 1
# 		for y in range(1, len(binary)):
# 			if (int(binary[y])):
# 				poly = poly + Y^y
# 		if (poly != 1 and poly(i) == 0):
# 			print("new min       "+str(i))
# 			print(power)
# 			print(poly)
# 			break

# # a^3, a^6 = 
# # a^5 = Y^5 + Y^4 + Y^2 + Y + 1
# a^7 = Y^5 + Y^3 + Y^2 + Y + 1
# # a^9 = Y^5 + Y^4 + Y^2 + Y + 1
# # a^10 = Y^5 + Y^4 + Y^2 + Y + 1
# # a^11 = Y^5 + Y^4 + Y^3 + Y + 1
# # a^13 = Y^5 + Y^4 + Y^3 + Y + 1
# a^14 = Y^5 + Y^3 + Y^2 + Y + 1
# # a^15 = Y^5 + Y^3 + 1
# # a^18 = Y^5 + Y^4 + Y^2 + Y + 1
# a^19 = Y^5 + Y^3 + Y^2 + Y + 1
# # a^20 = Y^5 + Y^4 + Y^2 + Y + 1
# # a^21 = Y^5 + Y^4 + Y^3 + Y + 1
# # a^22 = Y^5 + Y^4 + Y^3 + Y + 1
# # a^23 = Y^5 + Y^3 + 1
# a^25 = Y^5 + Y^3 + Y^2 + Y + 1
# # a^26 = Y^5 + Y^4 + Y^3 + Y + 1
# # a^27 = Y^5 + Y^3 + 1
# a^28 = Y^5 + Y^3 + Y^2 + Y + 1
# # a^29 = Y^5 + Y^3 + 1
# # a^30 = Y^5 + Y^3 + 1
# # a^31 = Y + 1

# Y^5 + Y^2 + 1  = a^1, a^2, a^4, a^8, a^16
# Y^5 + Y^4 + Y^3 + Y^2 + 1 = a^3, a^6, a^12, a^17, a^24
# Y^5 + Y^4 + Y^2 + Y + 1 = 

# # 1(0) = 0



# print("start bin")




# B = X^7
# B2 = B^2
# B3 = B^3
# B4 = B^4

# print(B)
# print(B^2)
# print(B^3)
# print(B^14)
# print("next row")
# print(B^3)
# print((B^3)^2)
# print((B^3)^3)
# print((B^3)^14)
# print("next row")
# print(B^5)
# print((B^5)^2)
# print((B^5)^3)
# print((B^5)^14)
# print("next row")
# print(B^7)
# print((B^7)^2)
# print((B^7)^3)
# print((B^7)^14)
# h = Y^8 + Y^7 + Y^6 + Y^4 + 1
# print(Y^11 * h(Y^-1))

# print(Y^16 * (Y^-16 + Y^-14 + Y^-12 + Y^-9 + Y^-8 + Y^-7 + Y^-6 + Y^-4 + Y^-2 + Y^-1 + 1))
# print(Y^7 * (Y^-8 + Y^-7 + Y^-6 + Y^-4 + 1))





# top = Y^(2^4) + Y
# print(top)

# print(factor(top))
# minimum = X^4 + X^3 + X^2 + X + 1
# print(minimum(B)) #Y^4 + Y^3 + 1
# print(minimum(B2)) #Y^4 + Y^3 + 1
# print(minimum(B3)) #Y^4 + Y^3 + Y^2 + Y + 1
# print(minimum(B4)) #Y^4 + Y^3 + 1

# # print((X^4 + X^3 + 1) * (X^4 + X^3 + 1) * (X^4 + X^3 + X^2 + X + 1) * (X^4 + X^3 + 1))
# # print(X^16 + X^14 + X^12 + X^9 + X^8 + X^7 + X^6 + X^4 + X^2 + X + 1)

# # # Y * (Y + 1) * (Y^2 + Y + 1) * (Y^4 + Y + 1) * (Y^4 + Y^3 + 1) * (Y^4 + Y^3 + Y^2 + Y + 1)

# # print(X^4 + X^3 + 1)
# # print(X^4 + X^3 + X^2 + X + 1)













# print(top.reduce(Ideal([test])))

# for i in range(2^(n-1), 2^(n)):
# 	binary = str(bin(i)[2:])
# 	assert(len(binary) == 15)
# 	poly = X-X
# 	for i in range(1, len(binary)):
# 		if (int(binary[i])):
# 			poly = poly + X^i
# 	poly = poly + 1
# 	r = top % poly
# 	if (r == 0):
# 		print(binary)
# 		print(poly)
# 		print((top))
# 		print((top)/poly)
# 		print((((top)/poly) * poly))











# elements = []
# results = []

# for b in GF(Prime):
# 	elements.append(b)
# 	results.append(poly(b))

# print(elements)
# print(results)

# for b in GF(Prime^3):
# 	power = 1
# 	while True:
# 		print(b^power)
# 		if (b^power == 1):
# 			break
# 		power = power + 1

# 	print("element "+str(b)+" has order "+str(power))


# poly1 = a^3 + a^2 + a^1 + a^(-1)
# poly2 = a^2 + a + 1

#3.1, 3.2, 3.4, 3.7, 3.13, 3.14

#4.1, 4.8, 4.18, 4.20

#5.1, 5.2, 5.6, 5.10, 5.16, 5.17, 5.19, 

# print(poly1 * poly2)
# print(poly())


# 1a^5 + 1a^4 + 1a^3 + 1a^2 + 1
# 1a^5 + 1a^4 + 1a^3 + 1a^1 + 1
# 1a^5 + 1a^4 + 1a^2 + 1a^1 + 1
# 1a^5 + 1a^4 + 1 
# 1a^5 + 1a^3 + 1a^2 + 1a^1 + 1
# 1a^5 + 1a^3 + 1 
# 1a^5 + 1a^2 + 1
# 1a^5 + 1a^1 + 1 

# dividen a^4
# 			a^4 + a^3 + a^2 + a^0
#  		  ---------
# a^3+a^2+1 |	a^7
# 	      - a^7 + a^6 + a^4
# 	      ------
# 	        a^6 + a^4
# 	      - a^6 + a^5 + a^3
# 	      ------
# 	        a^5 + a^4 + a^3
# 	      - a^5 + a^4 + a^2
# 	      ------
# 	        a^3 + a^2
# 	      - a^3 + a^2
# 	      ------
# 	        0



	      



# dividen a^5 + a^1 + 1 

#          a^4 + a^3 + a^2 + a
#        -------------
#  a^1+1 | a^5 + a^1 + 1 
#  	   - a^5 + a^4
#  	   -----------
#  	   	 a^4 + a^1 + 1
#  	   - a^4 + a^3
#  	   -----------
#  	     a^3 + a^1 + 1
#  	   - a^3 + a^2
#  	   -----------
#  	     a^2 + a^1 + 1
#  	   - a^2 + a^1
#  	   -----------
#  	    1

# dividen a^5 + a^2 + 1

#          a^4 + a^3 + a^2
#        -------------
#  a^1+1 | a^5 + a^2 + 1
#  	   - a^5 + a^4
#  	   -----------
#  	     a^4 + a^2 + 1
#  	   - a^4 + a^3
#  	   -----------
#  	     a^3 + a^2 + 1
#  	     a^3 + a^2
#  	   -----------
#  	     1

# dividen a^5 + a^3 + 1

#          a^4 + a^3
#        -------------
#  a^1+1 | a^5 + a^3 + 1
#  	   - a^5 + a^4
#  	   -----------
#  	     a^4 + a^3 + 1
#  	   - a^4 + a^3
#  	   -----------
#  	     1

# dividen a^5 + a^4 + 1

#          a^4 + a^3
#        -------------
#  a^1+1 | a^5 + a^4 + 1
#  	   - a^5 + a^4
#  	   -----------
#  	     1

# dividen a^5 + a^3 + a^2 + a^1 + 1

#          a^4 + a^3 + a^1
#        -------------
#  a^1+1 | a^5 + a^3 + a^2 + a^1 + 1
#  	   - a^5 + a^4
#  	   -----------
#  	     a^4 + a^3 + a^2 + a^1 + 1
#  	   - a^4 + a^3
#  	   -----------
#  	     a^2 + a^1 + 1
#  	   - a^2 + a^1
#  	   -----------
#  	     1

# dividen a^5 + a^4 + a^2 + a^1 + 1

#          a^4 + a^1
#        -------------
#  a^1+1 | a^5 + a^4 + a^2 + a^1 + 1
#  	   - a^5 + a^4
#  	   -----------
#  	   	 a^2 + a^1 + 1
#  	   - a^2 + a^1
#  	   -----------
#  	     1

# dividen a^5 + a^4 + a^3 + a^1 + 1

#          a^4 + a^2 + a^1
#        -------------
#  a^1+1 | a^5 + a^4 + a^3 + a^1 + 1
#  	   - a^5 + a^4
#  	   -----------
#  	   	 a^3 + a^1 + 1
#  	   - a^3 + a^2
#  	   -----------
#  	     a^2 + a^1 + 1
#  	   - a^2 + a^1
#  	   -----------
#  	     1


# dividen a^5 + a^4 + a^3 + a^2 + 1

#          a^4 + a^2
#        -------------
#  a^1+1 | a^5 + a^4 + a^3 + a^2 + 1
#  	   - a^5 + a^4
#  	   -----------
#  	   	 a^3 + a^2 + 1
#  	   - a^3 + a^2
#  	   -----------
#  	     1


# dividen a^5 + a^1 + 1

#                a^3 + a^2 + 1
#        		 -----------------
#  a^2 + a + 1 | a^5 + a^1 + 1
#  			 - a^5 + a^4 + a^3
#  			 -----------
#  			   a^4 + a^3 + a^1 + 1
#  			 - a^4 + a^3 + a^2
#  			 -----------
#  			   a^2 + a^1 + 1
#  			 - a^2 + a^1 + 1
#  			 -----------
#  			   0

# dividen a^5 + a^2 + 1

#                a^3 + a^2
#        		 -----------------
#  a^2 + a + 1 | a^5 + a^2 + 1
#  			 - a^5 + a^4 + a^3
#  			 -----------
#  			   a^4 + a^3 + a^2 + 1
#  			 - a^4 + a^3 + a^2
#  			 -----------
#  			  1

# dividen a^5 + a^3 + 1

#                a^3 + a^2 + a^1
#        		 -----------------
#  a^2 + a + 1 | a^5 + a^3 + 1
#  			 - a^5 + a^4 + a^3
#  			 -----------
#  			   a^4 + 1
#  			 - a^4 + a^3 + a^2
#  			 -----------
#  			   a^3 + a^2 + 1
#  			 - a^3 + a^2 + a^1
#  			 -----------
#  			   a^1 + 1

# dividen a^5 + a^3 + a^2 + a^1 + 1

#                a^3 + a^2 + a^1 + a^0 
#        		 -----------------
#  a^2 + a + 1 | a^5 + a^3 + a^2 + a^1 + 1
#  			 - a^5 + a^4 + a^3
#  			 -----------
#  			   a^4 + a^2 + a^1 + 1
#  			 - a^4 + a^3 + a^2
#  			 -----------
#  			   a^3 + a^1 + 1
#  			 - a^3 + a^2 + a^1
#  			 -----------
#  			   a^2 + 1
#  			 - a^2 + a^1
#  			 -----------
#  			   a^1 + 1
 			


# dividen a^5 + a^4 + 1

#                a^3 + a^1 + a^0
#        		 -----------------
#  a^2 + a + 1 | a^5 + a^4 + 1
#  			 - a^5 + a^4 + a^3
#  			 -----------
#  			   a^3 + 1
#  			 - a^3 + a^2 + a^1
#  			 -----------
#  			  a^2 + a^1 + 1
#  			  a^2 + a^1
#  			 -----------
#  			  1


# dividen a^5 + a^4 + a^2 + a^1 + 1

#                a^3 + a^1
#        		 -----------------
#  a^2 + a + 1 | a^5 + a^4 + a^2 + a^1 + 1
#  			 - a^5 + a^4 + a^3
#  			 -----------
#  			   a^3 + a^2 + a^1 + 1
#  			 - a^3 + a^2 + a^1
#  			 -----------
#  			  1

# dividen a^5 + a^4 + a^3 + a^1 + 1

#                a^3 
#        		 -----------------
#  a^2 + a + 1 | a^5 + a^4 + a^3 + a^1 + 1
#  			 - a^5 + a^4 + a^3
#  			 -----------
#  			   a^1 + 1




# dividen a^5 + a^4 + a^3 + a^2 + 1

#                a^3 + a^0 
#        		 -----------------
#  a^2 + a + 1 | a^5 + a^4 + a^3 + a^2 + 1
#  			 - a^5 + a^4 + a^3
#  			 -----------
#  			   a^2 + 1
#  			 - a^2 + a^1
#  			 -----------
#  			   a^1 + 1






 			

 			  



 	  




 	   


 	    


 	     


 	 




# a^3+a^2+a+a^5+1

# 1+a^5+a^3
# /

# divisor a^1+1
# dividen a^5 + a^4 + 1

  #         a^4
		# ------------
  # a^1+1 | a^5 + a^4 + 1
  # 		  a^5 + a^4
  # 		------
  # 		  1



# divisor = a^2 + a + 1

# diviend = a^5 + a^3 + 1

# a^5/a^2 = a^3 

# 1/1 = 1

# a^3 * a^2+a+1 = a^5+a^4+a^3

# (a^5+a^3+1) - (a^5+a^4+a^3) = a^4+1

# a/a^2 = a

# a * a^2 + a + 1 = a^3 + a^2 + a




# a^5 + a^3 + 1
# -------
# a^2 + a + 1


# 			  a^3 
#             ---------------
# a^2 + a + 1 | a^5 + a^3 + 1





# 			  a^3 + a^2
#             ---------------
# a^2 + a + 1 | a^5 + 0a^4+ a^3 + 1
# 			  a^5 + a^4 + a^3
# 			--------
# 			  a^4 + 1
# 			  a^4 + a^3 + a^2
# 			--------
# 			  a^3 + a^2 + 1
# 			  a^3 + a^2 + a
# 			--------
# 			  a + 1

# a^3 + a^2

# a^5+a^3+1 = (a^2 + a + 1) * (a^3 + a^2) + (a + 1)


# 			  X^11 + X^8 + X^7 + X^5 + X^3 + X^2 + X + 1
#             ---------------
# X^4 + X + 1 | X^15 + 1
# 			  X^15 + X^12 + X^11
# 			------
# 			  X^12 + X^11 + 1
# 			  X^12 + X^9 + X^8
# 			------
#               X^11 + X^9 + X^8 + 1
#               X^11 + X^8 + X^7
#             ------
#               X^9 + X^7 + 1
#               X^9 + X^6 + X^5
#             ------
#               X^7 + X^6 + X^5 + 1
#               X^7 + X^4 + X^3
#             ------
#               X^6 + X^5 + X^4 + X^3 + 1
#               X^6 + X^3 + X^2
#             ------
#               X^5 + X^4 + X^2 + 1
#               X^5 + X^2 + X
#             ------
#               X^4 + X + 1
#               X^4 + X + 1
#             ------
#               0

	#      X^3 + 1
	# 	----------
 # X^3+1 | X^6+1
 # 		 X^6 + X^3
 # 		 -------
 # 		 X^3 + 1
 # 		 X^3 + 1






# X^5+X^4+X^3+X^2+1
# X^5+X^4+X^3+X+1
# X^5+X^4+X^2+X+1
# X^5+X^3+X^2+X+1
# X^5+X+1
# X^5+X^2+1
# X^5+X^3+1
# X^5+X^4+1
# X^5+X^4+X^3+X^2+X+1


# a^5 + a^4 + a^3 + a^2 + 1
# a^5 + a^4 + a^3 + a + 1
# a^5 + a^4 + a^2 + a + 1
# a^5 + a^4 + 1
# a^5 + a^3 + a^2 + a + 1
# a^5 + a^3 + 1
# a^5 + a^2 + 1





# poly1 = 1+a^1
# poly2 = 1+a^4


# #both poly1 and poly2 must a have a degree lesser than 5

# #for poly1 and poly2 to be non constant coeffs then it must have 1 + ...

# #If poly1 and poly2 have 1+ and they have deffirent degrees then it the resulting coeff will have both terms of poly1 and poly2

# #Because both powers of the terms of poly are relitivly prime 





# polyr = poly1*poly2

# print(poly)
# print(polyr)


# Prime = 2
# R.<a,X,Y,Z> = GF(Prime^4)[]

# elements = []

# for b in GF(Prime^4):
# 	elements.append(b)

# # for i in range(0, len(elements)):
# # 	b = elements[i]
# # 	power = 1
# # 	while b^power != 1 and b^power != 0:
# # 		# print(b^power)
# # 		power = power + 1
# # 	print(str(b)+" has order "+str(power)+" and its index is "+str(i))


# # 1,2,4,7,8,11,13,14
# primativeElements = [elements[1],elements[2],elements[4],elements[7],elements[8], elements[11], elements[13], elements[14]]



# poly1 = X+(a^5)*Y+Z
# poly2 = X+a*Y+(a^7)*Z
# poly3 = (a^2)*X+Y+(a^6)*Z

# poly1res = a^7
# poly2res = a^9
# poly3res = a

# #        [a, X, Y, Z]
# params = [elements[1], 1, 0, 1]
# print(elements[1])

# print(elements[1]^5)
# print((elements[1]^5)*elements[0])


# print("\n")
# print("poly1")
# print(poly1)
# print(poly1(params))
# print("poly1res")
# print(poly1res(params))
# print("\n")
# print("poly2")
# print(poly2)
# print(poly2(params))
# print("poly2res")
# print(poly2res(params))
# print("\n")
# print("poly3")
# print(poly3)
# print(poly3(params))
# print("poly3res")
# print(poly3res(params))
# print("\n")

# for a in primativeElements:
# 	for x in elements:
# 		for y in elements:
# 			for z in elements:
# 				params = [a, x, y, z]
# 				if (poly1(params) == poly1res(params) and poly2(params) == poly2res(params) and poly3(params) == poly3res(params)):
# 					print("finished: "+str(params))




# print(poly1(params) == poly1res(params))
# print(poly2(params) == poly2res(params))
# print(poly3(params) == poly3res(params))


# poly1 = X+(a^5)*Y+Z = a^7
# poly2 = X+a*Y+(a^7)*Z = a^9
# poly3 = (a^2)*X+Y+(a^6)*Z = a

# poly1 = X+a*Y+Z
# poly2 = X+a*Y+a*Z
# poly3 = a*X+Y+a*Z

# a = 1
# poly1 = X+Y+Z
# poly2 = X+Y+Z
# poly3 = X+Y+Z

# a = 0

# poly1 = X+Z
# poly2 = X
# poly3 = Y


