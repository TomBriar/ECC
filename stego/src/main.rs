// use std::io;
// use rand::Rng;
// use std::cmp::Ordering;


fn main() {
    println!("Hello, world!");
    
    // let secret_number = rand::thread_rng().gen_range(1..101);
    
    const MESSAGE_LENGTH: usize = 4;
    const MESSAGE: [i32; MESSAGE_LENGTH] = [0, 1, 1, 1];
    const COVER_LENGTH: usize = 8;
    const COVER_OBJECT: [i32; COVER_LENGTH] = [1, 0, 1, 1, 0, 0, 0, 1]; 
    const COVER_WEIGHTS: [i32; COVER_LENGTH] = [1, 1, 1, 1, 1, 1, 1, 1];
    const SUB_H: [[i32; 2]; 2]  = [[1, 0], [1, 1]];
    const SUB_WIDTH: usize = COVER_OBJECT.len()/MESSAGE.len(); //rate of the encoding or the width of the sub matrix H
    const SUB_HEIGHT: usize = SUB_H.len(); //performance parameter
    assert!(SUB_WIDTH == SUB_H[0].len()); //SUB_WIDTH is rate of code and width of sub matrix
    assert!((SUB_WIDTH % 1) == 0); //rate of code must be an intager
    const EXT_HEIGHT: usize = MESSAGE.len(); //extended matrix H height
    const EXT_WIDTH: usize = COVER_OBJECT.len(); //extended matrix W width
    let mut EXT_H = [[0i32; EXT_WIDTH]; EXT_HEIGHT]; //extended matrix

    //BUILD H
    let mut row = 0;
    let mut column = 0;
    'B: for i in 0..(EXT_WIDTH/SUB_WIDTH) {
    	for ii in 0..SUB_HEIGHT {
    		for iii in 0..SUB_WIDTH {
    			if (row+ii >= EXT_HEIGHT) || (column+iii >= EXT_WIDTH) {
    				break 'B
    			}
    			EXT_H[row+ii][column+iii] = SUB_H[ii][iii];
    		}
    	}
    	row += 1;
		column = column+SUB_WIDTH;
    }
    let mut EXT_CH = [[0i32; EXT_HEIGHT]; EXT_WIDTH]; //extended matrix
    for i in 0..EXT_H[0].len() {
    	for ii in 0..EXT_H.len() {
    		EXT_CH[i][ii] = EXT_H[ii][i];
    	}
    }
    // const EXT_CH_CON: [[i32; EXT_HEIGHT]; EXT_WIDTH] = EXT_CH;

	fn xor(c: &mut [i32; EXT_HEIGHT], d: [i32; EXT_HEIGHT]) {
		for i in 0..(c.len()) {
			c[i] = (c[i] + d[i]) % 2;
		}
	}

	fn syndrom(s: &mut [i32; EXT_HEIGHT], matrix: [[i32; EXT_WIDTH]; EXT_HEIGHT], cover: [i32; EXT_WIDTH]) {
		for i in 0..EXT_HEIGHT {
			let mut bit = 0;
			for ii in 0..EXT_WIDTH {
				bit += (matrix[i][ii]*cover[ii]) % 2;
			}
			s[i] = bit % 2;
		}
	}

	// let mut s = [0i32; 4];
	// syndrom(&mut s, ext_h, X);
	// for i in 0..s.len() {
	// 	println!("{}", s[i]);
	// }

	fn find_syndrom(s: &mut [i32; EXT_HEIGHT], name: i32, index: usize) {
		// let indexs: Vec<&str> = name.split("-").collect();
		// let name1: i32 = indexs[1].parse().unwrap();
		let mut binary: String = format!("{:b}", name);
		for i in 0..(SUB_HEIGHT-binary.len()) {
			let filler: String = String::from("0");
			binary = filler+&binary;
		}
		for i in 0..(index) {
			let filler: String = String::from("0");
			binary = filler+&binary;
		}
		if EXT_HEIGHT < binary.len() {
			binary = binary[0..EXT_HEIGHT].to_string();
		} else {
			for i in 0..(EXT_HEIGHT-binary.len()) {
				let filler: String = String::from("0");
				binary = binary+&filler;
			}
		}
		assert!(binary.len() == EXT_HEIGHT);
		let char_vec: Vec<&str> = binary.trim().split("").collect();
	    for i in 1..char_vec.len()-1 {
	    	// println!("{}", char_vec[i]);
	        s[i-1] = char_vec[i].parse().unwrap()
	    }
	}

	fn find_state(r: &mut i32, s: [i32; EXT_HEIGHT], index: usize) {
		let mut result: String = String::new();
		for i in 0..s.len() {
			result = result+(&s[i].to_string());
		}
		if index <= (s.len()-SUB_HEIGHT).try_into().unwrap() {
			result = result[index..(index+SUB_HEIGHT)].to_string();
		} else {
			result = result[index..(result.len())].to_string();
		}
		let newbit = isize::from_str_radix(&result, 2).unwrap();
		*r = newbit as i32;
	}

	let mut e = [0i32; EXT_HEIGHT];
	let name = 2;
	for i in 0..(EXT_HEIGHT-1) {
		find_syndrom(&mut e, name, i);
		let mut newbit: i32 = 0;
		find_state(&mut newbit, e, i);
		assert!(newbit == name);
	}
		

	// #[derive(Copy, Clone)]
	#[derive(PartialEq, Eq, PartialOrd, Ord, Copy, Clone)]
	struct Node {
	    name1: i32,
	    name2: i32,
	    cost: i32
	}

	impl Node {
		fn new_empty() -> Node {
	        Node{
	            name1: 0,
	            name2: 0,
	            cost: 0
	        }
	    }
	    fn new(name1: i32, name2: i32, cost: i32) -> Node {
	        Node{
	            name1: name1,
	            name2: name2,
	            cost: cost
	        }
	    }
	    fn print(&self) {
	    	println!("{}-{} cost: {}",self.name1, self.name2, self.cost);
	    }
	}
	#[derive(PartialEq, Eq, PartialOrd, Ord, Copy, Clone)]
	struct Edge {
	    to1: i32,
	    to2: i32,
	    from1: i32,
	    from2: i32,
	    cost: i32
	}

	impl Edge {
	    fn new(from1: i32, from2: i32, to1: i32, to2: i32, cost: i32) -> Edge {
	        Edge{
	            to1: to1,
	            to2: to2,
	            from1: from1,
	            from2: from2,
	            cost: cost
	        }
	    }
	    fn print(&self) {
	    	println!("from {}-{} to {}-{} cost: {}",self.from1, self.from1, self.to1, self.to2, self.cost);
	    }
	}

	fn to_node<'a>(paths: &mut Vec<&'a Edge>, edges: &'a mut Vec<Vec<Edge>>, node: &Node) {
		for i in 0..edges[((node.name1-1) as usize)].len() {
			if edges[((node.name1-1) as usize)][i].to2 == node.name2 {
				paths.push(&edges[((node.name1-1) as usize)][i]);
			}
		}
	}

	// fn get_node<'a>(node: &mut &'a Node, nodes: &'a mut Vec<Vec<Node>>, edge: &Edge) {
	// 	let mut barrow = &nodes[0][0];
	// 	for i in 0..nodes[((edge.from1) as usize)].len() {
	// 		if nodes[((edge.from1) as usize)][i].name2 == edge.from2 {
	// 			barrow = &nodes[((edge.from1) as usize)][i];
	// 			node = &mut barrow;
	// 		}
	// 	}
	// }

	//HashMap
	let mut nodes: Vec<Vec<Node>> = Vec::new();
	nodes.push(Vec::new());
	nodes[0].push(Node::new(0, 0, 0));
	let mut edges: Vec<Vec<Edge>> = Vec::new();
	edges.push(Vec::new());
	

	
	fn forward_pass(nodes: &mut Vec<Vec<Node>>, edges: &mut Vec<Vec<Edge>>, ch: [[i32; EXT_HEIGHT]; EXT_WIDTH]) {
		let mut node_index: usize = 0;
		for i in 0..2 {//EXT_HEIGHT
			for ii in 0..SUB_WIDTH {//SUB_WIDTH
				let index: usize = (i*SUB_WIDTH)+ii;
				// println!("nodeindex {}, index {}", node_index, index);
				// for ii in 0..nodes[node_index].len() {
				// 	nodes[node_index][ii].print();
				// }
				nodes.push(Vec::new());
				edges.push(Vec::new());
				let coverbit: i32 = COVER_OBJECT[index];
				let weight: i32 = COVER_WEIGHTS[index];
				let mut cost1: i32 = 1*weight;
				let mut cost0: i32 = 1*weight;
				if coverbit == 1 {
					cost0 = 0
				} else {
					cost1 = 0
				}
				for iii in 0..nodes[node_index].len() {
					let start_node: &Node = &nodes[node_index][iii];
					let mut syndrom = [0i32; EXT_HEIGHT];
					find_syndrom(&mut syndrom, start_node.name2, i);
					xor(&mut syndrom, ch[index]);
					// for i in 0..syndrom.len() {
					// 	println!("{}",syndrom[i]);
					// }
					let mut newbit: i32 = 0;
					find_state(&mut newbit, syndrom, i);
					let node0 = Node::new(start_node.name1+1, start_node.name2, 0);
					let node1 = Node::new(start_node.name1+1, newbit, 0);
					let edge0 = Edge::new(start_node.name1, start_node.name2, start_node.name1+1, start_node.name2, cost0);
					let edge1 = Edge::new(start_node.name1, start_node.name2, start_node.name1+1, newbit, cost1);
					edges[node_index].push(edge0);
					edges[node_index].push(edge1);
					nodes[node_index+1].push(node0);
					nodes[node_index+1].push(node1);
				}
				// println!("N over");
				// for ii in 0..nodes[node_index+1].len() {
				// 	nodes[node_index+1][ii].print();
				// }
				edges[node_index].sort();
				edges[node_index].dedup();
				nodes[node_index+1].sort();
				nodes[node_index+1].dedup();
				// println!("E over");
				// for ii in 0..nodes[node_index+1].len() {
				// 	nodes[node_index+1][ii].print();
				// }
				node_index += 1;
				for iii in 0..nodes[node_index].len() {
					let mut paths: Vec<&Edge> = Vec::new();
					let node: &Node = &nodes[node_index][iii];
					to_node(&mut paths, edges, node);
					let mut min_path: &Edge = paths[0];
					let mut min_node: &Node = &Node::new_empty();
					for i in 0..nodes[((min_path.from1) as usize)].len() {
						if nodes[((min_path.from1) as usize)][i].name2 == min_path.from2 {
							min_node = &nodes[((min_path.from1) as usize)][i];
						}
					}
					for i in 1..paths.len() {
						let path = paths[i];
						let mut temp_node: &Node = &nodes[node_index][1];
						for i in 0..nodes[((path.from1) as usize)].len() {
							if nodes[((path.from1) as usize)][i].name2 == path.from2 {
								min_node = &nodes[((path.from1) as usize)][i];
							}
						}
						// println!("path.cost = {}, temp_node.cost = {}, min_path.cost = {}, min_node.cost {}", path.cost, temp_node.cost, min_path.cost, min_node.cost);
						if (path.cost + temp_node.cost) < (min_path.cost + min_node.cost) {
							min_path = paths[i];
							min_node = temp_node;
						}
					}
					nodes[node_index][iii].cost = min_path.cost + min_node.cost;
				}
			}
			nodes.push(Vec::new());
			edges.push(Vec::new());
			// println!("PRUNE");
			for iii in 0..nodes[node_index].len() {
				let mut paths: Vec<&Edge> = Vec::new();
				let node: &Node = &nodes[node_index][iii];
				// node.print();
				let mut syndrom = [0i32; EXT_HEIGHT];
				find_syndrom(&mut syndrom, node.name2, i);
				if syndrom[i] == MESSAGE[i] {
					let mut newbit = 0;
					if i == (MESSAGE.len()-1) {
						find_state(&mut newbit, syndrom, i);
					} else {
						find_state(&mut newbit, syndrom, i+1);
					}
					let newnode = Node::new(node.name1+1, newbit, 0);
					// newnode.print();
					let newedge = Edge::new(node.name1, node.name2, node.name1+1, newbit, 2);
					edges[node_index].push(newedge);
					nodes[node_index+1].push(newnode);
					// let mut node: Node = nodes[0][0].clone()
				}
			}
			node_index += 1;
			// println!("END PRUNE");
		}
	}

	forward_pass(&mut nodes, &mut edges, EXT_CH);

	// for i in 0..nodes.len() {
	// 	println!("time slice {}",i);
	// 	for ii in 0..nodes[i].len() {
	// 		nodes[i][ii].print();
	// 	}
	// }

	fn backward_pass(nodes: &mut Vec<Vec<Node>>, edges: &mut Vec<Vec<Edge>>, ch: [[i32; EXT_HEIGHT]; EXT_WIDTH]) {

	}




	// let mut a = [0, 1, 1];
	// let b = [0, 0, 1];
	// xor(&mut a,b);
	// for i in 0..a.len() {
	// 	println!("{}",a[i]);
	// }

    // for i in 0..ext_height {
    // 	for ii in 0..ext_width {
    // 		print!("{}",ext_h[i][ii]);
    // 	}
    // }
    












 //    loop {
 //    	guess = String::new();
 //    	io::stdin()
 //        .read_line(&mut guess)
 //        .expect("Failed to read line");
 //        println!("You guessed: {}", guess);
	//     let guess: u32 = guess.trim().parse().expect("Please type a number!");
	//     println!("It was: {}",secret_number);
	//     match guess.cmp(&secret_number) {
	//         Ordering::Less => println!("Too small!"),
	//         Ordering::Greater => println!("Too big!"),
	//         Ordering::Equal => {
	//         	println!("You win!");
	//         	break
	//         },
	//     };
	// };
}
