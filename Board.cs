using Godot;
using System;
using System.Linq;

public class Vertex {
	int ID {get;}
	public Vector2 position {get; set;}
	bool ground {get;}
	bool display {get;set;}
	
	public Vertex(int i, Vector2 p) {
		ID = i;
		position = p;
		
		if (p.y == 0) {
			ground = true;
		} else {
			ground = false;
		}
	}
}

public class Edge {
	public int ID {get;}
	public int p  {get;} // from
	public int q {get;} // to
	public string color {get; set;}
	

	public Edge(int i, int _p, int _q, string c) {
		ID = i;
		p = _p;
		q = _q;
		color = c;
	}
}

public class Board : Node2D {
	public bool inGame = true;
	public bool redsTurn = true; 
	public int maxCapacity = 50;
	public Sprite TurnSprite;
	public Vertex[] Vertices;
	public Edge[] Edges;
	
	public override void _Ready() {
		TurnSprite = GetNode<Sprite>("Turn");
		
		Vertices = new Vertex[] {
			new Vertex(0, new Vector2(0, 0)),
			new Vertex(0, new Vector2(0, -100)),
			new Vertex(0, new Vector2(0, -200)),
			new Vertex(0, new Vector2(0, -300)),
			new Vertex(0, new Vector2(100, 0)),
			new Vertex(0, new Vector2(100, -100)),
			new Vertex(0, new Vector2(100, -200))
		};
		
		Edges = new Edge[] {
			new Edge(0, 0, 1, "005F73"),
			new Edge(0, 1, 2, "AE2012"),
			new Edge(0, 2, 3, "005F73"),
			new Edge(0, 4, 5, "AE2012"),
			new Edge(0, 5, 6, "005F73"),
		};
		
		Render();
	}
	
	public void Render() {
		foreach(var obj in GetChildren()) {
			var node = (Node)obj;
			if (node.IsInGroup("branch")) {
				node.QueueFree();
			}
		}
			
		
		foreach(var edge in Edges) {
			var start = Vertices[edge.p].position;
			var end = Vertices[edge.q].position;
			
			var branch = GD.Load<PackedScene>("res://Scenes/Branch.tscn");
			var instance = branch.Instance<Line2D>();
			instance.SetPoints(new Vector2[]{start, end});
			
			instance.DefaultColor = new Color(edge.color);
			AddChild(instance);
		}
		
	
		TurnSprite.Texture = redsTurn ? ResourceLoader.Load("res://Sprites/red.png") as Texture : ResourceLoader.Load("res://Sprites/blue.png") as Texture;
	}
	
	public bool IsViableMove(string color) {
		return !((redsTurn && color == "005F73") || (!redsTurn && color == "AE2012"));
	}
	
	public void Cut(int edgeID) {
		string color = Edges[edgeID].color;
		
		if (!IsViableMove(color)) {
			return;
		}


		// Maybe some cool animation?
		
		redsTurn = !redsTurn;
		
		bool move_available = false;
		// Check for available moves
		foreach(var edge in Edges) {
			if (IsViableMove(edge.color)) {
				move_available = true;
			}
		}
		
		if (!IsMoveAvailable()) {
			inGame = false;
			if (redsTurn) {
				Win("blue");
			}
			else {
				Win("red");
			}
		}
		Render();
	}
	
	public bool IsMoveAvailable() {
		// TODO
		return false;
	}
	
	public void Win(string winner) {
		if (winner == "red") {
			GD.Print("red");
		}
	}
}
