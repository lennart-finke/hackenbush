using Godot;
using System;
using System.Linq;

public class Vertex : Godot.Object {
	public int ID 					{get;}
	public Vector2 position 		{get; set;}
	public bool ground 				{get;}
	public bool display 			{get;set;}
	public int index 				{get;set;}
	
	public Vertex(int i, Vector2 p) {
		ID = i;
		position = p;
		
		if (p.y == 0) {
			ground = true;
		} else {
			ground = false;
		}
		display = true;
	}
}

public class Edge : Godot.Object {
	public int ID {get;}
	public int p  {get;} // from
	public int q {get;} // to
	public string color {get; set;}
	public bool display;
	public bool bezier;
	public Vector2[] control;
	
	public Edge(int i, int _p, int _q, string c) {
		ID = i;
		p = _p;
		q = _q;
		color = c;
		display = true;
		bezier = false;
		control = new Vector2[]{};
	}
	
	public Edge(int i, int _p, int _q, string c, Vector2[] con) {
		ID = i;
		p = _p;
		q = _q;
		color = c;
		display = true;
		bezier = false;
		control = con;
	}
}

public class Board : Node {
	System.Collections.Generic.Dictionary<string, int> colorDict = new System.Collections.Generic.Dictionary<string, int> {
		{"005F73", 1},
		{"AE2012", 2},
	};
	
	public int world = 1;
	public int level = 1;
	
	public bool inGame = false;
	public bool againstComputer = true;
	public bool humanTurn = true;
	public bool redsTurn = false; 
	public int maxCapacity = 50;
	public Node Helper;
	public CPUParticles2D Confetti;
	public AnimatedSprite BladeRed;
	public AnimatedSprite BladeBlue;
	public Node2D EdgeContainer;
	public Control GUI;
	public AudioStreamPlayer2D SFX;
	public Area2D Pointer;
	public AnimationPlayer CameraAnimator;
	public Timer Clock;
	public Timer Clock2;
	public Vertex[] Vertices;
	public Edge[] Edges;
	
	public override void _Ready() {
		Helper = GetNode<Node>("/root/Helper");
		Confetti = GetNode<CPUParticles2D>("CPUParticles2D");
		BladeRed = GetNode<AnimatedSprite>("UILayer/GUI/MainGameStatic/MarginContainer/HBoxContainer/Red/Blade");
		BladeBlue = GetNode<AnimatedSprite>("UILayer/GUI/MainGameStatic/MarginContainer/HBoxContainer/Blue/Blade");
		EdgeContainer = GetNode<Node2D>("Edges");
		Pointer = GetNode<Area2D>("Pointer");
		CameraAnimator = GetNode<AnimationPlayer>("Camera/AnimationPlayer");
		GUI = GetNode<Control>("UILayer/GUI");
		SFX = GUI.GetNode<AudioStreamPlayer2D>("SFX");
		Clock = GetNode<Timer>("Timer");
		Clock2 = GetNode<Timer>("Timer2");
		
		Clock.Connect("timeout", this, "ComputerMove");
	}
	
	// This structure contains the topological representation of the game used for trimming off
	// floating islands, computing best moves etc.
	public Hackenbush.game G = new Hackenbush.game(Hackenbush.MAXNODES * 4);
	
	public void MakeGame() {
		G = new Hackenbush.game(Hackenbush.MAXNODES * 4);
		Hackenbush.initgame();
	
		Hackenbush.pointcount = Vertices.Length;
		
		int i, j, n1 = 0, n2 = 0;
		
		
		j = 1;
		for (i = 0; i < Hackenbush.pointcount; i++) {
			if (Vertices[i].ground) Vertices[i].index = 0; else Vertices[i].index = j++;
		}
		
		for (i = 0; i < Hackenbush.MAXNODES; i++) {
			Hackenbush.node[i, 0] = -1;
		}
		
		j = 0;
		while (j < Edges.Length) {
			n1 = Vertices[Edges[j].p].index;
			n2 = Vertices[Edges[j].q].index;
			if (n1 > n2) { // guarantees they're in order
				int temp = n1;
				n1 = n2;
				n2 = temp;
			}
			
			G.edge[Hackenbush.edgecount * 4 + 0] = n1;
			G.edge[Hackenbush.edgecount * 4 + 1] = n2;
			G.edge[Hackenbush.edgecount * 4 + 2] = (int)colorDict[Edges[j++].color];
			
			i = 0;
			while (Hackenbush.node[n1, i] != -1) i++;
			Hackenbush.node[n1, i++] = Hackenbush.edgecount;
			Hackenbush.node[n1, i] = -1;
			
			if (n1 != n2) {
				i = 0;
				while (Hackenbush.node[n2, i] != -1) i++;
				
				Hackenbush.node[n2, i++] = Hackenbush.edgecount;
				Hackenbush.node[n2, i] = -1;
			}
			Hackenbush.edgecount++;
		}
		
		G.edge[Hackenbush.edgecount * 4 + 0] = G.edge[Hackenbush.edgecount * 4 + 1] = -1;
	}
	
