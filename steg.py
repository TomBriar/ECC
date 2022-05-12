import hashlib
import struct
from datetime import datetime
import math
import random
import json
import itertools
import graphviz
import sys
import cv2
import numpy
sys.setrecursionlimit(2000000)

def ImgToCover(file, limit):
	img = cv2.imread(file)
	imageHeight = len(img)
	imageWidth = len(img[0])
	grayscale = type(img[0][0]) == type(numpy.uint8(0))
	counter = 0
	x = []
	xc = []
	for i in range(0, len(img)):
		for ii in range(0, len(img[i])):
			if (grayscale):
				print("error")
				# byte = img[i][ii]
			else:
				for iii in range(0, len(img[i][ii])):
					byte = img[i][ii][iii]
					byte = str(int(bin(byte)[2:]))
					for iiii in range(0, 8-len(byte)):
						byte = "0"+byte
					for iiii in range(0, len(byte)):
						if (iiii == 7):#LSB
							cost = 1
						else:
							cost = (imageHeight*imageWidth)*(8-iiii) #Extreamly high cost
						if (counter < limit):
							counter += 1
						else:
							return (x, xc)
						x.append(int(byte[iiii]))
						xc.append(cost)
	return (x, xc)

def bits2a(b):
	result = ""
	for i in range(0,int(len(b)/8)):
		bytearr = b[i*8:(i+1)*8]
		byte = ""
		for bit in bytearr:
			byte += str(bit)
		result += chr(int(byte, 2))
	return result


# print(imageHeight)
# print(imageWidth)

# print()
# img = cv2.imwrite('dog2.jpeg', img)

# error

def StrToCover(file, msg, weights=False):
	f = open(file, "r")
	a = f.read()
	size = (len(a)*8)**2
	assert(len(msg) < (size/2))
	x = []
	xc = []
	counter = 0
	for i in a:
		string = str(int(bin(ord(i))[2:]))
		for i in range(0, 8-len(string)):
			string = "0"+string
		string = list(string)
		for i in range(0, len(string)):
			cost = size
			if (i == 2):
				cost = 1
			x.append(int(string[i]))
			xc.append(cost)
	while (not (len(x)/len(msg)%1 == 0)):
		x.pop()
		xc.pop()
	# print(len(msg))
	# print(len(x))
	# error
	return (x, xc, a)	

def StrToMsg(msg):
	size = len(msg)**2
	result = []
	for i in msg:
		string = str(int(bin(ord(i))[2:]))
		for ii in range(0, 8-len(string)):
			string = "0"+string
		for ii in range(0, len(string)):
			result.append(int(string[ii:ii+1]))
	# assert(len(result) <= size)#Message must not be larger than target message length
	for i in range(0, size-len(result)):
		result.append(0)
	return result


useGraphviz = 0#Optional trellis rendering via Graphviz
if (useGraphviz):
	dot = graphviz.Digraph("mainGraph", strict=True, graph_attr={"rankdir": "LR"}) #Graphviz initilization.
# subH = [[1,0,1,1,0,1,0,1,1,1,1,1,1,0,0,1],[1,1,0,0,0,1,1,1,1,0,0,1,0,0,1,1]] # chosen randomly atm but h is height and w is width.
subH = [[],[]] #subH is a template for the subH generated randomly below
h = len(subH) #The height of the matrx, concerns the performance of the code.
mstr = "12"
m = StrToMsg(mstr) #Your message to encode.
print(mstr)
print(bits2a(m))
# print(mstr == bits2a(m))
# assert(mstr == bits2a(m))

#Example
# m = [0,1,1,1,1,0]
# m = [0,1,1,1]
# print("msg: "+str(m))
# x = [1,0,1,1,0,0,0,1]
# xc = [1,1,1,1,1,1,1,1]
# x = [1,1,1,0,0,0,1,1,1,0,0,0,1,1,1,0,0,0,1,0,1,0,0,0]
# xc = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
# x = [1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1]
# xc = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
coverFile = 'input.txt'
stegoFile = 'stegoinput.txt'
# coverFile = 'dog.jpeg'
# stegoFile = 'dog2.jpeg'
# (x, xc) = ImgToCover(coverFile, coverlength)
(x, xc, string) = StrToCover(coverFile, m)
assert((len(x) / len(m))%1 == 0) # make sure the bellow is an intager
w = int(len(x) / len(m)) #This is the rate of the code. This is also the width of the matrix.
# assert(w%8 == 0) #Confirm I can handle a whole byte with out a pruning interuption
# Generate ideal subH
for i in range(0, h):
	for ii in range(0, w):
		bit = random.getrandbits(1)
		if (i == h-1):
			bit = 1
		elif (ii == 0):
			bit = 1
		subH[i].append(bit)
		# subH[i].append(bit)
