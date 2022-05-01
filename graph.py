import graphviz
dot = graphviz.Digraph()
for n in range(0, len(nodes)):
	for node in nodes[n]:
		dot.node(node['name'], 'cost: '+str(node['cost']))
for n in range(0, len(edges)):
	for edge in edges[n]:
		dot.edge(edge['from'], edge['to'])