	public void FromGame() {
		for (int k = 0; k < Edges.Length; k++) {
			Edges[k].display = (G.edge[4 * k + 0] != -2);
		}
	}
	
	public void FromFile() {
		ClearBranches();
		
		var file = new File{};
		var filepath = "res://Games/" + world.ToString() + "-" + level.ToString() + ".tscn";
		if (world == 0) {
			filepath = "user://0-" + level.ToString() + ".tscn";
		}
		
		if (file.FileExists(filepath)) {
			var container = GD.Load<PackedScene>(filepath);
			var container_instance = container.Instance<Node2D>();
			
			foreach(var obj in container_instance.GetChildren()) {
				var node = (Node)obj;
				container_instance.RemoveChild(node);
				EdgeContainer.AddChild(node);
			}
			
			FromEditor();
			MakeGame();
			Render();
		}
		
		else {
			Helper.Set("level_filepath", filepath);
			GetTree().ChangeScene("res://Scenes/LevelEditor.tscn");
			QueueFree();
		}
	}
	
	public void FromEditor() {
		Edges = new Edge[]{};
		Vertices = new Vertex[]{};
		
		Godot.Collections.Array objects = EdgeContainer.GetChildren();
		int l = objects.Count;
		var EdgeList = new System.Collections.Generic.List<Edge>{};
		var VertexDict = new System.Collections.Generic.Dictionary<int, Vector2>{};
		for (int i = 0; i < l; i++) {
			var edge = (Line2D)objects[i];
			
			int ID = (int)edge.Get("ID");
			int p = (int)edge.Get("p");
			int q = (int)edge.Get("q");
			int length = (int)edge.Points.Length;
			Vector2 start = edge.Points[0];
			Vector2 end = edge.Points[length-1];
			string color = edge.DefaultColor.ToHtml(false).ToUpper();
			if (!VertexDict.ContainsKey(p)) VertexDict.Add(p, start);
			if (!VertexDict.ContainsKey(q)) VertexDict.Add(q, end);
			EdgeList.Add(new Edge((int)edge.Get("ID"), p, q, color, (Vector2[])edge.Points));
		}
		
		Edges = EdgeList.ToArray();
		
		Vertices = new Vertex[VertexDict.Count];
		foreach(System.Collections.Generic.KeyValuePair<int, Vector2> pair in VertexDict) {
			Vertices[pair.Key] = new Vertex(pair.Key, pair.Value);
		}
	}
	
	public void StartGame() {
		inGame = true;
		humanTurn = true;
		redsTurn = true;
		Pointer.Call("set_color", new Color(redsTurn ? "AE2012" : "005F73"));
	}
	
	public void ClearBranches() {
		foreach(var obj in EdgeContainer.GetChildren()) {
			var node = (Node)obj;
			if (node.IsInGroup("branch")) {
				if (G.edge[4 * (int)node.Get("ID")] == -2) {
					node.Call("die");
				}
			}
		}
		
		foreach(var obj in EdgeContainer.GetChildren()) {
			var node = (Node)obj;
			if (node.IsInGroup("branch")) {
				EdgeContainer.RemoveChild(node);
			}
		}
	}
	
