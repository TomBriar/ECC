use std::collections::HashMap;
use image::io::Reader as ImageReader;
use image::{GenericImageView, Rgba};
use std::io::{stdin,stdout,Write};
use std::time::Instant;



fn main() {

	let mut cover_object: Vec<i8> = Vec::new();
	let mut cover_weights: Vec<i8> = Vec::new();
	// let img = match ImageReader::open("../dog.jpeg") {
	// 	Ok(reader) => match reader.decode() {
	// 		Ok(img) => img,
	// 		Err(e) => panic!("{}", e),
	// 	},
	// 	Err(e) => panic!("{}", e),
	// };
	// for i in 0..img.height() {
	// 	for ii in 0..img.width() {
	// 		let pixel = img.get_pixel(ii, i);
	// 		let r = pixel[0];
	// 		let mut r_byte = format!("{r:b}");
	// 		for _ in 0..(8-r_byte.len()) {
	// 			let filler: String = String::from("0");
	// 			r_byte = filler+&r_byte
	// 		}
	// 		let r_lsb = r_byte.pop().expect("Never panic").to_string().parse::<i8>().unwrap();
	// 		// println!("{}", Rbyte);
	// 		// println!("{}", );
	// 		cover_object.push(r_lsb);
	// 		cover_weights.push(1);
	// 	}
	// }
	// const sss: &str = "test";
	// const MESSAGE_LENGTH: usize = sss.len();
	// let mut s = String::new();
 //    print!("Please enter some text: ");
 //    let _=stdout().flush();
 //    stdin().read_line(&mut s).expect("Did not enter a correct string");
 //    s = s.trim().to_string();
 //    // println!("trimed {}", s);

	// // let msg_string = "t";
	// let mut message = Vec::<i8>::new();
	// for m in s.bytes() {
	// 	let mut binary = format!("{m:b}");
	// 	for _ in 0..(8-binary.len()) {
	// 		let filler: String = String::from("0");
	// 		binary = filler+&binary
	// 	}
	// 	for i in binary.chars() {
	// 		// println!("teste {}", );
	// 		message.push(i.to_string().parse::<i8>().unwrap());
	// 	}
	// }
	let mut message = Vec::new();
	message.push(0);
	message.push(1);
	message.push(1);
	message.push(1);

	cover_object.push(1);
	cover_weights.push(1);
	cover_object.push(0);
	cover_weights.push(1);
	cover_object.push(1);
	cover_weights.push(1);
	cover_object.push(1);
	cover_weights.push(1);
	cover_object.push(0);
	cover_weights.push(1);
	cover_object.push(0);
	cover_weights.push(1);
	cover_object.push(0);
	cover_weights.push(1);
	cover_object.push(1);
	cover_weights.push(1);


	

	// while cover_object.len()%message.len() != 0 {
	// 	cover_object.pop();
	// }

	let sub_width = cover_object.len()/message.len(); //rate of the encoding or the width of the sub matrix H
    let sub_height = 2; //performance parameter
    let mut sub_h: Vec<Vec<i8>> = Vec::new();
    // for i in 0..sub_width {
    // 	sub_h.push(Vec::new());
    // 	for _ in 0..sub_height {
    // 		// if rand::random() {
    // 			sub_h[i].push(1);
    // 		// } else {
    // 			// sub_h[i].push(0);
    // 		// }
    // 	} 
    // }
    sub_h.push(Vec::new());
    sub_h[0].push(1);
    sub_h[0].push(0);
    sub_h.push(Vec::new());
    sub_h[1].push(1);
    sub_h[1].push(1);

    let mut sub_ch: Vec<Vec<i8>> = Vec::new();
    for i in 0..sub_width {
    	sub_ch.push(Vec::new());
    	for ii in 0..sub_height {
    		sub_ch[i].push(sub_h[ii][i]);
    	}
    }
    for i in 0..sub_width {
    	for ii in 0..sub_height {
    		println!("sub[{}][{}] = {}",i, ii, sub_ch[i][ii]);
    	}
    }
 
    let ext_height = message.len(); //extended matrix H height
    let ext_width = cover_object.len(); //extended matrix W width



    // const message_LENGTH: usize = 4;
    
    // const COVER_LENGTH: usize = 12;
    // const cover_object: [i8; COVER_LENGTH] = [1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0]; 
    // const cover_weights: [i8; COVER_LENGTH] = [-2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    // const sub_width: usize = cover_object.len()/message.len(); //rate of the encoding or the width of the sub matrix H
    // const sub_height: usize = 3; //performance parameter
    // const sub_h: [[i8; sub_width]; sub_height]  = [[1, 1, 0], [0, 1, 0], [0, 0, 1]];
    // assert!(sub_width == sub_h[0].len()); //sub_width is rate of code and width of sub matrix
    // assert!((sub_width % 1) == 0); //rate of code must be an intager
    // const ext_height: usize = message.len(); //extended matrix H height
    // const ext_width: usize = cover_object.len(); //extended matrix W width
    let mut ext_h: Vec<Vec<i8>> = Vec::new(); //extended matrix
    for i in 0..(ext_height) {
    	ext_h.push(Vec::new());
    	for _ in 0..ext_width {
    		ext_h[i].push(0);
    	}
    }
    let mut ext_ch: Vec<Vec<i8>> = Vec::new(); //extended matrix column oriented
    for i in 0..(ext_width) {
    	ext_ch.push(Vec::new());
    	for _ in 0..ext_height {
    		ext_ch[i].push(0);
    	}
    }


    //BUILD H
    let mut row = 0;
    let mut column = 0;
    'B: for _ in 0..(ext_width/sub_width) {
    	for ii in 0..sub_height {
    		for iii in 0..sub_width {
    			if (row+ii >= ext_height) || (column+iii >= ext_width) {
    				break 'B
    			}
    			ext_h[row+ii][column+iii] = sub_h[ii][iii];
    		}
    	}
    	row += 1;
		column = column+sub_width;
    }
    
    for i in 0..ext_h[0].len() {
    	for ii in 0..ext_h.len() {
    		ext_ch[i][ii] = ext_h[ii][i];
    	}
    }

	fn xor(c: &mut Vec<i8>, d: &Vec<i8>) {
		for i in 0..(c.len()) {
			c[i] = (c[i] + d[i]) % 2;
		}
	}

	fn matrix_multi(s: &mut Vec<i8>, x: &mut Vec<i8>, ch: &Vec<Vec<i8>>, ext_height: usize) {
		for i in 0..ext_height {
			s.push(0);
		}
		for i in 0..ch.len() {
			for ii in 0..ext_height {
				s[ii] += (x[i]*ch[i][ii])%2;
			}
		}
		for ii in 0..ext_height {
			s[ii] = s[ii]%2;
		}
	}

	fn find_syndrom(s: &mut Vec<i8>, name: i32, index: usize, sub_height: usize) {
		let time = Instant::now();
		let mut binary: String = format!("{:b}", name);
		while s.len()+binary.len() < sub_height {
			s.push(0)
		}
		
		let char_vec: Vec<&str> = binary.trim().split("").collect();
	    for i in 1..char_vec.len()-1 {
	        s.push(char_vec[i].parse::<i8>().unwrap())
	    }
	    // println!("time4 = {}", time.elapsed().as_nanos());
	}
	// let mut syndrom: Vec<i8> = Vec::new();
	// find_syndrom(&mut syndrom, 3, 0, ext_height, sub_height);
	// let _ = stdout().flush();
	// let _ = stdin().read_line(&mut "".to_string()).unwrap();
			

	fn find_state(r: &mut i32, s: &mut Vec<i8>, index: usize, ext_height: usize, sub_height: usize) {
		let mut result: String = String::new();
		while s.len()+result.len() < sub_height {
			result = result+&("0".to_string());
		}
		while s.len()+index > ext_height {
			s.pop();
		} 
		for i in 0..s.len() {
			result = result+(&s[i].to_string());
		}
		
		let newbit = isize::from_str_radix(&result, 2).unwrap();
		*r = newbit as i32;
	}
	// let mut s = Vec::new();
	// s.push(1);
	// s.push(1);
	// let mut r = 0;
	// find_state(&mut r, s, 0, 2);
	// println!("{}", r);
	// let _ = stdout().flush();
	// let _ = stdin().read_line(&mut "".to_string()).unwrap();

	// #[derive(Copy, Clone)]
	#[derive(PartialEq, Eq, PartialOrd, Ord, Copy, Clone, Hash)]
	struct Node {
	    name1: i32,
	    name2: i32,
	    cost: i8
	}

	impl Node {
		fn new_empty() -> Node {
	        Node{
	            name1: 0,
	            name2: 0,
	            cost: 0
	        }
	    }
	    fn new(name1: i32, name2: i32, cost: i8) -> Node {
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
	#[derive(PartialEq, Eq, PartialOrd, Ord, Copy, Clone, Hash)]
	struct Edge {
	    to1: i32,
	    to2: i32,
	    from1: i32,
	    from2: i32,
	    cost: i8,
	    output: i8
	}

	impl Edge {
	    fn new(from1: i32, from2: i32, to1: i32, to2: i32, cost: i8, output: i8) -> Edge {
	        Edge{
	            to1: to1,
	            to2: to2,
	            from1: from1,
	            from2: from2,
	            cost: cost,
	            output: output
	        }
	    }
	    fn print(&self) {
	    	println!("from {}-{} to {}-{} cost: {}, output: {}",self.from1, self.from2, self.to1, self.to2, self.cost, self.output);
	    }
	}

	fn get_node(r_node: &mut Node, nodes: &Vec<Node>, node_index: i32) {
		for i in 0..nodes.len() {
			if nodes[i].name2 == node_index {
				let new_node = nodes[i].clone();
				*r_node = new_node;
			}
		}
	}


	fn to_node(paths: &mut Vec<Edge>, edges: &Vec<Edge>, node: &Node) {
		for i in 0..edges.len() {
			if edges[i].to2 == node.name2 {
				let new_edge = edges[i].clone();
				paths.push(new_edge);
			}
		}
	}

	let mut nodes: Vec<Vec<Node>> = Vec::new();
	nodes.push(Vec::new());
	nodes[0].push(Node::new(0, 0, 0));
	let mut edges: Vec<Vec<Edge>> = Vec::new();


	
	fn forward_pass(nodes: &mut Vec<Vec<Node>>, edges: &mut Vec<Vec<Edge>>, ch: &Vec<Vec<i8>>, ext_height: usize, sub_width: usize, sub_height: usize, cover_object: &Vec<i8>, cover_weights: Vec<i8>, message: Vec<i8>) {
		let mut node_index: usize = 0;
		
		println!("exth = {}, sub_width = {}", ext_height, sub_width);
		for i in 0..ext_height {//ext_height
			for ii in 0..sub_width {//sub_width
				let index: usize = (i*sub_width)+ii;
				// println!("index {}", index);
				// println!("ext[{}]...", index);
				// for iii in 0..sub_height {
				// 	print!("{}, ", ch[index][iii]);
				// }
				// println!(";");
				let coverbit: i8 = cover_object[index];
				let weight: i8 = cover_weights[index];
				let mut cost1: i8 = coverbit;
				let mut cost0: i8;
				if coverbit == 1 {
					cost0 = 0
				} else {
					cost0 = 1
				}
				cost1 = cost1*weight;
				cost0 = cost0*weight;
				let mut new_nodes: HashMap<Node, i8> = HashMap::new();
				let mut new_edges: HashMap<Edge, i8> = HashMap::new();
				for iii in 0..nodes[node_index].len() {
					let start_node: &Node = &nodes[node_index][iii];
					println!("START----------------");
					println!("index {}", index);
					start_node.print();
					let mut syndrom: Vec<i8> = Vec::new();
					find_syndrom(&mut syndrom, start_node.name2, i, sub_height);
					print!("synd obj = ");
					for i in 0..syndrom.len() {
						print!("{}, ", syndrom[i]);
					}
					println!("done");
					xor(&mut syndrom, &ch[ii]);
					syndrom.reverse();
					print!("synd obj = ");
					for i in 0..syndrom.len() {
						print!("{}, ", syndrom[i]);
					}
					println!("done");
					print!("ch obj = ");
					for i in 0..ch[ii].len() {
						print!("{}, ", ch[ii][i]);
					}
					println!("done");
					let mut newbit: i32 = 0;
					find_state(&mut newbit, &mut syndrom, i, ext_height, sub_height);
					println!("bit {}",newbit);
					if cost1 != -2 {
						let node0 = Node::new(start_node.name1+1, start_node.name2, 0);
						let edge0 = Edge::new(start_node.name1, start_node.name2, start_node.name1+1, start_node.name2, cost1, 0);
						new_nodes.insert(node0, 0);
						new_edges.insert(edge0, 0);
					}
					if cost0 != -2 {
						let node1 = Node::new(start_node.name1+1, newbit, 0);
						let edge1 = Edge::new(start_node.name1, start_node.name2, start_node.name1+1, newbit, cost0, 1);
						new_edges.insert(edge1, 0);
						new_nodes.insert(node1, 0);
					}
				}
				// println!("time = {}, sw = {}", time.elapsed().as_nanos(), sub_width);

				nodes.push(new_nodes.into_keys().collect());
				// for i in 0..nodes[node_index+1].len() {
				// 	nodes[node_index+1][i].print();
				// }
				edges.push(new_edges.into_keys().collect());
				node_index += 1;
				// println!("Node len {}", nodes[node_index].len());
				
				for iii in 0..nodes[node_index].len() {
					let node: &Node = &nodes[node_index][iii];
					let mut paths: Vec<Edge> = Vec::new();
					to_node(&mut paths, &edges[node_index-1], node);
					let mut min_path: Edge = paths[0];
					let mut min_node: Node = Node::new_empty();
					get_node(&mut min_node, &nodes[node_index-1], min_path.from2);
					for path in &paths {
						let mut temp_node: Node = min_node;
						get_node(&mut temp_node, &nodes[node_index-1], path.from2);
						if (path.cost + temp_node.cost) < (min_path.cost + min_node.cost) {
							min_path = path.clone();
							min_node = temp_node;
						}
					}
					nodes[node_index][iii].cost = min_path.cost + min_node.cost;
				}
				// println!("time2 = {}", time.elapsed().as_nanos());
			}
			let mut new_nodes: HashMap<Node, i8> = HashMap::new();
			let mut new_edges: HashMap<Edge, i8> = HashMap::new();
			println!("prune-------------------------");
			for ii in 0..nodes[node_index].len() {
				let node: Node = nodes[node_index][ii];
				let mut syndrom: Vec<i8> = Vec::new();
				find_syndrom(&mut syndrom, node.name2, i, sub_height);
				print!("synd obj = ");
					for i in 0..syndrom.len() {
						print!("{}, ", syndrom[i]);
					}
					println!("done");
				if syndrom[1] == message[i] {
					let mut newbit = 0;
					find_state(&mut newbit, &mut syndrom, i+1, ext_height, sub_height);
					let newnode = Node::new(node.name1+1, newbit, node.cost);
					let newedge = Edge::new(node.name1, node.name2, node.name1+1, newbit, 0, 2);
					new_edges.insert(newedge, 0);
					new_nodes.insert(newnode, 0);
				}
			}
			if new_edges.len() == 0 || new_nodes.len() == 0 {
				panic!("Failed encoding try a different cover object or remove wet paper elements");
			}
			nodes.push(new_nodes.into_keys().collect());
			edges.push(new_edges.into_keys().collect());
			node_index += 1;
		}
	}
	println!("START forward_pass");
	forward_pass(&mut nodes, &mut edges, &sub_ch, ext_height, sub_width, sub_height, &cover_object, cover_weights, message);

	for i in 0..nodes.len()-1 {
		println!("timeslice {}",i);
		for ii in 0..nodes[i].len() {
			nodes[i][ii].print();
		}
		for ii in 0..edges[i].len() {
			edges[i][ii].print();
		}
	}

	fn backward_pass(stego_obj: &mut Vec<i8>, cost: &mut i8, nodes: Vec<Vec<Node>>, edges: Vec<Vec<Edge>>) {
		let mut node: Node = nodes[(nodes.len()-1) as usize][0];
		node.print();
		*cost = node.cost;
		for i in 0..nodes.len()-1 {
			let index: usize = (nodes.len()-1)-i;
			let mut paths: Vec<Edge> = Vec::new();
			to_node(&mut paths, &edges[index-1], &node);
			
			'A: for ii in 0..paths.len() {
				let mut temp_node: Node = Node::new_empty();
				get_node(&mut temp_node, &nodes[index-1], paths[ii].from2);
				let cost: i8 = temp_node.cost + paths[ii].cost;
				if cost <= node.cost {
					if paths[ii].output != 2 {
						stego_obj.push(paths[ii].output);
					}
					node = temp_node;
					break 'A
				}
			}
		}
		stego_obj.reverse();
	}
	let mut stego_object: Vec<i8> = Vec::new();
	let mut cost: i8 = 0;
	println!("START backward_pass");
	backward_pass(&mut stego_object, &mut cost, nodes, edges,);
	println!("len {}",stego_object.len());
	println!("cost = {}",cost);
	print!("cover obj = ");
	for i in 0..cover_object.len() {
		print!("{}, ", cover_object[i]);
	}
	println!("done");
	print!("stego obj = ");
	for i in 0..stego_object.len() {
		print!("{}, ", stego_object[i]);
	}
	println!("done");

	let mut syndrom = Vec::new();
	matrix_multi(&mut syndrom, &mut stego_object, &ext_ch, ext_height);
	for i in 0..syndrom.len() {
		println!("s{} = {}", i, syndrom[i]);
	}


	// let mut newimg = img.into_rgba8();
	// let mut index = 0;
	// for i in 0..newimg.height() {
	// 	for ii in 0..newimg.width() {
	// 		let pixel = newimg.get_pixel(ii, i);
	// 		if index < stego_object.len() {
	// 			let r = pixel[0];
	// 			let mut r_byte = format!("{r:b}");
	// 			for _ in 0..(8-r_byte.len()) {
	// 				let filler: String = String::from("0");
	// 				r_byte = filler+&r_byte
	// 			}
	// 			r_byte.pop();
	// 			r_byte = r_byte+&stego_object[index].to_string();
	// 			let new_pixel = Rgba([u8::from_str_radix(&r_byte, 2).unwrap(), pixel[1], pixel[2], pixel[3]]);
	// 			newimg.put_pixel(ii, i, new_pixel);
	// 		}
	// 		index += 1;
	// 	}
	// }
	// newimg.save("../dog2.jpeg").expect("Faild to save image");

	// let readimg = match ImageReader::open("../dog.jpeg") {
	// 	Ok(reader) => match reader.decode() {
	// 		Ok(img) => img,
	// 		Err(e) => panic!("{}", e),
	// 	},
	// 	Err(e) => panic!("{}", e),
	// };
	// let mut stego_ob = Vec::new();
	// for i in 0..readimg.height() {
	// 	for ii in 0..readimg.width() {
	// 		let pixel = readimg.get_pixel(ii, i);
	// 		let r = pixel[0];
	// 		let mut r_byte = format!("{r:b}");
	// 		for _ in 0..(8-r_byte.len()) {
	// 			let filler: String = String::from("0");
	// 			r_byte = filler+&r_byte
	// 		}
	// 		let r_lsb = r_byte.pop().expect("Never panic").to_string().parse::<i8>().unwrap();
	// 		stego_ob.push(r_lsb);
	// 	}
	// }
	// let mut syndrom = Vec::new();
	
	// assert!(stego_ob == stego_object);



}