assert(w == len(subH[0])) #Assertation of the above.

#UTILS
def addEdge(edges, fromNode, toNode, output, cost):
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

def toNode(edges, node):
	result = []
	def filterfun(edge):
			if edge["to"] == node["name"]:
				return True
			else:
				return False
	for i in filter(filterfun, edges):
		result.append(i)
	return result

def getNodeByName(nodes, name):
	for node in nodes:
		if (node["name"] == name):
			return node

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
f = open("pubMatrix.txt", "w")
f.write(str(CH))


def findState(news, i):
	if (i <= len(news)-h):
		state = news[(i):(i+h)]
	else:
		state = news[(i):len(news)]
		for ii in range(0, h-len(state)):
			state.append(0)
	# state.reverse()
	statestr = ""
	for ii in range(0, len(state)):
		statestr += str(state[ii])
	state = statestr
	newbit = int(state, 2)
	return newbit

def findSyndrom(nodeName,i):
	state = int(nodeName[1])
	binary = bin(state)[2:]
	for ii in range(0, h-len(binary)):
		binary = "0"+binary
	# binary = binary[::-1]
	#Pad binary for position in message
	for ii in range(0, i):
		binary = "0"+binary
	while (len(binary) > len(CH[0])):
		binary = binary[:-1]
	while (len(binary) < len(CH[0])):
		binary = binary+"0"
	result = []
	binary = list(binary)
	for ii in range(0, len(binary)):
		result.append(int(binary[ii]))
	return result

assert(findState(findSyndrom((0,2),1),1) == 2)


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
			node = {"name": str(n)+"-"+str(i), "cost": 0}
			nslice.append(node)
		nodes.append(nslice)
	return (nodes, maxheight)

# (nodes, maxheight) = genNodes() #Generate an array of arrays for each set of nodes for each time slice

def genEdges():
	#Initialize varibles
	originNode = "" 
	edges = [[]] #edges of trellis
	nodeIndex = 0
	nodes = [[{"name": "0-0", "cost": 0}],[]]
	for i in range(0, len(m)): #run once per bit of message
		for ii in range(0, w): #run w where w = len(x)*w = len(m)
			index = (i*w)+ii
			startNodes = nodes[nodeIndex]
			coverbit = x[index] #The bit of the cover object we are currently using
			weightedCost = xc[index]
			cost0 = coverbit*weightedCost #The cost of not adding this column of H. Computed by the weighted cost multiplyed by the existiance of having to not add it either way
			cost1 = 1 #The oposite of above
			if (coverbit):
				cost1 = 0
			cost1 = cost1*weightedCost
			# print(coverbit, cost0, cost1)
			newNodes = []
			for iii in range(0, len(startNodes)): #Loop through each of the starting nodes
				name = startNodes[iii]["name"].split("-")
				startNode = (int(name[0]), int(name[1]), startNodes[iii]["cost"])
				state = findSyndrom(startNode, i)
				#don't add
				node = (startNode[0]+1, startNode[1])
				formatnode = {"name": str(startNode[0]+1)+"-"+str(startNode[1]), "cost": 0}
				if (getNodeByName(nodes[nodeIndex+1], formatnode["name"]) == None):
					nodes[nodeIndex+1].append(formatnode)
				edge = {"from": startNodes[iii]["name"], "to": str(node[0])+"-"+str(node[1]), "output": 0, "cost": cost0}
				edges[nodeIndex].append(edge)
				#add
				news = xor(state, CH[index]) #Compute the current syndrom + the index column of H
				newbit = findState(news, i) #Find the corisponding trellis state of the new syndrom
				node = (startNode[0]+1, newbit)
				formatnode = {"name": str(startNode[0]+1)+"-"+str(newbit), "cost": 0}
				if (getNodeByName(nodes[nodeIndex+1], formatnode["name"]) == None):
					nodes[nodeIndex+1].append(formatnode)
				edge = {"from": startNodes[iii]["name"], "to": str(node[0])+"-"+str(node[1]), "output": 1, "cost": cost1}
				edges[nodeIndex].append(edge)
			##Post n slice
			for node in nodes[nodeIndex+1]:
				paths = toNode(edges[nodeIndex], node)
				costs = []
				for path in paths:
					sourceNode = getNodeByName(nodes[nodeIndex], path["from"])
					totalPathCost = sourceNode["cost"] + path['cost']
					costs.append(totalPathCost)
				if (len(costs) > 0):
					mincost = costs[0]
					for cost in costs:
						if cost < mincost:
							mincost = cost
					node['cost'] = mincost
			nodeIndex += 1
			nodes.append([])
			edges.append([])
		startNodes = nodes[nodeIndex]
		for ii in range(0, len(startNodes)):
			name = startNodes[ii]["name"].split("-")
			startNode = (int(name[0]), int(name[1]), startNodes[ii]["cost"])
			state = findSyndrom(startNode, i)
			if (state[i] == m[i]): #Prune our current list of starting nodes before the next run by matching the message bit that will be unchangable after this point
				newbit = findState(state, i+1) #Find the new state based on the next index.
				node = (startNode[0]+1, newbit)
				formatnode = {"name": str(startNode[0]+1)+"-"+str(newbit), "cost": startNode[2]}
				if (getNodeByName(nodes[nodeIndex+1], formatnode["name"]) == None):
					nodes[nodeIndex+1].append(formatnode)
				edge = {"from": startNodes[ii]["name"], "to": formatnode["name"], "output": 2, "cost": 0}
				edges[nodeIndex].append(edge)
		nodeIndex += 1
		nodes.append([])
		edges.append([])
	originNode = nodes[nodeIndex][0] #Get the furthest node from the start
	nodes.pop()
	edges.pop()
	return (edges, originNode, nodes)