	public void Render() {
		// Renders the Hackenbush board as scenes.
		// This may only be called if both Edges, Vertices and G are set up.
		Hackenbush.prunegame(G);
		FromGame();
		ClearBranches();
		
		for (int k = 0; k < Edges.Length; k++) {
			Edge edge = Edges[k];
			
			if (edge.display) {
				var start = Vertices[edge.p].position;
				var end = Vertices[edge.q].position;
				
				var branch = GD.Load<PackedScene>("res://Scenes/Branch.tscn");
				var instance = branch.Instance<Line2D>();
				instance.Points = edge.control;
				instance.Set("ID", k);
				instance.DefaultColor = new Color(edge.color);
				EdgeContainer.AddChild(instance);
			}
		}
		
		if (redsTurn) BladeRed.Animation = "default";
		else BladeBlue.Animation = "default";
	}
	
	public bool IsViableMove(string color) {
		return !((redsTurn && color == "005F73") || (!redsTurn && color == "AE2012"));
	}
	
	public void Cut(int edgeID) {
		// Called when a human attempts to cut an edge
		string color = Edges[edgeID].color;
		
		if (!IsViableMove(color) || !humanTurn) {
			return;
		}
		
		Move(edgeID);
		
		humanTurn = false; // We block human moves for a second, no matter which mode.
		
		
		Clock.WaitTime = 1.0f;
		Clock.Start();
	}
	
	public void Move(int edgeID) {
		// Called when a Computer or a Human would like to make a move
		Hackenbush.cutedge(edgeID, G);
		
		SFX.Stream = ResourceLoader.Load("res://Sound/woosh.wav") as AudioStream;
		SFX.PitchScale = redsTurn ? 1f : 1.5f;
		SFX.Play();
		
		if (redsTurn) BladeRed.Animation = "strike";
		else BladeBlue.Animation = "strike";
		
		redsTurn = !redsTurn;
		// We change the cursor color for 2 player mode.
		if (!againstComputer) Pointer.Call("set_color", new Color(redsTurn ? "AE2012" : "005F73"));
		
		Render();
		
		// We check if the active party can't make a move
		int red = 0;
		int blue = 0;
		for (int i = 0; i < Edges.Length; i++) {
			if (G.edge[4 * i] == -2) continue;
			 
			if (G.edge[4 * i + 2] == 2) {
					red++;
			}
			else if (G.edge[4 * i + 2] == 1) {
					blue++;
			}
		}
		
		if 			(blue == 0 && !redsTurn) {
			Confetti.Color = new Color("AE2012");
			Cheer("red");
		} else if 	(red == 0 && redsTurn) {
			Confetti.Color = new Color("005F73");
			Cheer("blue");
		}
		
		Hackenbush.findbestgamemoves(G);
	}
	
	public void ComputerMove() {
		Clock.Stop();
		
		if (!againstComputer) {humanTurn = true; return;}
		
		int bestMove = redsTurn ? Hackenbush.Bestred : Hackenbush.Bestblue;
		if (bestMove < 0) {
			GD.Print("No move to make?");
			return;
		}
		
		Move(bestMove);
		humanTurn = true;
	}
	
	public void GiveUp() {
		string winner = "blue";
		if (!againstComputer) {
			if (humanTurn) {
				winner = redsTurn ? "blue" : "red"; 
			}
		}
		Win(winner);
	}
	
	public async void Cheer(string winner) {
		Confetti.Restart();
		Confetti.Emitting = true;
		
		if (winner == "red") GUI.Call("red_win"); else GUI.Call("blue_win");
		
		Clock2.WaitTime = 2f;
		Clock2.Start();
		await ToSignal(Clock2, "timeout");
		
		Win(winner);
	}
	
	public async void Win(string winner) {
		if (!inGame) return;
		inGame = false;
		
		if (againstComputer && winner == "red") {
			Helper.Call("unlock", world, level);
		}
		
		GUI.Call("fade_out");
		Clock2.Stop();
		Clock2.WaitTime = 0.5f;
		Clock2.Start();
		await ToSignal(Clock2, "timeout");
		
		CameraAnimator.Play("pan_down");
		Clock2.Stop();
		Clock2.WaitTime = 0.9f;
		Clock2.Start();
		await ToSignal(Clock2, "timeout");
		Clock2.Stop();
		
		GUI.Call("to_next", "levelselect", "down");
	}
	
	public override void _Input(InputEvent @event) { // DEBUG
		if (@event.IsActionPressed("a")) ComputerMove();
	}
	
}
