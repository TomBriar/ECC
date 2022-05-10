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
import json

stegoFile = 'dog2.jpeg'
stegoLength = 512 #Will be standard

def ImgToCover(file, limit):
	img = cv2.imread(file)
	imageHeight = len(img)
	imageWidth = len(img[0])
	grayscale = type(img[0][0]) == type(numpy.uint8(0))
	counter = 0
	x = []
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
						if (counter < limit):
							counter += 1
						else:
							return x
						x.append(int(byte[iiii]))
	return x

stegoObj = ImgToCover(stegoFile, stegoLength)
f = open("pubMatrix.txt", "r")
CH = json.loads(f.read())#Public matrix



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

def bits2a(b):
	result = ""
	for i in range(0,int(len(b)/8)):
		bytearr = b[i*8:(i+1)*8]
		byte = ""
		for bit in bytearr:
			byte += str(bit)
		result += chr(int(byte, 2))
	return result

# print(bits2a(stegoObj))
result = MatrixMulti(CH, stegoObj)
print(bits2a(result))

# print("result = CH * stegoObj = "+str())