(edges, originNode, nodes) = genEdges() #Generate the edges between the nodes.


def minPath(oNode):
	inde = int(oNode["name"].split("-")[0])
	output = []
	originNode = nodes[inde][0]
	for i in range(0, inde):
		index = inde-i
		paths = toNode(edges[index-1], originNode)
		nodepaths = []
		for path in paths:
			nodepaths.append([getNodeByName(nodes[index-1],path['from']),path])
		minNode = nodepaths[0]
		for node in nodepaths:
			if node[0]['cost']+node[1]['cost'] < minNode[0]['cost']+minNode[1]['cost']:
				minNode = node 
		if (useGraphviz):
			dot.edge(minNode[0]['name'], originNode['name'], color='red')
		if (minNode[1]['output'] != 2):
				output.insert(0, (int(minNode[1]['output'])))
		print(minNode[0]["name"])
		originNode = minNode[0]
	return output
result = minPath(originNode) # Backwards pass of the vertui algorithim
print("m  : "+str(m))
print("syn: "+str(MatrixMulti(H, result)))
print("cost: "+str(originNode["cost"]))


print(bits2a(MatrixMulti(H, result)))
# print(MatrixMulti(H, result))
assert(MatrixMulti(H, result) == m)
# assert(== mstr)
# print(result)
# print(strresult)


f = open("stego"+coverFile, "w")
f.write(bits2a(result))
# print(bits2a(strresult))
# print(string[:int(coverlength/8)])
# print(originNode)
# def reBuildImg():
# 	img = cv2.imread(coverFile)
# 	imageHeight = len(img)
# 	imageWidth = len(img[0])
# 	grayscale = type(img[0][0]) == type(numpy.uint8(0))
# 	counter = 0
# 	for i in range(0, len(img)):
# 		for ii in range(0, len(img[i])):
# 			if (grayscale):
# 				# img[i][ii][]
# 				return "error"
# 			else:
# 				for iii in range(0, len(img[i][ii])):
# 					if (counter < len(result)):
# 						newbyte = ""
# 						for iiii in range(0, 8):
# 							newbyte += str(result[counter+iiii])
# 						print("--")
# 						print(newbyte)
# 						print(bin(img[i][ii][iii])[2:])
# 						newbyte = numpy.uint8(int(newbyte, 2))
# 						print(newbyte)
# 						print(img[i][ii][iii])
						
# 						img[i][ii][iii] = newbyte
# 						counter += 8
# 					else:
# 						return img
# img = reBuildImg()
# cv2.imwrite(stegoFile, img)
# print(originNode)

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
	for edgeN in edges:
		for edge in edgeN:
			dot.edge(edge['from'], edge['to'], xlabel=str(edge['output'])+" = "+str(edge['cost'])[:5], rank="same")
	dot.render('doctest-output/trellis.gv').replace('\\', '/')
	dot.render('doctest-output/trellis.gv', view=True) 

if (useGraphviz):
	render() #Optional grahpviz rendering




